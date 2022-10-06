set -Euo pipefail

source source.sh

unset projects
declare -t projects=(
  ${PROJECT_RAPID_STD_AUTO}
  ${PROJECT_RAPID_AP_AUTO}
  ${PROJECT_REGULAR_STD_AUTO}
  ${PROJECT_REGULAR_AP_AUTO}
  ${PROJECT_RAPID_STD_MANUAL}
  ${PROJECT_RAPID_AP_MANUAL}
  ${PROJECT_REGULAR_STD_MANUAL}
  ${PROJECT_REGULAR_AP_MANUAL}
  )

for project in ${projects[@]}; do
  gcloud endpoints services delete test.endpoints.${project}.cloud.goog --project=${project} -q
  gcloud projects delete ${project} -q
  echo "$project was deleted."
done

echo "Done"