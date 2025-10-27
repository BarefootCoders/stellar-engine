#!/bin/bash

#### Use this script at your own risk. The author assumes no responsibility for any damages or losses incurred through its use.

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}" || exit

promptUser() {
  echo -e "\n${1} Type 's' to skip, or 'c' to continue'."
  read -r choice
  if [[ "$choice" == "s" ]]; then
    return 255 # Won't run command
  else
    shift
    for i in "$@"; do
      eval "$i"
    done
  fi
}

########### Initial Provisioning ############
if ! promptUser "This script will delete your entire environment, and all local .terraform dirs. Proceed with caution."; then exit; fi

# Set variables
  if [ ! -f "$SCRIPT_DIR"/config.env ] || promptUser "Would you like to overwrite your config.env file?"; then
    gcloud organizations list

    read -r -p "Enter your billing account: " BILLING_ACCOUNT
    read -r -p "Enter your bootstrap project ID: " BOOTSTRAP_PROJECT_ID
    read -r -p "Enter the compliance regime: " COMPLIANCE_REGIME
    read -r -p "Enter your directory customer ID : " DIRECTORY_CUSTOMER_ID
    read -r -p "Enter your deployer email address: " DEPLOYER_EMAIL_ADDRESS
    read -r -p "Enter your fully qualified domain name: " FULLY_QUALIFIED_DOMAIN_NAME
    read -r -p "Enter your logging alerts email address: " LOGGING_ALERTS_EMAIL_ADDRESS
    read -r -p "Enter your organization ID: " ORGANIZATION_ID
    read -r -p "Enter your prefix: " PREFIX
    read -r -p "Enter your region: " REGION
    read -r -p "Enter your tenant name: "  TENANT_NAME

    echo "--- Configuration Summary ---"
    echo "billing-account: $BILLING_ACCOUNT"
    echo "bootstrap-project-id: $BOOTSTRAP_PROJECT_ID"
    echo "compliance-regime: $COMPLIANCE_REGIME"
    echo "directory-customer-id: $DIRECTORY_CUSTOMER_ID"
    echo "deployer-email-address: $DEPLOYER_EMAIL_ADDRESS"
    echo "fully-qualified-domain-name: $FULLY_QUALIFIED_DOMAIN_NAME"
    echo "logging-alerts-email-address: $LOGGING_ALERTS_EMAIL_ADDRESS"
    echo "organization-id: $ORGANIZATION_ID"
    echo "prefix: $PREFIX"
    echo "region: $REGION"
    echo "tenant-name: $TENANT_NAME"

    {
      echo "BILLING_ACCOUNT=$BILLING_ACCOUNT"
      echo "BOOTSTRAP_PROJECT_ID=$BOOTSTRAP_PROJECT_ID"
      echo "COMPLIANCE_REGIME=$COMPLIANCE_REGIME"
      echo "DIRECTORY_CUSTOMER_ID=$DIRECTORY_CUSTOMER_ID"
      echo "DEPLOYER_EMAIL_ADDRESS=$DEPLOYER_EMAIL_ADDRESS"
      echo "FULLY_QUALIFIED_DOMAIN_NAME=$FULLY_QUALIFIED_DOMAIN_NAME"
      echo "LOGGING_ALERTS_EMAIL_ADDRESS=$LOGGING_ALERTS_EMAIL_ADDRESS"
      echo "ORGANIZATION_ID=$ORGANIZATION_ID"
      echo "PREFIX=$PREFIX"
      echo "REGION=$REGION"
      echo "TENANT_NAME=$TENANT_NAME"
    } > "$SCRIPT_DIR"/config.env
else
    # shellcheck source=experimental/config.env.sample
    source "$SCRIPT_DIR"/config.env
    echo "------------------------------------------------------------------"
    echo "config.env"
    cat config.env
    echo "------------------------------------------------------------------"
    echo "If the above does not look correct your config.env may be wrong!"
  fi

if promptUser "Would you like to reauthenticate?"; then
  gcloud auth revoke "${DEPLOYER_EMAIL_ADDRESS}"
  gcloud auth login; gcloud auth application-default login
fi

promptUser "Would you like to set your default project to ${PREFIX}-prod-iac-core-0?" "gcloud config set project ${PREFIX}-prod-iac-core-0"

# if promptUser "Would you to set your IAM permissions?"; then
#   "${SCRIPT_DIR}"/../fast/stages-aw/0-bootstrap/setIAM.sh "${DEPLOYER_EMAIL_ADDRESS}" "${ORGANIZATION_ID}"
# fi

if promptUser "Would you like to disable org policies to allow for deletion?"; then
  gcloud org-policies delete-custom-constraint custom.kmsRotation"${PREFIX}" --organization="${ORGANIZATION_ID}"
  gcloud resource-manager org-policies disable-enforce compute.requireOsLogin --organization="${ORGANIZATION_ID}"
  echo "Sleeping for 60 seconds to allow disabling policies to take effect"
  sleep 60
fi

########### Stage 3 - Security ############
echo -e "\n#######################################################"
echo "#######################################################"
echo "#######################################################"

if promptUser "Stage 3 - Security"; then
  cd "${SCRIPT_DIR}"/../fast/stages-aw/3-security || exit

  if promptUser "Would you like to restore your bootstrap project if it was deleted?"; then
    gcloud projects undelete "${BOOTSTRAP_PROJECT_ID}"
    sleep 60
    gcloud billing projects link "${BOOTSTRAP_PROJECT_ID}" --billing-account="${BILLING_ACCOUNT}"
  fi

  if promptUser "Would you like to reenable disabled Service Accounts?"; then
    ./sa_lockdown.sh --enable
    sleep 30
  fi
  
  promptUser "Would you like to run terraform destroy?" "terraform destroy"
  promptUser "Would you like to delete your .terraform dir?" "rm -r .terraform"

  if promptUser "Would you like to remove billing account admin permissions for ${PREFIX}-prod-resman-0@${PREFIX}-prod-iac-core-0.iam.gserviceaccount.com?"; then
    gcloud billing accounts remove-iam-policy-binding "${BILLING_ACCOUNT}" --member=serviceAccount:"${PREFIX}"-prod-resman-0@"${PREFIX}"-prod-iac-core-0.iam.gserviceaccount.com --role=roles/billing.admin
  fi

fi
########## Stage 2 - Networking ############
echo -e "\n#######################################################"
echo "#######################################################"
echo "#######################################################"

if promptUser "Stage 2 - Networking"; then
  # Choose networking paradigm
  echo "Please type \"1\", \"2\", or \"3\" below that corresponds to the network paradigm you want: "
  echo "1) IL2/FedRAMP Moderate"
  echo "2) FedRAMP High"
  echo "3) IL4/IL5"
  read -r choice

  ########### IL2/FedRAMP Moderate ###########
  if [ "$choice" == 1 ]; then
    echo "This stage is still under development."

  ########### FedRAMP High ###########
  elif [ "$choice" == 2 ]; then
    cd "${SCRIPT_DIR}"/../fast/stages-aw/2-networking-a-fedramp-high || exit
    promptUser "Would you like to run terraform destroy?" "terraform destroy"
    promptUser "If you receive a peering error, would you like to rerun terraform destroy?" "terraform destroy"
    promptUser "Would you like to delete your .terraform dir?" "rm -r .terraform"

  ########### IL4/IL5 ###########
  elif [ "$choice" == 3 ]; then
    cd "${SCRIPT_DIR}"/../fast/stages-aw/2-networking-b-il5-ngfw || exit
    promptUser "Would you like to run terraform destroy?" "terraform destroy"
    promptUser "If you receive a peering error, would you like to rerun terraform destroy?" "terraform destroy"
    promptUser "Would you like to delete your .terraform dir?" "rm -r .terraform"
  fi
  
  if promptUser "Would you like to remove billing account admin permissions for the ${PREFIX}-prod-resman-net-0@${PREFIX}-prod-iac-core-0.iam.gserviceaccount.com?"; then
    gcloud billing accounts remove-iam-policy-binding "${BILLING_ACCOUNT}" --member=serviceAccount:"${PREFIX}"-prod-resman-net-0@"${PREFIX}"-prod-iac-core-0.iam.gserviceaccount.com --role=roles/billing.admin
  fi
fi

########### Stage 1 - Resman ############
echo -e "\n#######################################################"
echo "#######################################################"
echo "#######################################################"

if promptUser "Stage 1 - Resource Manager"; then # Left Here
  cd "${SCRIPT_DIR}"/../fast/stages-aw/1-resman || exit
    if promptUser "Would you like to remove all storage buckets?"; then
      # TODO - Update for multiple tenants
      gcloud storage rm -r gs://"${PREFIX}"-test-"${TENANT_NAME}"-iac-outputs-0
      gcloud storage rm -r gs://"${PREFIX}"-int-"${TENANT_NAME}"-iac-outputs-0
      gcloud storage rm -r gs://"${PREFIX}"-prod-"${TENANT_NAME}"-iac-outputs-0

      gcloud storage rm -r gs://"${PREFIX}"-prod-resman-sec-0
      gcloud storage rm -r gs://"${PREFIX}"-prod-resman-net-0
    fi

    promptUser "Would you like to run terraform destroy?" "terraform destroy -lock=false"

    if promptUser "If you received an error for TagValues, would you like to delete all child tags?"; then
      read -r -p "Please enter the TagValue from the above error - numbers only" TAG
      gcloud resource-manager tags values delete tagValues/"${TAG}"
      terraform destroy
    fi

    promptUser "Would you like to delete your .terraform dir?" "rm -r .terraform"
fi

########### Stage 0 - Bootstrap ############
echo -e "\n#######################################################"
echo "#######################################################"
echo "#######################################################"

if promptUser "Stage 0 - Bootstrap"; then
  cd "${SCRIPT_DIR}"/../fast/stages-aw/0-bootstrap || exit

  if promptUser "Would you like to set the bootstrap project as your default project?"; then
    gcloud config set project "${BOOTSTRAP_PROJECT_ID}"
  fi

  if promptUser "Would you like to copy the remote state to your local device, revert your providers, and migrate to the local state?"; then
    gcloud storage cp gs://"${PREFIX}"-prod-iac-core-bootstrap-0/default.tfstate ./terraform.tfstate
    cp providers.tf.tmp 0-bootstrap-providers.tf
    terraform init -migrate-state
  fi

  if promptUser "Would you to set your IAM permissions?"; then
    "${SCRIPT_DIR}"/../fast/stages-aw/0-bootstrap/setIAM.sh "${DEPLOYER_EMAIL_ADDRESS}" "${ORGANIZATION_ID}"
  fi

  if promptUser "Would you like to delete storage buckets?"; then
    terraform state rm 'module.automation-tf-bootstrap-gcs.google_storage_bucket.bucket[0]'
    terraform state rm 'module.automation-tf-output-gcs.google_storage_bucket.bucket[0]'
    terraform state rm 'module.automation-tf-resman-gcs.google_storage_bucket.bucket[0]'

    gcloud storage rm -r gs://"${PREFIX}"-prod-iac-core-resman-0
    gcloud storage rm -r gs://"${PREFIX}"-prod-iac-core-outputs-0
    gcloud storage rm -r gs://"${PREFIX}"-prod-iac-core-bootstrap-0
  fi

  if promptUser "Would you like to run terraform destroy?"; then
    terraform destroy -var bootstrap_user="$(gcloud config list --format 'value(core.account)')"
  fi

  if promptUser "Did you receive any errors deleting projects or Assured Workloads resources?"; then
    "${SCRIPT_DIR}"/../fast/stages-aw/0-bootstrap/setIAM.sh "${DEPLOYER_EMAIL_ADDRESS}" "${ORGANIZATION_ID}"
    sleep 60
    terraform destroy
  fi

  ### Keeping the below in for reference
  # if promptUser "Did you receive any errors deleting projects"; then
  #   "${SCRIPT_DIR}"/../fast/stages-aw/0-bootstrap/setIAM.sh "${DEPLOYER_EMAIL_ADDRESS}" "${ORGANIZATION_ID}"
  #   gcloud projects delete "${PREFIX}"-prod-audit-logs-0
  #   gcloud projects delete "${PREFIX}"-prod-iac-core-0
  # fi

  # if promptUser "Did you receive any errors deleting Assured Workloads?"; then
  #   "${SCRIPT_DIR}"/../fast/stages-aw/0-bootstrap/setIAM.sh "${DEPLOYER_EMAIL_ADDRESS}" "${ORGANIZATION_ID}"

  #   aw_folder=$(gcloud resource-manager folders list --organization="${ORGANIZATION_ID}" | grep StellarEngine-"${PREFIX}" | awk '{print $3}')
  #   common_folder=$(gcloud resource-manager folders list --folder="${aw_folder}" --format='value(ID)')
  #   aw_environment=$(gcloud assured workloads list \
  #                 --organization="${ORGANIZATION_ID}" \
  #                 --location=us-east4 \
  #                 --format='value(name)' 2>/dev/null)

  #   gcloud resource-manager folders delete "${common_folder}"
  #   gcloud resource-manager folders delete "${aw_folder}"
  #   echo 'Waiting 2 minutes to ensure child folders and projects are properly deleted, then deleting the Assured Workloads Environment'
  #   sleep 120
  #   gcloud assured workloads delete "${aw_environment}"
  # fi

  if promptUser "Would you like to delete your .terraform dir?"; then
    rm -r .terraform
  fi

  if promptUser "Would you like to delete your .tfstate?"; then
    rm terraform.tfstate
  fi
fi

if promptUser "Would you like reenable compute.requireOsLogin?"; then
  gcloud resource-manager org-policies enable-enforce compute.requireOsLogin --organization="${ORGANIZATION_ID}"
fi

if promptUser "Would you like to remove your gcloud configuration?"; then
  gcloud auth revoke "${DEPLOYER_EMAIL_ADDRESS}"
fi

echo "You have deleted your environment. Please run clean.sh if you are still running into issues."

# TODO - Remove user permissions
# Keep these
# Organization Policy Administrator
# Organization Role Administrator
# Service Account Admin
