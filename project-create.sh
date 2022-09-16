folder="115792097683"
prefix="nje"
suffix="01"
gke_project=${prefix}-gke-${suffix}
billing_account_id="0178B5-7A3501-25922A"

unset projects
declare -t projects=(
    "${gke_project}" 
    "${vpc_project}"
    )
for project in ${projects}; do
   gcloud projects create ${project} --folder ${folder}
   gcloud alpha billing projects link ${project} --billing-account ${billing_account_id}
done
