set -Euo pipefail

suffix=$RANDOM
unset projects
declare -t projects=(
  "${PREFIX}-rapid-std-${suffix}" 
  "${PREFIX}-rapid-ap-${suffix}" 
  "${PREFIX}-regular-std-${suffix}" 
  "${PREFIX}-regular-ap-${suffix}" 
  )
for project in ${projects}; do
  gcloud projects create ${project} --folder ${FOLDER_ID}
  gcloud alpha billing projects link ${project} --billing-account ${BILLING_ID}
  echo "$project was created."
  DIR="test-${project}"
  mkdir ${DIR}
  cp -rf configs ${DIR}
  cp asm-test-create.sh ${DIR}
done

cat <<EOF > source.sh
export PROJECT_RAPID_STD="${PREFIX}-rapid-std-${suffix}"
export PROJECT_RAPID_AP="${PREFIX}-rapid-ap-${suffix}" 
export PROJECT_REGULAR_STD="${PREFIX}-regular-std-${suffix}"
export PROJECT_REGULAR_AP="${PREFIX}-regular-ap-${suffix}" 
EOF