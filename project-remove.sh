set -Euo pipefail

source source.sh

unset projects
declare -t projects=(
  ${PROJECT_RAPID_STD} 
  ${PROJECT_REGULAR_STD} 
  ${PROJECT_RAPID_AP} 
  ${PROJECT_REGULAR_AP} 
  )

for project in ${projects[@]}; do
  gcloud endpoints services delete test.endpoints.${project}.cloud.goog --project=${project} -q
  gcloud projects delete ${project} -q
  echo "$project was deleted."
done

echo "Done"