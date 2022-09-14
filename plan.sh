# Path to Terraform code
TF_ROOT=path/to/code
# If you're using Terraform Enterprise update this to your Terraform enterprise hostname (without https://)
TFC_HOST=app.terraform.io
# Create a Team API Token or User API Token that can be used to fetch the plan, see https://www.terraform.io/docs/cloud/users-teams-organizations/api-tokens.html
TFC_TOKEN=my_token_here

# This file is used by the Terraform CLI to authenticate with Terraform Cloud, it might also live in /root/.terraformrc on Linux CI/CD machines
cp ~/.terraformrc ~/.terraformrc.old
cat <<EOF > /root/.terraformrc
credentials "$TFC_HOST" {
  token = "$TFC_TOKEN"
}
EOF

cd $TF_ROOT

# You can remove this if Terraform is already init'd
echo "Running terraform init"
terraform init

# When using TFC remote execution, terraform doesn't allow us to save the plan output.
# So we have to save the plan logs so we can parse out the run ID and fetch the plan JSON
echo "Running terraform plan"
terraform plan -no-color | tee /tmp/plan_logs.txt

echo "Retrieving the plan JSON"
# Parse the run URL and ID from the logs
run_url=$(grep -A1 'To view this run' /tmp/plan_logs.txt | tail -n 1)
run_id=$(basename $run_url)

# Get the run plan response and parse out the path to the plan JSON
run_plan_resp=$(wget -q -O - --header="Authorization: Bearer $TFC_TOKEN" "https://$TFC_HOST/api/v2/runs/$run_id/plan")
plan_json_path=$(echo $run_plan_resp | sed 's/.*\"json-output\":\"\([^\"]*\)\".*/\1/')

# Download the plan JSON
wget -q -O plan.json --header="Authorization: Bearer $TFC_TOKEN" "https://$TFC_HOST$plan_json_path"

# Infracost CLI commands can be run now
infracost breakdown --path plan.json

# Cleanup generated files
rm /tmp/plan_logs.txt
rm plan.json