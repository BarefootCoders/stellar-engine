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

############ Prerequisites ############
echo "Welcome to the Stellar Engine automated deployment!
This is designed for the initial deployment. For a redeployment, please make sure you change the prefix and run the delete.sh script prior to redeployment.

If you do not have a large enough quota for your billing projects, follow the below link:
https://support.google.com/code/contact/billing_quota_increase

Also, please make sure you have Super Admin privileges - if not, please contact your oganization administrator."
 
echo -e "\n#######################################################"
echo "#######################################################"
echo "#######################################################"

if promptUser "Prerequisites -"; then
  # Authentication
  promptUser 'Would you like to (re)authenticate with Google Cloud?' "gcloud auth login; gcloud auth application-default login"

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
    read -r -p "Enter your prefix (6 chars or less): " PREFIX
    read -r -p "Enter your region: " REGION
    read -r -p "Enter your tenant name (6 chars or less): "  TENANT_NAME

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

  # Set Boostrap Project
  promptUser "Would you like to set the bootstrap project as the default project?" "gcloud config set project ${BOOTSTRAP_PROJECT_ID}"

  # setIAM
  promptUser "Would you like to set your IAM permissions?" "${SCRIPT_DIR}/../fast/stages-aw/0-bootstrap/setIAM.sh ${DEPLOYER_EMAIL_ADDRESS} ${ORGANIZATION_ID}"

  # enable Services
  promptUser "Would you like to enable all Google Cloud Services?" "${SCRIPT_DIR}/../fast/stages-aw/0-bootstrap/enableServices.sh ${DEPLOYER_EMAIL_ADDRESS} ${ORGANIZATION_ID}"

  if promptUser "Would you like to link the billing account to the bootstrap project?"; then
    gcloud billing projects link "${BOOTSTRAP_PROJECT_ID}" --billing-account="${BILLING_ACCOUNT}"
  fi

  # Groups and Admin setup
  echo -e "\nPlease follow the link below (if you have not yet done so) to set up 2) Users and groups and 3) Administrative access"
  echo "https://console.cloud.google.com/cloud-setup/overview?invt=AbuI_w&organizationId=${ORGANIZATION_ID}"
  echo "Press any key when complete to go to the next step."
  read -r -n 1 -s -p ""

  echo -e "\nPlease follow the link below (if you have not yet done so) to enable access transparency for your organization"
  echo "https://console.cloud.google.com/iam-admin/settings?invt=AbuKFg&organizationId=${ORGANIZATION_ID}"
  echo "Press any key when complete to go to the next step."
  read -r -n 1 -s -p ""

  echo -e "\nCongratulations, you have finished the prerequisites!"

else
    # shellcheck source=experimental/config.env.sample
    source "$SCRIPT_DIR"/config.env
    echo "------------------------------------------------------------------"
    echo "config.env"
    cat config.env
    echo "------------------------------------------------------------------"
    echo -e "If the above does not look correct your config.env may be wrong!\n"
fi

########### Stage 0 - Bootstrap ############
echo -e "\n#######################################################"
echo "#######################################################"
echo "#######################################################"

if promptUser "Stage 0 - Bootstrap -"; then
  cd "${SCRIPT_DIR}"/../fast/stages-aw/0-bootstrap || exit

  # Confirm billing account privikleges
  echo "Please make sure you have billing account admin privileges, and billing is enabled on the bootstrap project."
  echo "Press any key to confirm, and go to the next step."
  read -r -n 1 -s -p ""

  # Generate TF Vars - This will NOT work indented
  if promptUser "Would you to generate a new tfvars file?"; then
cat <<EOF > terraform.tfvars
billing_account = {
  id = "${BILLING_ACCOUNT}"
}

# locations for GCS, BigQuery, KMS, and logging buckets created here
locations = {
  bq      = "${REGION}"
  gcs     = "${REGION}"
  logging = "${REGION}"
  pubsub  = ["${REGION}"]
  kms     = "${REGION}"
}

# use \`gcloud organizations list\`
organization = {
  domain      = "${FULLY_QUALIFIED_DOMAIN_NAME}"
  id          = "${ORGANIZATION_ID}"
  customer_id = "${DIRECTORY_CUSTOMER_ID}"
}

outputs_location = "~/fast-config"

# use something unique and no longer than 9 characters
prefix = "${PREFIX}"
log_sinks = {
  audit-logs = {
    filter = "logName:\"/logs/cloudaudit.googleapis.com%2Factivity\" OR logName:\"/logs/cloudaudit.googleapis.com%2Fsystem_event\" OR protoPayload.metadata.@type=\"type.googleapis.com/google.cloud.audit.TransparencyLog\""
    type   = "pubsub"
  }
  vpc-sc = {
    filter = "protoPayload.metadata.@type=\"type.googleapis.com/google.cloud.audit.VpcServiceControlAuditMetadata\""
    type   = "pubsub"
  }
  workspace-audit-logs = {
    filter = "logName:\"/logs/cloudaudit.googleapis.com%2Fdata_access\" and protoPayload.serviceName:\"login.googleapis.com\""
    type   = "pubsub"
  }

  # CIS Compliance Benchmark 2.2
  empty-audit-logs = {
    filter = ""
    type   = "pubsub"
  }
}

org_policies_config = {
  import_defaults = false # No policies to import as of 27 SEP 2024
}

fast_features = {
  envs = true
}

assured_workloads = {
  regime   = "${COMPLIANCE_REGIME}" # "IL4, IL5, FEDRAMP_HIGH, etc... if you wish to not use assured_workloads, set this value to COMPLIANCE_REGIME_UNSPECIFIED"
  location = "${REGION}" # Uses the same region as other resources for consistency
}

bootstrap_project = "${BOOTSTRAP_PROJECT_ID}"

alert_email = "${LOGGING_ALERTS_EMAIL_ADDRESS}"
EOF
  fi

  # Create temporary providers.tf
  if [ ! -f "0-bootstrap-providers.tf" ] || promptUser "Would you like to generate your initial providers.tf?"; then
    cp providers.tf.tmp 0-bootstrap-providers.tf
  fi

  promptUser "Would you like to perform the initial terraform init?" "terraform init"

  # Terraform Apply #1
  if promptUser "Would you like to run the first terraform apply with the bootstrap user?"; then
    terraform apply -var bootstrap_user="$(gcloud config list --format 'value(core.account)')"
  fi

  if promptUser "Would you like to Update the Assured Workloads folder to allow BigQuery?"; then
    "${SCRIPT_DIR}"/allow_bq.sh
    echo "Please wait for two minutes for the changes to take effect"
    sleep 120 
  fi

  # Terraform Apply #2
  cmd=("terraform apply -var bootstrap_user=$(gcloud config list --format 'value(core.account)')")
  promptUser "Would you like to run the second terraform apply with the bootstrap user?" "${cmd[@]}"

  # Set Default Project
  cmd=("gcloud config set project ${PREFIX}-prod-iac-core-0")
  promptUser "Would you like to set the default project to ${PREFIX}-prod-iac-core-0" "${cmd[@]}"

  # Update Providers
  cmd=("gcloud storage cp gs://${PREFIX}-prod-iac-core-outputs-0/providers/0-bootstrap-providers.tf ./")
  promptUser "Would you like to update your providers file?" "${cmd[@]}" # Pass the array elements

  # Migrate State
  cmd=("terraform init --migrate-state")
  promptUser "Would you like to migrate to the remote state to ${PREFIX}-prod-iac-core-0?" "${cmd[@]}"

  # Import Organization Polcies
  promptUser "Would you like to import recommended org policies?" "./import.sh"

  # Terraform Apply #2
  promptUser "Would you like to run the third terraform apply (without the bootstrap user)?" "terraform apply"
fi

########### Stage 1 - Resman ############
echo -e "\n#######################################################"
echo "#######################################################"
echo "#######################################################"

if promptUser "Stage 1 - Resource Manager -"; then
  cd "${SCRIPT_DIR}"/../fast/stages-aw/1-resman || exit
  if promptUser "Would you like to provide billing account admin permissions for ${PREFIX}-prod-resman-0@${PREFIX}-prod-iac-core-0.iam.gserviceaccount.com?"; then
    gcloud billing accounts add-iam-policy-binding "${BILLING_ACCOUNT}" --member=serviceAccount:"${PREFIX}"-prod-resman-0@"${PREFIX}"-prod-iac-core-0.iam.gserviceaccount.com  --role=roles/billing.admin
  fi

  # Generate new tfvars - this will not work indented
  if promptUser "Would you like to generate a new 1-resman tfvars?"; then
cat <<EOF > terraform.tfvars
tenants = {
${TENANT_NAME} = { ## Updated with tenant-name variable
  admin_principal  = "group:gcp-devops@${FULLY_QUALIFIED_DOMAIN_NAME}"
  descriptive_name = "${TENANT_NAME}" ## Updated with tenant-name variable
  locations = {
    gcs = "${REGION}"
    kms = "${REGION}" # Must match GCS Region
   }
 }
## You can have “n” number of tenants
}

fast_features = {
 envs = true
}

envs_folders = {
 Prod = {
   admin = "gcp-organization-admins@${FULLY_QUALIFIED_DOMAIN_NAME}"
 },
 Int = {
  admin = "gcp-organization-admins@${FULLY_QUALIFIED_DOMAIN_NAME}"
 },
 Test = {
   admin = "gcp-organization-admins@${FULLY_QUALIFIED_DOMAIN_NAME}"
 }
}
EOF
  fi

  # Modify tfvars prompt
  echo -e "\nIf you have more than one tenant, please modify your tfvars."
  echo "Press any key when ready."
  read -r -n 1 -s -p ""

  # Copy remote tfvars
  cmd=(
    "gcloud storage cp gs://${PREFIX}-prod-iac-core-outputs-0/providers/1-resman-providers.tf ./"
    "gcloud storage cp gs://${PREFIX}-prod-iac-core-outputs-0/tfvars/0-globals.auto.tfvars.json ./"
    "gcloud storage cp gs://${PREFIX}-prod-iac-core-outputs-0/tfvars/0-bootstrap.auto.tfvars.json ./"
  )
  promptUser "Would you like to pull the remote tfvars files created in Stage 0?" "${cmd[@]}"

  promptUser "Would you like to perform the terraform init?" "terraform init"
  promptUser "Would you like to perform the terraform apply?" "terraform apply"

  echo "Congratulations, you have completed Stage 1!"
fi

########### Stage 2 - Networking ############
echo -e "\n#######################################################"
echo "#######################################################"
echo "#######################################################"

if promptUser "Stage 2 - Networking -"; then
  # Add external billing account
  if promptUser "Would you like to provide billing account admin permissions for ${PREFIX}-prod-resman-net-0@${PREFIX}-prod-iac-core-0.iam.gserviceaccount.com?"; then
    gcloud billing accounts add-iam-policy-binding "${BILLING_ACCOUNT}" --member=serviceAccount:"${PREFIX}"-prod-resman-net-0@"${PREFIX}"-prod-iac-core-0.iam.gserviceaccount.com  --role=roles/billing.admin
  fi

  # Choose networking paradigm
  cd "${SCRIPT_DIR}"/../fast/stages-aw/1-resman || exit

  echo "Please type \"1\", \"2\", or \"3\" below that corresponds to the network paradigm you want: "
  echo "1) IL2/FedRAMP Moderate"
  echo "2) FedRAMP High"
  echo "3) IL4/IL5"
  read -r choice

  ########### IL2/FedRAMP Moderate ###########
  if [ "$choice" == 1 ]; then
    echo "This stage is still under development. Goodbye!"

  ########### FedRAMP High ###########
  elif [ "$choice" == 2 ]; then
    echo "You have selected FedRAMP High"
    cd "${SCRIPT_DIR}"/../fast/stages-aw/2-networking-a-fedramp-high || exit

    if promptUser "Would you like to pull the remote tfvars files created in Stages 0 and 1?"; then
      gcloud storage cp gs://"${PREFIX}"-prod-iac-core-outputs-0/providers/2-networking-providers.tf ./
      gcloud storage cp gs://"${PREFIX}"-prod-iac-core-outputs-0/tfvars/0-globals.auto.tfvars.json ./
      gcloud storage cp gs://"${PREFIX}"-prod-iac-core-outputs-0/tfvars/0-bootstrap.auto.tfvars.json ./
      gcloud storage cp gs://"${PREFIX}"-prod-iac-core-outputs-0/tfvars/1-resman.auto.tfvars.json ./
    fi

    promptUser "Would you like to perform the terraform init?" "terraform init"
    if promptUser "Would you like to perform the terraform apply?"; then
      terraform apply

      # Potential Service Account/KMS bugs
      echo 'If you receive an error relating to a service account not existing, please click “Settings” in gcs within the project, and it will generate the service account for you.'
      promptUser "Would you like to rerun the apply due to the above error?" "terraform apply"

      promptUser "Would you like to rerun the terraform apply due to a peering error" "terraform apply"
    fi

  ########### IL4/IL5 ###########
  elif [ "$choice" == 3 ]; then
    echo "You have selected IL5"
    cd "${SCRIPT_DIR}"/../fast/stages-aw/2-networking-b-il5-ngfw || exit

    # cmd=("./pre-redeploy.sh")
    # promptUser "If this is a redeployment (<30 days), would you like to run the redeploy script?" "${cmd[@]}"

    if promptUser "Would you like to pull the remote tfvars files created in Stages 0 and 1?"; then
      gcloud storage cp gs://"${PREFIX}"-prod-iac-core-outputs-0/providers/2-networking-providers.tf ./
      gcloud storage cp gs://"${PREFIX}"-prod-iac-core-outputs-0/tfvars/0-globals.auto.tfvars.json ./
      gcloud storage cp gs://"${PREFIX}"-prod-iac-core-outputs-0/tfvars/0-bootstrap.auto.tfvars.json ./
      gcloud storage cp gs://"${PREFIX}"-prod-iac-core-outputs-0/tfvars/1-resman.auto.tfvars.json ./
    fi

    promptUser "Would you like to perform the terraform init?" "terraform init"

    cmd=("terraform apply -target google_project_iam_custom_role.ngfw-custom-role")
    promptUser "Would you like to perform the targeted terraform apply?" "${cmd[@]}"

    promptUser "Would you like to perform the full terraform apply?" "terraform apply"

    # Potential Service Account/KMS bugs
    echo 'If you receive an error relating to a service account not existing, please click “Settings” in gcs within the project, and it will generate the service account for you.'
    promptUser "Would you like to rerun the apply due to the above error?" "terraform apply"

    promptUser "Would you like to rerun the terraform apply due to a peering error" "terraform apply"
  fi

  echo "Congratulations, you have completed Stage 2!"
fi

########### Stage 3 - Security ############
echo -e "\n#######################################################"
echo "#######################################################"
echo "#######################################################"

if promptUser "Stage 3 - Security -"; then
  cd "${SCRIPT_DIR}"/../fast/stages-aw/3-security || exit

  # Add external billing account
  if promptUser "Would you like to provide billing account admin permissions for ${PREFIX}-security-0@${PREFIX}-prod-iac-core-0.iam.gserviceaccount.com?"; then
    gcloud billing accounts add-iam-policy-binding "${BILLING_ACCOUNT}" --member=serviceAccount:"${PREFIX}"-security-0@"${PREFIX}"-prod-iac-core-0.iam.gserviceaccount.com  --role=roles/billing.admin
  fi

  if promptUser "Would you like to pull the remote tfvars files created in Stages 0 and 1?"; then
    gcloud storage cp gs://"${PREFIX}"-prod-iac-core-outputs-0/providers/3-security-providers.tf ./
    gcloud storage cp gs://"${PREFIX}"-prod-iac-core-outputs-0/tfvars/0-globals.auto.tfvars.json ./
    gcloud storage cp gs://"${PREFIX}"-prod-iac-core-outputs-0/tfvars/0-bootstrap.auto.tfvars.json ./
    gcloud storage cp gs://"${PREFIX}"-prod-iac-core-outputs-0/tfvars/1-resman.auto.tfvars.json ./
  fi

    promptUser "Would you like to perform the terraform init?" "terraform init"
    promptUser "Would you like to perform the terraform apply?" "terraform apply"

    echo -e "\nIf you receive an error relating to a service account, please rerun the apply."
    promptUser "Would you like to rerun the apply due to the above error?" "terraform apply"

    promptUser "Would you like to run the lockdown script?" "./sa_lockdown.sh"

    # promptUser "Would you like to delete the bootstrap project?" "./delete_gcp_project.sh --project-id=${BOOTSTRAP_PROJECT_ID}"

    echo "Congratulations, you have finished Stage 3! Please see the SBPG linked below for further hardening."
    echo 'https://docs.google.com/document/d/1uv62Fqg73r9oJNP-NPZebpzoBom8rOgLoHkiMZPutbo/edit?usp=drive_link'
fi
