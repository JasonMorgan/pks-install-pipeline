#!/bin/bash
set -eu

root=$PWD

# us: ops-manager-us/pcf-gcp-1.9.2.tar.gz -> ops-manager-us/pcf-gcp-1.9.2.tar.gz
pcf_opsman_bucket_path=$(grep -i 'us:.*.tar.gz' pivnet-opsmgr/*GCP.yml | cut -d' ' -f2)

# ops-manager-us/pcf-gcp-1.9.2.tar.gz -> opsman-pcf-gcp-1-9-2
pcf_opsman_image_name=$(echo $pcf_opsman_bucket_path | sed 's%.*/\(.*\).tar.gz%opsman-\1%' | sed 's/\./-/g')

export TF_VAR_service_account_key=${GCP_SERVICE_ACCOUNT_KEY}
export GOOGLE_PROJECT=${GCP_PROJECT_ID}
export GOOGLE_REGION=${GCP_REGION}

terraform init pks-install-pipeline/ci/deploy-opsman/terraform

terraform plan \
  -var "region=${GCP_REGION}" \
  -var "zones=[\"${GCP_ZONE_1}\", \"${GCP_ZONE_2}\", \"${GCP_ZONE_3}\"]" \
  -var "env_prefix=${GCP_RESOURCE_PREFIX}" \
  -var "pcf_opsman_image_name=${pcf_opsman_image_name}" \
  -var "project=${GCP_PROJECT_ID}" \
  -var "nat_machine_type=n1-standard-4" \
  -var "opsman_machine_type=n1-standard-2" \
  -var "domain=${GCP_DOMAIN}" \
  -var "zone_name=${GCP_ZONE_NAME}"
  -out terraform.tfplan \
  -state terraform-state/terraform.tfstate \
  pks-install-pipeline/ci/deploy-opsman/terraform

# -var "service_account_key=${GCP_SERVICE_ACCOUNT_KEY}" \

terraform apply \
  -state-out $root/create-infrastructure-output/terraform.tfstate \
  -parallelism=5 \
  terraform.tfplan

cd $root/create-infrastructure-output
  output_json=$(terraform output -json -state=terraform.tfstate)
  output=$(echo $output_json | jq)
cd -

echo "$output"
