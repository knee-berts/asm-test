set -Euo pipefail

suffix=$RANDOM
unset projects
declare -t projects=(
  "${PROJECT_PREFIX}-rapid-std-auto-${suffix}"
  "${PROJECT_PREFIX}-rapid-ap-auto-${suffix}"
  "${PROJECT_PREFIX}-regular-std-auto-${suffix}"
  "${PROJECT_PREFIX}-regular-ap-auto-${suffix}"
  "${PROJECT_PREFIX}-rapid-std-manual-${suffix}"
  "${PROJECT_PREFIX}-rapid-ap-manual-${suffix}"
  "${PROJECT_PREFIX}-regular-std-manual-${suffix}"
  "${PROJECT_PREFIX}-regular-ap-manual-${suffix}"
  )
for project in ${projects[@]}; do
  gcloud projects create ${project} --folder ${FOLDER_ID}
  gcloud alpha billing projects link ${project} --billing-account ${BILLING_ID}
  echo "$project was created."
  DIR="test-${project}"
  mkdir ${DIR}
  cp -rf configs ${DIR}
  cp *.sh ${DIR}
  cp Makefile ${DIR}
done

cat <<EOF > source.sh
export PROJECT_RAPID_STD_AUTO="${PROJECT_PREFIX}-rapid-std-auto-${suffix}"
export PROJECT_RAPID_AP_AUTO="${PROJECT_PREFIX}-rapid-ap-auto-${suffix}"
export PROJECT_REGULAR_STD_AUTO="${PROJECT_PREFIX}-regular-std-auto-${suffix}"
export PROJECT_REGULAR_AP_AUTO="${PROJECT_PREFIX}-regular-ap-auto-${suffix}"
export PROJECT_RAPID_STD_MANUAL="${PROJECT_PREFIX}-rapid-std-manual-${suffix}"
export PROJECT_RAPID_AP_MANUAL="${PROJECT_PREFIX}-rapid-ap-manual-${suffix}"
export PROJECT_REGULAR_STD_MANUAL="${PROJECT_PREFIX}-regular-std-manual-${suffix}"
export PROJECT_REGULAR_AP_MANUAL="${PROJECT_PREFIX}-regular-ap-manual-${suffix}"
EOF