set -Euo pipefail

suffix=$RANDOM
unset projects
declare -t projects=(
  "${PROJECT_PREFIX}-rapid-std-${suffix}" 
  "${PROJECT_PREFIX}-rapid-ap-${suffix}" 
  "${PROJECT_PREFIX}-regular-std-${suffix}" 
  "${PROJECT_PREFIX}-regular-ap-${suffix}" 
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
export PROJECT_RAPID_STD="${PROJECT_PREFIX}-rapid-std-${suffix}"
export PROJECT_RAPID_AP="${PROJECT_PREFIX}-rapid-ap-${suffix}" 
export PROJECT_REGULAR_STD="${PROJECT_PREFIX}-regular-std-${suffix}"
export PROJECT_REGULAR_AP="${PROJECT_PREFIX}-regular-ap-${suffix}" 
EOF