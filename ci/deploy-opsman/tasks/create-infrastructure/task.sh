#!/bin/bash
set -eu

root=$PWD

# us: ops-manager-us/pcf-gcp-1.9.2.tar.gz -> ops-manager-us/pcf-gcp-1.9.2.tar.gz
pcf_opsman_bucket_path=$(grep -i 'us:.*.tar.gz' pivnet-opsmgr/*GCP.yml | cut -d' ' -f2)

# ops-manager-us/pcf-gcp-1.9.2.tar.gz -> opsman-pcf-gcp-1-9-2
pcf_opsman_image_name=$(echo $pcf_opsman_bucket_path | sed 's%.*/\(.*\).tar.gz%opsman-\1%' | sed 's/\./-/g')

export GOOGLE_CREDENTIALS=${GCP_SERVICE_ACCOUNT_KEY}
export GOOGLE_PROJECT=${GCP_PROJECT_ID}
export GOOGLE_REGION=${GCP_REGION}

terraform init pks-install-pipeline/ci/deploy-opsman/terraform

terraform plan \
  -var "region=${GCP_REGION}" \
  -var "zones=[${GCP_ZONE_1}, ${GCP_ZONE_2}, ${GCP_ZONE_3}]" \
  -var "env_prefix=${GCP_RESOURCE_PREFIX}" \
  -var "pcf_opsman_image_name=${pcf_opsman_image_name}" \
  -out terraform.tfplan \
  -state terraform-state/terraform.tfstate \
  pcf-pipelines/install-pcf/gcp/terraform

terraform apply \
  -state-out $root/create-infrastructure-output/terraform.tfstate \
  -parallelism=5 \
  terraform.tfplan

cd $root/create-infrastructure-output
  output_json=$(terraform output -json -state=terraform.tfstate)
  pub_ip_global_pcf=$(echo $output_json | jq --raw-output '.pub_ip_global_pcf.value')
  pub_ip_ssh_and_doppler=$(echo $output_json | jq --raw-output '.pub_ip_ssh_and_doppler.value')
  pub_ip_ssh_tcp_lb=$(echo $output_json | jq --raw-output '.pub_ip_ssh_tcp_lb.value')
  pub_ip_opsman=$(echo $output_json | jq --raw-output '.pub_ip_opsman.value')
cd -

echo "Please configure DNS as follows:"
echo "----------------------------------------------------------------------------------------------"
echo "*.${SYSTEM_DOMAIN} == ${pub_ip_global_pcf}"
echo "*.${APPS_DOMAIN} == ${pub_ip_global_pcf}"
echo "ssh.${SYSTEM_DOMAIN} == ${pub_ip_ssh_and_doppler}"
echo "doppler.${SYSTEM_DOMAIN} == ${pub_ip_ssh_and_doppler}"
echo "loggregator.${SYSTEM_DOMAIN} == ${pub_ip_ssh_and_doppler}"
echo "tcp.${PCF_ERT_DOMAIN} == ${pub_ip_ssh_tcp_lb}"
echo "opsman.${PCF_ERT_DOMAIN} == ${pub_ip_opsman}"
echo "----------------------------------------------------------------------------------------------"
