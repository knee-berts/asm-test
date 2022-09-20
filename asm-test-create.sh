#!/usr/bin/env bash

set -Euo pipefail

while getopts p:r:t: flag
do
  case "${flag}" in
      p) PROJECT_ID=${OPTARG};;
      r) RELEASE_CHANNEL=${OPTARG};;
      t) CLUSTER_TYPE=${OPTARG};;
  esac
done

echo "::Variable set::"
echo "PROJECT_ID: ${PROJECT_ID}"
echo "RELEASE_CHANNEL: ${RELEASE_CHANNEL}" ## regular or rapid
echo "CLUSTER_TYPE: ${CLUSTER_TYPE}"  ## std or ap 

export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format="value(projectNumber)")
export WORKDIR=`pwd`
mkdir tmp
touch kubeconfig
export KUBECONFIG=${WORKDIR}/kubeconfig

echo "Enabling GCP services"
gcloud services enable \
  --project=${PROJECT_ID} \
  anthos.googleapis.com \
  container.googleapis.com \
  compute.googleapis.com \
  monitoring.googleapis.com \
  logging.googleapis.com \
  cloudtrace.googleapis.com \
  meshca.googleapis.com \
  meshtelemetry.googleapis.com \
  meshconfig.googleapis.com \
  iamcredentials.googleapis.com \
  gkeconnect.googleapis.com \
  gkehub.googleapis.com \
  multiclusteringress.googleapis.com \
  multiclusterservicediscovery.googleapis.com \
  stackdriver.googleapis.com \
  trafficdirector.googleapis.com \
  cloudresourcemanager.googleapis.com

GKE_CLUSTERS=(
  "gke-${CLUSTER_TYPE}-us-west1"
  "gke-${CLUSTER_TYPE}-us-east1"
  "gke-${CLUSTER_TYPE}-us-central1"
)

echo "Creating a VPC."
if [[ $(gcloud compute networks describe demo-vpc --project ${PROJECT_ID}) ]]; then
  echo "VPC already exists."
else
  gcloud compute networks create demo-vpc --project ${PROJECT_ID}\
    --subnet-mode=auto \
    --bgp-routing-mode=global
fi

echo "Creating a VPC firewall rule."
if [[ $(gcloud compute firewall-rules describe all-10 --project ${PROJECT_ID}) ]]; then
  echo "VPC firewall rule already exists."
else
  gcloud compute firewall-rules create all-10 \
    --project ${PROJECT_ID} \
    --network demo-vpc \
    --allow all \
    --direction INGRESS \
    --source-ranges 10.0.0.0/8
fi
  echo "Creating a global public IP for the ASM GW."
if [[ $(gcloud compute addresses describe asm-gw-ip --global --project ${PROJECT_ID}) ]]; then
  echo "ASM GW IP already exists."
else
  echo "Creating ASM GW IP."
  gcloud compute addresses create asm-gw-ip --global --project ${PROJECT_ID}
fi
export ASM_GW_IP=`gcloud compute addresses describe asm-gw-ip --global --project ${PROJECT_ID} --format="value(address)"`
echo -e "GCLB_IP is ${ASM_GW_IP}"

cd configs
echo `pwd`
## Hydrate configs
echo "Hydrating configs"
if [[ "$OSTYPE" == "darwin"* ]]; then
  LC_ALL=C find . -type f -exec sed -i '' -e "s/{{PROJECT_ID}}/${PROJECT_ID}/g" {} +
  LC_ALL=C find . -type f -exec sed -i '' -e "s/{{ASM_GW_IP}}/${ASM_GW_IP}/g" {} +
else
  find . -type f -exec sed -i -e "s/{{PROJECT_ID}}/${PROJECT_ID}/g" {} +
  find . -type f -exec sed -i -e "s/{{ASM_GW_IP}}/${ASM_GW_IP}/g" {} +
fi
cd -
echo "Creating gcp endpoints for test app."
gcloud endpoints services deploy configs/test-openapi.yaml --project ${PROJECT_ID} --async -q

# Enable mesh feature
gcloud container fleet mesh enable --project=${PROJECT_ID}

## Create Clusters
echo "Creating a GKE clusters"
for CLUSTER in ${GKE_CLUSTERS[@]}; do
  if [[ ${CLUSTER_TYPE} == "ap" ]]; then
    REGION=$(echo ${CLUSTER} | awk -F "-"  '{print $3 "-" $4}' )
    gcloud beta container --project ${PROJECT_ID} clusters create-auto ${CLUSTER} \
      --region ${REGION} \
      --release-channel ${RELEASE_CHANNEL} \
      --network "demo-vpc" \
      --enable-master-authorized-networks \
      --master-authorized-networks 0.0.0.0/0 \
      --async

    else
    ZONE=$(echo ${CLUSTER} | awk -F "-"  '{print $3 "-" $4 "-b"}' )
    echo ${CLUSTER}
    gcloud beta container --project ${PROJECT_ID} clusters create ${CLUSTER} \
      --zone ${ZONE} \
      --release-channel "regular" \
      --machine-type "e2-medium" \
      --num-nodes "1" \
      --network "demo-vpc" \
      --enable-ip-alias \
      --enable-autoscaling --min-nodes "1" --max-nodes "10" \
      --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0 \
      --labels mesh_id=proj-${PROJECT_NUMBER} \
      --autoscaling-profile optimize-utilization \
      --workload-pool "${PROJECT_ID}.svc.id.goog" \
      --enable-master-authorized-networks \
      --master-authorized-networks 0.0.0.0/0 \
      --async
    fi
done
while [[ $(gcloud container clusters list --project ${PROJECT_ID} --filter "STATUS=RUNNING" --format="value(name)"| wc -l | awk '{print $1}') != "3" ]]; do
  echo "Waiting for all the cluster installs to complete."
  sleep 5
done
echo "All clusters are in the RUNNING status."
for CLUSTER in ${GKE_CLUSTERS[@]}; do
  if [[ ${CLUSTER_TYPE} == "ap" ]]; then
    REGION=$(echo ${CLUSTER} | awk -F "-"  '{print $3 "-" $4}' )
    
    gcloud container clusters update ${CLUSTER} --project ${PROJECT_ID} \
      --region ${REGION} \
      --update-labels mesh_id=proj-${PROJECT_NUMBER} 
    
    gcloud container clusters get-credentials ${CLUSTER} --region ${REGION} --project ${PROJECT_ID}
    kubectx ${CLUSTER}=gke_${PROJECT_ID}_${REGION}_${CLUSTER}
    
    gcloud container hub memberships register ${CLUSTER} \
      --project=${PROJECT_ID} \
      --gke-cluster=${REGION}/${CLUSTER} \
      --enable-workload-identity
    
    gcloud container fleet mesh update \
      --control-plane automatic \
      --memberships ${CLUSTER} \
      --project ${PROJECT_ID}
  else
    ZONE=$(echo ${CLUSTER} | awk -F "-"  '{print $3 "-" $4 "-b"}' )
    
    gcloud container clusters get-credentials ${CLUSTER} --zone ${ZONE} --project ${PROJECT_ID}
    kubectx ${CLUSTER}=gke_${PROJECT_ID}_${ZONE}_${CLUSTER}

    gcloud container hub memberships register ${CLUSTER} \
      --project=${PROJECT_ID} \
      --gke-cluster=${ZONE}/${CLUSTER} \
      --enable-workload-identity   
    
    gcloud container fleet mesh update \
      --control-plane automatic \
      --memberships ${CLUSTER} \
      --project ${PROJECT_ID}
  fi 
done

gcloud projects add-iam-policy-binding ${PROJECT_ID}  \
  --member "serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-servicemesh.iam.gserviceaccount.com" \
  --role roles/anthosservicemesh.serviceAgent

## Install MCI MCS and ASM Gateways
if [[ $(gcloud compute ssl-certificates describe whereami-cert --project ${PROJECT_ID}) ]]; then
  echo "Test app cert already exists"
else
  echo "Creating certificates for test app."
  gcloud compute ssl-certificates create test-cert \
      --domains=whereami.endpoints.${PROJECT_ID}.cloud.goog \
      --global --project ${PROJECT_ID}
fi

# Enable ingress feature which also enables the multi-cluster-services feature controller and install test app
gcloud container fleet ingress enable \
  --config-membership=/projects/${PROJECT_ID}/locations/global/memberships/"gke-${CLUSTER_TYPE}-us-central1" \
  --project=${PROJECT_ID}

git clone https://github.com/GoogleCloudPlatform/kubernetes-engine-samples.git 
cp -rf kubernetes-engine-samples/whereami ${WORKDIR}/configs/all-clusters/ 
rm -rf kubernetes-engine-samples

for CLUSTER in ${GKE_CLUSTERS[@]}; do
  kubectl apply -f ${WORKDIR}/configs/pre-reqs/. --context ${CLUSTER}
  kubectl apply -k ${WORKDIR}/configs/all-clusters/whereami/k8s-backend-overlay-example/ --context=${CLUSTER} -n whereami 
  kubectl apply -k ${WORKDIR}/configs/all-clusters/whereami/k8s-frontend-overlay-example/ --context=${CLUSTER} -n whereami

  openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/CN=frontend.endpoints.${PROJECT_ID}.cloud.goog/O=Edge2Mesh Inc" \
    -keyout tmp/frontend.endpoints.${PROJECT_ID}.cloud.goog.key \
    -out tmp/frontend.endpoints.${PROJECT_ID}.cloud.goog.crt
  kubectl -n asm-gateways create secret tls edge2mesh-credential \
    --key=tmp/frontend.endpoints.${PROJECT_ID}.cloud.goog.key \
    --cert=tmp/frontend.endpoints.${PROJECT_ID}.cloud.goog.crt --context ${CLUSTER}

  echo -n "Waiting for the ASM MCP webhook to install."
  if [[ "${RELEASE_CHANNEL}" == "rapid" ]]; then
    until kubectl get mutatingwebhookconfigurations istiod-asm-managed-rapid --context ${CLUSTER}
    do
      echo -n "...still waiting for ASM MCP webhook creation"
      sleep 5
    done
  else 
    until kubectl get mutatingwebhookconfigurations istiod-asm-managed --context ${CLUSTER}
    do
      echo -n "...still waiting for ASM MCP webhook creation"
      sleep 5
    done
  fi
  echo "ASM MCP webhook has been created."   
  kubectl apply -f ${WORKDIR}/configs/all-clusters/. --context ${CLUSTER}
done

kubectl apply -f ${WORKDIR}/configs/config-cluster/. --context "gke-${CLUSTER_TYPE}-us-central1"  

echo "ASM MCP test env installed"