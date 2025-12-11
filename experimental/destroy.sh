#!/bin/bash

#### Use this script at your own risk. The author assumes no responsibility for any damages or losses incurred through its use.

# Enable error handling
# Note: NOT using 'set -e' because it conflicts with interactive prompt functions
# that return non-zero as part of normal operation (e.g., when user says "no")
set -o pipefail

# Global variables
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}" || exit

# Source common functions
if [[ -f "${SCRIPT_DIR}/common-functions.sh" ]]; then
    # shellcheck source=experimental/common-functions.sh
    source "${SCRIPT_DIR}/common-functions.sh"
else
    # Fallback logging if common functions not available
    log_info() { echo -e "\033[0;32m[INFO]\033[0m $1"; }
    log_warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }
    log_error() { echo -e "\033[0;31m[ERROR]\033[0m $1" >&2; }
    # Fallback for gcloud_safe - just run gcloud directly
    gcloud_safe() { gcloud "$@"; }
    safe_delete() { log_warn "safe_delete not available without common-functions.sh"; return 1; }
fi

# Enhanced error handler with cleanup
error_handler() {
    local line_no=$1
    local exit_code=$?
    log_error "Script failed at line $line_no with exit code $exit_code"
    log_info "You may need to run clean.sh to complete cleanup"

    # Attempt to save current state
    if [[ -n "${PREFIX:-}" ]]; then
        echo "LAST_FAILED_OPERATION=destroy" >> "${SCRIPT_DIR}/last_operation.env" 2>/dev/null || true
        echo "LAST_FAILED_LINE=$line_no" >> "${SCRIPT_DIR}/last_operation.env" 2>/dev/null || true
    fi

    cleanup
    exit "$exit_code"
}

# Note: error_handler is already defined above, no need for setup_error_handling
trap 'error_handler $LINENO' ERR

# Improved prompt function with better error handling
promptUser() {
    local prompt="$1"
    shift
    local commands=("$@")

    while true; do
        echo
        log_warn "DESTRUCTIVE OPERATION: $prompt"
        echo "Please choose: [y]es / [n]o / [s]kip"
        read -r choice

        case "$choice" in
            [Yy]|[Yy][Ee][Ss])
                log_info "Executing commands..."
                for cmd in "${commands[@]}"; do
                    log_info "Running: $cmd"
                    if ! bash -c "$cmd"; then
                        log_error "Command failed: $cmd"
                        echo "Continue anyway? [y/N]"
                        read -r continue_choice
                        if [[ ! "$continue_choice" =~ ^[Yy] ]]; then
                            log_warn "Skipping failed command and continuing"
                            break
                        fi
                    fi
                done
                return 0
                ;;
            [Nn]|[Nn][Oo])
                log_warn "Skipping: $prompt"
                return 1
                ;;
            [Ss]|[Ss][Kk][Ii][Pp])
                log_warn "Skipping: $prompt"
                return 255
                ;;
            *)
                log_error "Invalid choice. Please enter y, n, or s."
                ;;
        esac
    done
}

########### DANGER: DESTRUCTIVE OPERATIONS ############
log_error "=== WARNING: DESTRUCTIVE SCRIPT ==="
log_error "This script will DELETE your ENTIRE environment!"
log_error "This includes all projects, resources, and local .terraform directories!"
echo
log_warn "Please ensure you have:"
echo "  • Backed up any important data"
echo "  • Confirmed this is the correct environment to destroy"
echo "  • Run any necessary export/backup scripts"
echo

if ! promptUser "Do you want to proceed with DESTROYING the entire environment?"; then
    log_info "Destruction cancelled by user. Exiting safely."
    exit 0
fi

# Load configuration
if [ ! -f "$SCRIPT_DIR"/config.env ]; then
    log_error "config.env file not found. Please run deploy.sh first or create the config file."
    exit 1
fi

if promptUser "Would you like to overwrite your config.env file?"; then
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
    read -r -p "Enter your Assured Workload region: " AW_REGION
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
    echo "aw-region: $AW_REGION"
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
      echo "AW_REGION=$AW_REGION"
      echo "TENANT_NAME=$TENANT_NAME"
    } > "$SCRIPT_DIR"/config.env
else
    # shellcheck source=experimental/config.env.sample
    if ! source "$SCRIPT_DIR"/config.env; then
        log_error "Failed to source config.env file"
        exit 1
    fi

    log_info "Current configuration:"
    echo "------------------------------------------------------------------"
    cat config.env
    echo "------------------------------------------------------------------"

    # Validate critical variables exist
    if [[ -z "${PREFIX:-}" ]] || [[ -z "${ORGANIZATION_ID:-}" ]] || [[ -z "${BILLING_ACCOUNT:-}" ]]; then
        log_error "Missing critical variables in config.env (PREFIX, ORGANIZATION_ID, or BILLING_ACCOUNT)"
        exit 1
    fi

    log_warn "Please verify the above configuration is correct before proceeding with destruction"
fi

if promptUser "Would you like to reauthenticate?"; then
  if [[ -n "${DEPLOYER_EMAIL_ADDRESS:-}" ]]; then
      gcloud auth revoke "${DEPLOYER_EMAIL_ADDRESS}" || log_warn "Failed to revoke auth for ${DEPLOYER_EMAIL_ADDRESS}"
  fi
  gcloud auth login
  gcloud auth application-default login
fi

if promptUser "Would you like to set your default project to ${PREFIX}-prod-iac-core-0?"; then
  if gcloud config set project "${PREFIX}-prod-iac-core-0"; then
    log_info "Default project set to ${PREFIX}-prod-iac-core-0"

    # Set the quota project to match to avoid quota issues
    log_info "Setting Application Default Credentials quota project to match..."
    if gcloud auth application-default set-quota-project "${PREFIX}-prod-iac-core-0" 2>/dev/null; then
      log_info "Quota project updated successfully"
    else
      log_warn "Could not update quota project - you may encounter quota issues"
    fi
  else
    log_warn "Failed to set default project, but continuing with destruction"
  fi
fi

# if promptUser "Would you to set your IAM permissions?"; then
#   "${SCRIPT_DIR}"/../fast/stages-aw/0-bootstrap/setIAM.sh "${DEPLOYER_EMAIL_ADDRESS}" "${ORGANIZATION_ID}"
# fi

if promptUser "Would you like to disable org policies to allow for deletion?"; then
  # Use safe deletion for custom constraint
  safe_delete "custom-constraint" "custom.kmsRotation${PREFIX}" --organization="${ORGANIZATION_ID}" || log_warn "Custom constraint may not exist or already deleted"

  # Disable org policy with retry mechanism
  if ! gcloud_safe resource-manager org-policies disable-enforce compute.requireOsLogin --organization="${ORGANIZATION_ID}"; then
    log_warn "Failed to disable compute.requireOsLogin policy, continuing anyway"
  fi

  log_info "Waiting 60 seconds for policy changes..."; sleep 60
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
  
  if promptUser "Would you like to run terraform destroy?"; then
    if ! terraform destroy; then
      log_error "Terraform destroy failed, but continuing with cleanup"
    fi
  fi

  if promptUser "Would you like to delete your .terraform dir and related files?"; then
    # Comprehensive terraform cleanup for stage 3
    if [[ -d ".terraform" ]]; then
      rm -rf .terraform
      log_info "Deleted .terraform directory"
    else
      log_warn ".terraform directory does not exist"
    fi

    # Remove terraform lock file
    if [[ -f ".terraform.lock.hcl" ]]; then
      rm -f .terraform.lock.hcl
      log_info "Deleted .terraform.lock.hcl"
    else
      log_warn ".terraform.lock.hcl does not exist"
    fi

    # Remove any backup state files
    if [[ -f "terraform.tfstate.backup" ]]; then
      rm -f terraform.tfstate.backup
      log_info "Deleted terraform.tfstate.backup"
    fi
  fi

  if promptUser "Would you like to remove billing account admin permissions for ${PREFIX}-security-0@${PREFIX}-prod-iac-core-0.iam.gserviceaccount.com?"; then
    if ! gcloud_safe billing accounts remove-iam-policy-binding "${BILLING_ACCOUNT}" \
      --member="serviceAccount:${PREFIX}-security-0@${PREFIX}-prod-iac-core-0.iam.gserviceaccount.com" \
      --role=roles/billing.admin; then
      log_warn "Failed to remove billing permissions, but continuing"
    fi
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

    if promptUser "Would you like to run terraform destroy?"; then
      destroy_success=false
      max_attempts=3
      attempt=1

      while [[ $attempt -le $max_attempts ]] && [[ "$destroy_success" == "false" ]]; do
        log_info "Terraform destroy attempt $attempt/$max_attempts"

        if terraform destroy; then
          destroy_success=true
          log_info "Terraform destroy completed successfully"
        else
          if [[ $attempt -lt $max_attempts ]]; then
            log_warn "Terraform destroy failed, checking for common issues..."

            # Check for peering errors (common during network destruction)
            if terraform show 2>/dev/null | grep -q "peering\|network" || [[ -f .terraform.tfstate.backup ]]; then
              log_warn "Likely network peering timing issues, waiting for resources to settle..."
              log_info "Waiting 60 seconds for network resource deletion..."; sleep 60
              ((attempt++))
            else
              log_warn "Terraform destroy failed with non-peering error"
              if promptUser "Would you like to retry destroy (attempt $((attempt+1))/$max_attempts)?"; then
                ((attempt++))
              else
                break
              fi
            fi
          else
            log_error "Terraform destroy failed after $max_attempts attempts"
            if promptUser "Would you like to try one more manual attempt?"; then
              terraform destroy && destroy_success=true
            fi
            break
          fi
        fi
      done

      if [[ "$destroy_success" == "false" ]]; then
        log_error "Unable to complete terraform destroy. Manual cleanup may be required."
      fi
    fi

    if promptUser "Would you like to delete your .terraform dir and related files?"; then
      # Comprehensive terraform cleanup for stage 2 - FedRAMP High
      if [[ -d ".terraform" ]]; then
        rm -rf .terraform
        log_info "Deleted .terraform directory"
      else
        log_warn ".terraform directory does not exist"
      fi

      # Remove terraform lock file
      if [[ -f ".terraform.lock.hcl" ]]; then
        rm -f .terraform.lock.hcl
        log_info "Deleted .terraform.lock.hcl"
      else
        log_warn ".terraform.lock.hcl does not exist"
      fi

      # Remove any backup state files
      if [[ -f "terraform.tfstate.backup" ]]; then
        rm -f terraform.tfstate.backup
        log_info "Deleted terraform.tfstate.backup"
      fi
    fi

  ########### IL4/IL5 ###########
  elif [ "$choice" == 3 ]; then
    cd "${SCRIPT_DIR}"/../fast/stages-aw/2-networking-b-il5-ngfw || exit

    if promptUser "Would you like to run terraform destroy?"; then
      destroy_success=false
      max_attempts=3
      attempt=1

      while [[ $attempt -le $max_attempts ]] && [[ "$destroy_success" == "false" ]]; do
        log_info "Terraform destroy attempt $attempt/$max_attempts"

        if terraform destroy; then
          destroy_success=true
          log_info "Terraform destroy completed successfully"
        else
          if [[ $attempt -lt $max_attempts ]]; then
            log_warn "Terraform destroy failed, checking for common issues..."

            # Check for peering errors (common during network destruction)
            if terraform show 2>/dev/null | grep -q "peering\|network" || [[ -f .terraform.tfstate.backup ]]; then
              log_warn "Likely network peering timing issues, waiting for resources to settle..."
              log_info "Waiting 60 seconds for network resource deletion..."; sleep 60
              ((attempt++))
            else
              log_warn "Terraform destroy failed with non-peering error"
              if promptUser "Would you like to retry destroy (attempt $((attempt+1))/$max_attempts)?"; then
                ((attempt++))
              else
                break
              fi
            fi
          else
            log_error "Terraform destroy failed after $max_attempts attempts"
            if promptUser "Would you like to try one more manual attempt?"; then
              terraform destroy && destroy_success=true
            fi
            break
          fi
        fi
      done

      if [[ "$destroy_success" == "false" ]]; then
        log_error "Unable to complete terraform destroy. Manual cleanup may be required."
      fi
    fi

    if promptUser "Would you like to delete your .terraform dir and related files?"; then
      # Comprehensive terraform cleanup for stage 2 - IL4/IL5
      if [[ -d ".terraform" ]]; then
        rm -rf .terraform
        log_info "Deleted .terraform directory"
      else
        log_warn ".terraform directory does not exist"
      fi

      # Remove terraform lock file
      if [[ -f ".terraform.lock.hcl" ]]; then
        rm -f .terraform.lock.hcl
        log_info "Deleted .terraform.lock.hcl"
      else
        log_warn ".terraform.lock.hcl does not exist"
      fi

      # Remove any backup state files
      if [[ -f "terraform.tfstate.backup" ]]; then
        rm -f terraform.tfstate.backup
        log_info "Deleted terraform.tfstate.backup"
      fi
    fi
  fi
  
  if promptUser "Would you like to remove billing account admin permissions for the ${PREFIX}-prod-resman-net-0@${PREFIX}-prod-iac-core-0.iam.gserviceaccount.com?"; then
    gcloud billing accounts remove-iam-policy-binding "${BILLING_ACCOUNT}" --member=serviceAccount:"${PREFIX}"-prod-resman-net-0@"${PREFIX}"-prod-iac-core-0.iam.gserviceaccount.com --role=roles/billing.admin
  fi
fi

########### Stage 1 - Resman ############
echo -e "\n#######################################################"
echo "#######################################################"
echo "#######################################################"

if promptUser "Stage 1 - Resource Manager"; then
  cd "${SCRIPT_DIR}"/../fast/stages-aw/1-resman || exit

    # CRITICAL: Remove storage buckets BEFORE terraform destroy to avoid force_destroy errors
    if promptUser "Would you like to remove all storage buckets (required to avoid force_destroy errors)?"; then
      log_info "Discovering and removing tenant storage buckets..."

      # First, remove buckets from terraform state to avoid force_destroy errors
      log_info "Removing tenant buckets from terraform state..."
      bucket_resources=$(terraform state list 2>/dev/null | grep "google_storage_bucket.bucket" || echo "")
      if [[ -n "$bucket_resources" ]]; then
        while IFS= read -r resource; do
          # Match pattern: module.tenant-self-iac-gcs-outputs["Test-lz01"] or module.tenant-self-iac-gcs-outputs["Prod-lz01"]
          if [[ "$resource" =~ tenant-self-iac-gcs-outputs ]]; then
            log_info "  Removing from state: $resource"
            terraform state rm "$resource" 2>/dev/null || log_warn "Failed to remove $resource from state"
          fi
        done <<< "$bucket_resources"
      else
        log_info "No bucket resources found in terraform state"
      fi

      # Get list of all tenant buckets matching the prefix pattern (case-insensitive)
      tenant_buckets=$(gcloud storage buckets list --format="value(name)" 2>/dev/null | grep -iE "^${PREFIX}-(test|int|prod)-.*-iac-outputs-[0-9]+$" | sed 's|^|gs://|' | tr '\n' ' ' || echo "")

      if [[ -n "$tenant_buckets" ]]; then
        log_info "Found tenant buckets: $tenant_buckets"

        # Then delete the actual buckets
        for bucket in $tenant_buckets; do
          log_info "Removing all objects from bucket: $bucket"

          # First, remove all objects inside the bucket (force removal)
          if ! gcloud_safe storage rm -r "${bucket}/**" 2>/dev/null; then
            log_warn "No objects found in $bucket or removal failed, continuing..."
          fi

          # Then remove the empty bucket
          log_info "Removing empty bucket: $bucket"
          bucket_name=${bucket#gs://}
          if ! gcloud_safe storage buckets delete "gs://${bucket_name}"; then
            log_warn "Failed to remove bucket $bucket, continuing..."
          fi
        done
      else
        log_info "No tenant storage buckets found matching pattern gs://${PREFIX}-*-iac-outputs-*"
      fi

      # Remove management buckets
      log_info "Removing management buckets from terraform state..."
      terraform state rm "module.net-sa-resman-0.google_storage_bucket_iam_binding.authoritative[\"${PREFIX}-prod-resman-net-0-roles/storage.admin\"]" 2>/dev/null || true
      terraform state rm "module.sec-sa-resman-0.google_storage_bucket_iam_binding.authoritative[\"${PREFIX}-prod-resman-sec-0-roles/storage.admin\"]" 2>/dev/null || true

      mgmt_buckets=(
        "gs://${PREFIX}-prod-resman-sec-0"
        "gs://${PREFIX}-prod-resman-net-0"
      )

      for bucket in "${mgmt_buckets[@]}"; do
        log_info "Removing all objects from management bucket: $bucket"

        # First, remove all objects inside the bucket (force removal)
        if ! gcloud_safe storage rm -r "${bucket}/**" 2>/dev/null; then
          log_warn "No objects found in $bucket or removal failed, continuing..."
        fi

        # Then remove the empty bucket
        log_info "Removing empty management bucket: $bucket"
        bucket_name=${bucket#gs://}
        if ! gcloud_safe storage buckets delete "gs://${bucket_name}"; then
          log_warn "Failed to remove management bucket $bucket, continuing..."
        fi
      done

      log_info "Storage bucket cleanup completed - terraform destroy should now proceed without force_destroy errors"
    else
      log_warn "Skipping bucket cleanup - terraform destroy may fail with force_destroy errors"
      log_info "If terraform destroy fails, manually run: gcloud storage rm -r gs://${PREFIX}-*-iac-outputs-*"
    fi

    promptUser "Would you like to run terraform destroy?" "terraform destroy -lock=false"

    if promptUser "If you received an error for TagValues, would you like to delete all child tags?"; then
      read -r -p "Please enter the TagValue from the above error - numbers only" TAG
      gcloud resource-manager tags values delete tagValues/"${TAG}"
      terraform destroy
    fi

    if promptUser "Would you like to delete your .terraform dir and related files?"; then
      # Comprehensive terraform cleanup for stage 1
      if [[ -d ".terraform" ]]; then
        rm -rf .terraform
        log_info "Deleted .terraform directory"
      else
        log_warn ".terraform directory does not exist"
      fi

      # Remove terraform lock file
      if [[ -f ".terraform.lock.hcl" ]]; then
        rm -f .terraform.lock.hcl
        log_info "Deleted .terraform.lock.hcl"
      else
        log_warn ".terraform.lock.hcl does not exist"
      fi

      # Remove any backup state files
      if [[ -f "terraform.tfstate.backup" ]]; then
        rm -f terraform.tfstate.backup
        log_info "Deleted terraform.tfstate.backup"
      fi
    fi

    # Remove resman billing permissions
    if promptUser "Would you like to remove billing account admin permissions for ${PREFIX}-prod-resman-0@${PREFIX}-prod-iac-core-0.iam.gserviceaccount.com?"; then
      if ! gcloud_safe billing accounts remove-iam-policy-binding "${BILLING_ACCOUNT}" \
        --member="serviceAccount:${PREFIX}-prod-resman-0@${PREFIX}-prod-iac-core-0.iam.gserviceaccount.com" \
        --role=roles/billing.admin; then
        log_warn "Failed to remove resman billing permissions, but continuing"
      fi
    fi
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

  # Bootstrap stage uses LOCAL state (not remote), so just verify it exists
  log_info "Verifying bootstrap state configuration..."
  if [[ -f "./terraform.tfstate" ]]; then
    log_info "✓ Found local terraform state file"

    # Verify providers are configured for local backend
    if grep -q "backend.*gcs" 0-bootstrap-providers.tf 2>/dev/null; then
      log_warn "Providers incorrectly configured for remote backend - fixing..."
      if [[ -f "providers.tf.tmp" ]]; then
        cp providers.tf.tmp 0-bootstrap-providers.tf
        log_info "Reverted providers to local backend configuration"
        terraform init -reconfigure
      else
        log_error "providers.tf.tmp not found - cannot revert providers"
        log_error "You may need to manually remove backend configuration from 0-bootstrap-providers.tf"
        exit 1
      fi
    else
      log_info "✓ Providers correctly configured for local backend"
    fi
  else
    log_error "❌ Local terraform.tfstate not found in $(pwd)"
    log_error "Bootstrap stage should use local state, but no state file exists"
    log_error "Either:"
    log_error "  1. Bootstrap was never deployed (nothing to destroy)"
    log_error "  2. State file was accidentally deleted"
    log_error "  3. You're in the wrong directory"

    if promptUser "Do you want to continue anyway and try to destroy without state?"; then
      log_warn "Continuing without state - Terraform will attempt to destroy based on configuration only"
      terraform init -reconfigure
    else
      log_info "Exiting - please locate the terraform.tfstate file or confirm bootstrap was deployed"
      exit 1
    fi
  fi

  # CRITICAL: Always restore permissions before any destroy operations (no prompt)
  log_info "Restoring IAM permissions for destroy operations..."
  if [[ -f "${SCRIPT_DIR}/../fast/stages-aw/0-bootstrap/setIAM.sh" ]]; then
    if "${SCRIPT_DIR}/../fast/stages-aw/0-bootstrap/setIAM.sh" "${DEPLOYER_EMAIL_ADDRESS}" "${ORGANIZATION_ID}"; then
      log_info "IAM permissions restored successfully"
      log_info "Waiting 120 seconds for IAM propagation..."; sleep 120

      # Verify critical permissions are in place
      log_info "Verifying critical permissions..."
      current_user=$(gcloud config list --format 'value(core.account)')
      required_roles=(
        "roles/resourcemanager.projectDeleter"
        "roles/resourcemanager.organizationAdmin"
        "roles/owner"
        "roles/assuredworkloads.admin"
      )

      missing_roles=()
      for role in "${required_roles[@]}"; do
        if ! gcloud organizations get-iam-policy "${ORGANIZATION_ID}" \
          --flatten="bindings[].members" \
          --filter="bindings.role:$role AND bindings.members:user:$current_user" \
          --format="value(bindings.role)" 2>/dev/null | grep -q "$role"; then
          missing_roles+=("$role")
        fi
      done

      if [[ ${#missing_roles[@]} -gt 0 ]]; then
        log_error "Missing critical permissions for destroy operations:"
        printf '%s\n' "${missing_roles[@]}"
        log_error "The destroy operation will likely fail without these permissions"
        if ! promptUser "Do you want to continue anyway?"; then
          exit 1
        fi
      else
        log_info "All critical permissions verified successfully"
      fi
    else
      log_error "Failed to restore IAM permissions"
      exit 1
    fi
  else
    log_error "setIAM.sh script not found at ${SCRIPT_DIR}/../fast/stages-aw/0-bootstrap/setIAM.sh"
    log_error "Cannot proceed without proper permissions"
    exit 1
  fi

  # CRITICAL: Proactive Assured Workloads cleanup BEFORE terraform destroy (AUTOMATIC - NO PROMPT)
  log_info "=========================================="
  log_info "ASSURED WORKLOADS CLEANUP (AUTOMATIC)"
  log_info "=========================================="
  log_info "Checking ALL regions for Assured Workloads..."
  current_account=$(gcloud config list --format 'value(core.account)')

  # Check multiple regions (not just one)
  AW_REGIONS=("us-east4" "us-west1" "us-central1" "us-east1")
  if [[ -n "${AW_REGION:-}" ]]; then
    # Add configured region if not already in list
    if [[ ! " ${AW_REGIONS[*]} " == *" ${AW_REGION} "* ]]; then
      AW_REGIONS+=("${AW_REGION}")
    fi
  fi
  if [[ -n "${REGION:-}" ]]; then
    # Add configured primary region if not already in list
    if [[ ! " ${AW_REGIONS[*]} " == *" ${REGION} "* ]]; then
      AW_REGIONS+=("${REGION}")
    fi
  fi

  log_info "Will check regions: ${AW_REGIONS[*]}"
  echo

    # Helper function to wait for project deletion
    wait_for_project_deletion() {
      local project_id="$1"
      local max_wait=30  # 2.5 minutes in 5-second intervals
      local wait_count=0

      while [[ $wait_count -lt $max_wait ]]; do
        if ! gcloud projects describe "$project_id" >/dev/null 2>&1; then
          log_info "Project $project_id is now deleted"
          return 0
        fi
        sleep 5
        ((wait_count++)) || true
      done

      log_warn "Project $project_id still exists after waiting"
      return 1
    }

    # Recursive function to clean up folders
    clean_folder_recursive() {
      local folder_id="$1"
      log_info "Cleaning up folder $folder_id..."

      # 1. Delete projects in this folder
      local projects
      projects=$(gcloud projects list --filter="parent.id=$folder_id" --format="value(projectId)" 2>/dev/null || echo "")
      
      if [[ -n "$projects" ]]; then
          log_info "Found projects in folder $folder_id: $(echo "$projects" | tr '\n' ' ')"
          for project in $projects; do
            # Remove liens
            gcloud_safe alpha resource-manager liens list --project="$project" --format="value(name)" 2>/dev/null | while read -r lien; do
              if [[ -n "$lien" ]]; then
                log_info "Removing lien $lien from project $project"
                gcloud_safe alpha resource-manager liens delete "$lien" || true
              fi
            done
            # Unlink billing
            gcloud_safe billing projects unlink "$project" 2>/dev/null || true
            # Delete project
            if ! gcloud_safe projects delete "$project" --quiet; then
              log_warn "Failed to delete project $project - checking if already deleted..."
              if gcloud projects describe "$project" >/dev/null 2>&1; then
                  log_error "Project $project still exists and could not be deleted"
              else
                  log_info "Project $project appears to be deleted already"
              fi
            else
                wait_for_project_deletion "$project"
            fi
          done
      else
          log_info "No projects found in folder $folder_id"
      fi

      # 2. Recurse into sub-folders
      local subfolders
      subfolders=$(gcloud resource-manager folders list --folder="$folder_id" --format="value(name)" 2>/dev/null || echo "")
      
      if [[ -n "$subfolders" ]]; then
          log_info "Found subfolders in folder $folder_id: $(echo "$subfolders" | tr '\n' ' ')"
          for subfolder in $subfolders; do
            local subfolder_id=${subfolder##*/}
            clean_folder_recursive "$subfolder_id"
          done
      else
          log_info "No subfolders found in folder $folder_id"
      fi

      # 3. Try to delete the folder itself (don't fail if we can't, e.g. retention)
      if ! gcloud_safe resource-manager folders delete "$folder_id" --quiet 2>/dev/null; then
          log_warn "Could not delete folder $folder_id (might be retention protected or not empty)"
          # Verify if it's really empty
          if gcloud projects list --filter="parent.id=$folder_id" --format="value(projectId)" --limit=1 2>/dev/null | grep -q .; then
             log_error "Folder $folder_id is still not empty (projects remain)"
          elif gcloud resource-manager folders list --folder="$folder_id" --format="value(name)" --limit=1 2>/dev/null | grep -q .; then
             log_error "Folder $folder_id is still not empty (subfolders remain)"
          fi
      fi
    }

    # Ensure Assured Workloads admin permissions
    if ! gcloud organizations get-iam-policy "${ORGANIZATION_ID}" --flatten="bindings[].members" --format="table(bindings.role,bindings.members)" | grep -q "roles/assuredworkloads.admin.*$current_account"; then
      log_info "Granting Assured Workloads admin role to $current_account"
      if gcloud_safe organizations add-iam-policy-binding "${ORGANIZATION_ID}" \
        --member="user:$current_account" \
        --role="roles/assuredworkloads.admin"; then
        log_info "Successfully granted Assured Workloads admin role"
        sleep 30  # Wait for IAM propagation
      else
        log_warn "Failed to grant Assured Workloads admin role - may encounter issues later"
      fi
    else
      log_info "User already has Assured Workloads admin role"
    fi

  # List and handle existing workloads across ALL regions
  total_workloads_found=0
  total_workloads_deleted=0
  total_workloads_retained=0

  for region in "${AW_REGIONS[@]}"; do
    log_info "Checking region: $region..."
    workloads=$(gcloud assured workloads list \
      --organization="${ORGANIZATION_ID}" \
      --location="${region}" \
      --format="value(name)" 2>/dev/null || echo "")

    if [[ -z "$workloads" ]]; then
      log_info "  No workloads found in $region"
      continue
    fi

    workload_count=$(echo "$workloads" | wc -l)
    total_workloads_found=$((total_workloads_found + workload_count))
    log_info "  Found $workload_count workload(s) in $region"

    if [[ -n "$workloads" ]]; then

      for workload in $workloads; do
        workload_name=$(gcloud assured workloads describe "$workload" --location="${region}" --format="value(displayName)" 2>/dev/null || echo "Unknown")
        log_info "  Processing: $workload_name (region: $region)"

        # Get projects in this workload
        workload_projects=$(gcloud assured workloads describe "$workload" \
          --location="${region}" \
          --format="value(resources[].resourceId)" 2>/dev/null | grep "^projects/" | sed 's|projects/||' || echo "")

        if [[ -n "$workload_projects" ]]; then
          log_info "Found projects in workload: $workload_projects"

          # Clean up each project
          for project in $workload_projects; do
            log_info "Cleaning up project $project from workload"

            # Remove liens
            gcloud_safe resource-manager liens list --project="$project" --format="value(name)" 2>/dev/null | while read -r lien; do
              if [[ -n "$lien" ]]; then
                log_info "Removing lien: $lien"
                gcloud_safe resource-manager liens delete "$lien" || true
              fi
            done

            # Unlink billing
            gcloud_safe billing projects unlink "$project" 2>/dev/null || true

            # Delete project and wait for completion
            if gcloud_safe projects delete "$project" --quiet; then
              log_info "Project $project deletion initiated, waiting for completion..."
              wait_for_project_deletion "$project"
            else
              log_warn "Failed to delete project $project - will be handled by terraform later"
            fi
          done
        fi

        # Now delete the empty workload with proper retry logic
        log_info "    Attempting to delete workload: $workload_name"
        max_attempts=5
        attempt=1
        workload_deleted=false

        while [[ $attempt -le $max_attempts ]]; do
          log_info "    Attempt $attempt/$max_attempts"

          if gcloud_safe assured workloads delete "$workload" --location="${region}" --quiet; then
            log_info "    ✓ Successfully deleted workload: $workload_name"
            workload_deleted=true
            ((total_workloads_deleted++)) || true
            break
          else
            log_warn "    Attempt $attempt failed - workload may still contain resources"

            if [[ $attempt -lt $max_attempts ]]; then
              # Check what resources are still in the workload
              log_info "    Checking workload contents..."
              remaining_resources=$(gcloud assured workloads describe "$workload" \
                --location="${region}" \
                --format="value(resources[].resourceId)" 2>/dev/null || echo "")

              if [[ -n "$remaining_resources" ]]; then
                log_info "Workload still contains: $remaining_resources"

                # Aggressively clean up contained resources
                for resource in $remaining_resources; do
                  if [[ "$resource" =~ ^[0-9]+$ ]]; then
                     # It's a folder
                     log_info "Found folder $resource in workload - attempting recursive cleanup"
                     clean_folder_recursive "$resource"
                  fi
                done

                # Re-check contents after cleanup
                remaining_resources=$(gcloud assured workloads describe "$workload" \
                --location="${region}" \
                --format="value(resources[].resourceId)" 2>/dev/null || echo "")

                # Check if remaining resources are only undeletable Assured Workload folders
                only_aw_folders=true
                for resource in $remaining_resources; do
                  if [[ "$resource" =~ ^projects/ ]]; then
                    # It's a project, not just a folder
                    only_aw_folders=false
                    break
                  elif [[ "$resource" =~ ^[0-9]+$ ]]; then
                    # Check if it's an Assured Workload folder
                    folder_info=$(gcloud resource-manager folders describe "$resource" --format="value(displayName)" 2>/dev/null || echo "")
                    
                    # Verify if folder is actually empty
                    is_empty=true
                    if gcloud projects list --filter="parent.id=$resource" --format="value(projectId)" --limit=1 2>/dev/null | grep -q .; then
                        is_empty=false
                    elif gcloud resource-manager folders list --folder="$resource" --format="value(name)" --limit=1 2>/dev/null | grep -q .; then
                        is_empty=false
                    fi

                    if [[ "$is_empty" == "false" ]]; then
                        log_warn "Folder $resource ($folder_info) is NOT empty - recursive cleanup might have failed"
                        only_aw_folders=false
                    elif ! echo "$folder_info" | grep -qi "StellarEngine"; then
                      # It's a folder but not an Assured Workload folder
                      # If we reached here, recursive cleanup failed to delete it?
                      # Assume it might be an AW folder with different naming?
                      # Or just assume we can't delete it.
                      # Let's keep existing logic but be looser
                      # only_aw_folders=false
                      log_warn "Folder $resource ($folder_info) remains - might be retention protected"
                    fi
                  fi
                done

                if [[ "$only_aw_folders" == "true" ]]; then
                  log_warn "    Workload only contains Assured Workload folders (30-day retention)"
                  log_warn "    Cannot delete now - will auto-delete after retention period"
                  ((total_workloads_retained++)) || true
                  break  # Break out of the attempt loop
                fi

                log_info "Waiting for resources to be fully deleted..."
                # Poll for resource deletion status
                wait_count=0
                max_wait=24  # 2 minutes in 5-second intervals
                while [[ $wait_count -lt $max_wait ]]; do
                  still_exists=false
                  for resource in $remaining_resources; do
                    if [[ "$resource" =~ ^projects/ ]]; then
                      project_id=${resource#projects/}
                      if gcloud projects describe "$project_id" >/dev/null 2>&1; then
                        still_exists=true
                        break
                      fi
                    elif [[ "$resource" =~ ^[0-9]+$ ]]; then
                      # Folder ID - check if it still exists (excluding Assured Workload folders)
                      folder_info=$(gcloud resource-manager folders describe "$resource" --format="value(displayName,lifecycleState)" 2>/dev/null || echo "")
                      if [[ -n "$folder_info" ]] && echo "$folder_info" | grep -q "ACTIVE"; then
                        if ! echo "$folder_info" | grep -qi "StellarEngine"; then
                          # Non-Assured Workload folder still exists
                          still_exists=true
                          break
                        fi
                      fi
                    fi
                  done

                  if [[ "$still_exists" == "false" ]]; then
                    log_info "All deletable resources are now deleted"
                    break
                  fi

                  sleep 5
                  wait_count=$((wait_count + 1))
                done
              fi
            fi
          fi
          ((attempt++))
        done

        if [[ "$workload_deleted" == "false" ]] && [[ $attempt -gt $max_attempts ]]; then
          log_error "    ✗ Failed to delete workload: $workload_name"
          log_error "    This workload may require manual deletion"
          ((total_workloads_retained++)) || true
        fi
        echo
      done
    fi
  done

  # Summary of Assured Workloads cleanup
  echo
  log_info "=========================================="
  log_info "ASSURED WORKLOADS CLEANUP SUMMARY"
  log_info "=========================================="
  log_info "Total workloads found: $total_workloads_found"
  log_info "Successfully deleted: $total_workloads_deleted"
  if [[ $total_workloads_retained -gt 0 ]]; then
    log_warn "Retained (30-day retention): $total_workloads_retained"
    log_warn "These will auto-delete after the retention period expires"
  fi

  # Final verification across all regions
  log_info "Verifying remaining workloads across all regions..."
  remaining_count=0
  for region in "${AW_REGIONS[@]}"; do
    remaining=$(gcloud assured workloads list --organization="${ORGANIZATION_ID}" --location="${region}" --format="value(displayName)" 2>/dev/null || echo "")
    if [[ -n "$remaining" ]]; then
      count=$(echo "$remaining" | wc -l)
      remaining_count=$((remaining_count + count))
      log_warn "Region $region still has $count workload(s): $(echo "$remaining" | tr '\n' ', ' | sed 's/,$//')"
    fi
  done

  if [[ $remaining_count -eq 0 ]]; then
    log_info "✓ All Assured Workloads successfully deleted!"
  else
    log_warn "$remaining_count workload(s) remain (likely 30-day folder retention)"
  fi
  echo

  # Remove Assured Workloads folders from terraform state since they can't be deleted (30-day retention)
  if promptUser "Would you like to remove Assured Workloads folders from state (they have 30-day retention and can't be immediately deleted)?"; then
    log_info "Removing Assured Workloads folders from terraform state..."
    terraform state rm 'module.branch-common-services-folder.google_folder.folder[0]' 2>/dev/null || log_warn "Common Services folder not in state"
    terraform state rm 'google_assured_workloads_workload.primary[0]' 2>/dev/null || log_warn "Assured Workloads not in state"
    log_info "These folders will be cleaned up automatically after the 30-day retention period"
  fi

  if promptUser "Would you like to run terraform destroy?"; then
    # Check if we have sufficient permissions for project deletion
    current_account=$(gcloud config list --format 'value(core.account)')
    log_info "Attempting terraform destroy with account: $current_account"

    if ! terraform destroy -var bootstrap_user="$current_account"; then
      log_warn "Terraform destroy failed even with restored permissions, analyzing issues..."

      # Check for specific error patterns and handle them properly
      destroy_output=$(terraform plan -destroy 2>&1 || true)

      # Handle Backend Initialization Required error
      if echo "$destroy_output" | grep -q "Backend initialization required"; then
        log_warn "Backend initialization required - attempting to reconfigure..."
        if terraform init -reconfigure; then
          log_info "Terraform init -reconfigure successful, retrying destroy..."
          if terraform destroy -var bootstrap_user="$current_account"; then
             log_info "Terraform destroy succeeded after reconfigure"
             return 0
          fi
        else
          log_error "Terraform init -reconfigure failed"
        fi
      fi

      # Handle Assured Workloads permission issues
      if echo "$destroy_output" | grep -q "assuredworkloads.*permission.*denied\|assuredworkloads.*403"; then
        log_warn "Detected Assured Workloads permission issue - attempting automatic resolution"

        # Function to handle Assured Workloads deletion automatically
        handle_assured_workloads_deletion() {
          local current_account
          current_account=$(gcloud config list --format 'value(core.account)')
          log_info "Current account: $current_account"

          # Check if user already has Assured Workloads admin role
          if gcloud organizations get-iam-policy "${ORGANIZATION_ID}" --flatten="bindings[].members" --format="table(bindings.role,bindings.members)" | grep -q "roles/assuredworkloads.admin.*$current_account"; then
            log_info "User already has Assured Workloads admin role"
          else
            log_info "Granting Assured Workloads admin role to $current_account"
            if ! gcloud_safe organizations add-iam-policy-binding "${ORGANIZATION_ID}" \
              --member="user:$current_account" \
              --role="roles/assuredworkloads.admin"; then
              log_error "Failed to grant Assured Workloads admin role"
              return 1
            fi

            # Wait for IAM propagation
            log_info "Waiting for IAM propagation..."
            log_info "Waiting 90 seconds for IAM policy changes..."; sleep 90
          fi

          # List and delete Assured Workloads (with proper project cleanup)
          log_info "Listing Assured Workloads in organization ${ORGANIZATION_ID}..."
          local workloads
          workloads=$(gcloud assured workloads list \
            --organization="${ORGANIZATION_ID}" \
            --location="${AW_REGION:-us-east4}" \
            --format="value(name)" 2>/dev/null)

          if [[ -n "$workloads" ]]; then
            log_info "Found Assured Workloads to delete:"
            echo "$workloads"

            for workload in $workloads; do
              log_info "Processing Assured Workload: $workload"

              # First, get all projects in this workload
              local workload_projects
              workload_projects=$(gcloud assured workloads describe "$workload" \
                --location="${AW_REGION:-us-east4}" \
                --format="value(resources[].resourceId)" 2>/dev/null | grep "^projects/" | sed 's|projects/||' || echo "")

              if [[ -n "$workload_projects" ]]; then
                log_info "Found projects in workload that need cleanup:"
                echo "$workload_projects"

                # Delete each project in the workload
                for project in $workload_projects; do
                  log_info "Attempting to delete project $project from workload"

                  # Remove any deletion liens first
                  gcloud_safe alpha resource-manager liens list --project="$project" --format="value(name)" | while read -r lien; do
                    if [[ -n "$lien" ]]; then
                      log_info "Removing lien: $lien"
                      gcloud_safe alpha resource-manager liens delete "$lien" || log_warn "Failed to remove lien $lien"
                    fi
                  done

                  # Disable billing
                  gcloud_safe billing projects unlink "$project" 2>/dev/null || log_warn "No billing to unlink for $project"

                  # Force delete the project
                  if gcloud_safe projects delete "$project"; then
                    log_info "Successfully deleted project $project"
                  else
                    log_warn "Failed to delete project $project - continuing anyway"
                  fi
                done

                # Wait for project deletions to propagate
                log_info "Waiting for project deletions to propagate..."
                log_info "Waiting 60 seconds for project deletions..."; sleep 60
              fi

              # Now try to delete the empty workload with proper timing
              log_info "Attempting to delete Assured Workload: $workload"
              local max_attempts=5
              local attempt=1

              while [[ $attempt -le $max_attempts ]]; do
                log_info "Attempt $attempt/$max_attempts to delete workload $workload"

                if gcloud_safe assured workloads delete "$workload" --location="${AW_REGION:-us-east4}"; then
                  log_info "Successfully deleted Assured Workload: $workload"
                  break
                else
                  log_warn "Attempt $attempt failed - workload may still contain resources"
                  if [[ $attempt -lt $max_attempts ]]; then
                    # Check what resources are still in the workload
                    log_info "Checking workload contents..."
                    local remaining_resources
                    remaining_resources=$(gcloud assured workloads describe "$workload" \
                      --location="${AW_REGION:-us-east4}" \
                      --format="value(resources[].resourceId)" 2>/dev/null || echo "")

                    if [[ -n "$remaining_resources" ]]; then
                      log_info "Workload still contains: $remaining_resources"
                      log_info "Waiting for resources to be fully deleted..."

                      # Poll for resource deletion status
                      local wait_count=0
                      local max_wait=24  # 2 minutes in 5-second intervals
                      while [[ $wait_count -lt $max_wait ]]; do
                        local still_exists=false
                        for resource in $remaining_resources; do
                          if [[ "$resource" =~ ^projects/ ]]; then
                            local project_id=${resource#projects/}
                            if gcloud projects describe "$project_id" >/dev/null 2>&1; then
                              still_exists=true
                              break
                            fi
                          elif [[ "$resource" =~ ^[0-9]+$ ]]; then
                            # Folder ID
                            if gcloud resource-manager folders describe "$resource" >/dev/null 2>&1; then
                              still_exists=true
                              break
                            fi
                          fi
                        done

                        if [[ "$still_exists" == "false" ]]; then
                          log_info "All resources are now deleted"
                          break
                        fi

                        sleep 5
                        ((wait_count++))
                      done
                    fi
                  fi
                fi
                ((attempt++))
              done

              if [[ $attempt -gt $max_attempts ]]; then
                log_error "Failed to delete Assured Workload: $workload after $max_attempts attempts"
                log_error "The workload may still contain resources or have dependencies"
                return 1
              fi
            done

            # Verify workloads are actually deleted
            log_info "Verifying Assured Workloads deletion..."
            local remaining_workloads
            remaining_workloads=$(gcloud assured workloads list \
              --organization="${ORGANIZATION_ID}" \
              --location="${AW_REGION:-us-east4}" \
              --format="value(name)" 2>/dev/null || echo "")

            if [[ -n "$remaining_workloads" ]]; then
              log_warn "Some workloads may still exist: $remaining_workloads"
              log_warn "This may cause issues with terraform destroy"
            else
              log_info "All Assured Workloads successfully deleted"
            fi
          else
            log_info "No Assured Workloads found to delete"
          fi

          return 0
        }

        if handle_assured_workloads_deletion; then
          log_info "Assured Workloads deletion completed successfully"
        else
          log_warn "Automatic Assured Workloads deletion failed - falling back to manual process"
          log_info "Assured Workloads must be deleted through console: https://console.cloud.google.com/assuredworkloads"
          if promptUser "Remove Assured Workloads from terraform state (you'll need to delete manually via console)?"; then
            terraform state rm 'google_assured_workloads_workload.primary[0]' || log_warn "Failed to remove Assured Workloads from state"
          fi
        fi
      fi

      # Handle project permission issues by ensuring proper permissions exist
      if echo "$destroy_output" | grep -q "project.*403\|project.*permission.*denied"; then
        log_warn "Project deletion permission issue detected"
        if promptUser "Would you like to switch to organization admin authentication?"; then
          log_info "Please authenticate with an organization admin account when prompted"
          gcloud auth login
          current_account=$(gcloud config list --format 'value(core.account)')
          log_info "Retrying with admin account: $current_account"
        fi
      fi

      # Retry destroy after handling permission issues
      if ! terraform destroy -var bootstrap_user="$current_account"; then
        log_error "Terraform destroy still failing after permission fixes"
        log_error "This indicates either:"
        log_error "  1. Insufficient organization-level permissions"
        log_error "  2. Resources with deletion protection enabled"
        log_error "  3. Dependencies that need manual cleanup"

        if promptUser "Would you like to force cleanup by removing problematic resources from state?"; then
          # This is a last resort - remove from state so they can be cleaned up manually
          log_warn "Removing problematic resources from terraform state (manual cleanup required)"
          terraform state rm 'google_assured_workloads_workload.primary[0]' 2>/dev/null || true
          terraform state rm 'module.automation-project.google_project.project[0]' 2>/dev/null || true

          log_info "Attempting final terraform destroy of remaining resources..."
          terraform destroy -var bootstrap_user="$current_account" || log_warn "Some resources may require manual cleanup"
        fi
      else
        log_info "Terraform destroy succeeded after permission restoration"
      fi
    else
      log_info "Terraform destroy succeeded with proper permissions"
    fi
  fi

  # Clean up any latent storage buckets that terraform couldn't delete
  if promptUser "Would you like to delete any remaining latent storage buckets?"; then
    log_info "Checking for latent storage buckets..."
    latent_buckets=$(gcloud storage buckets list --format="value(name)" 2>/dev/null | grep -E "^${PREFIX}-prod-iac-core-(resman|outputs|bootstrap)-" | sed 's|^|gs://|' | tr '\n' ' ' || echo "")

    if [[ -n "$latent_buckets" ]]; then
      log_info "Found latent buckets: $latent_buckets"

      for bucket in $latent_buckets; do
        log_info "Removing all objects from bucket: $bucket"
        gcloud_safe storage rm -r "${bucket}/**" 2>/dev/null || log_warn "No objects found in $bucket or removal failed"

        log_info "Removing empty bucket: $bucket"
        bucket_name=${bucket#gs://}
        if ! gcloud_safe storage buckets delete "gs://${bucket_name}"; then
          log_warn "Failed to remove bucket $bucket, continuing..."
        fi
      done
      log_info "Latent bucket cleanup completed"
    else
      log_info "No latent storage buckets found"
    fi
  fi

  # CRITICAL: Delete the automation project (often requires special handling)
  automation_project="${PREFIX}-prod-iac-core-0"
  if promptUser "Would you like to delete the automation project (${automation_project})?"; then
    log_info "Checking if automation project ${automation_project} exists..."

    if gcloud projects describe "${automation_project}" >/dev/null 2>&1; then
      log_info "Automation project ${automation_project} exists, preparing for deletion..."

      # Remove all deletion blockers systematically
      log_info "Step 1: Removing project liens..."
      liens=$(gcloud_safe alpha resource-manager liens list --project="${automation_project}" --format="value(name)" 2>/dev/null || echo "")
      if [[ -n "$liens" ]]; then
        while IFS= read -r lien; do
          if [[ -n "$lien" ]]; then
            log_info "  Removing lien: $lien"
            gcloud_safe alpha resource-manager liens delete "$lien" || log_warn "Failed to remove lien $lien"
          fi
        done <<< "$liens"
      else
        log_info "  No liens found"
      fi

      # Unlink billing
      log_info "Step 2: Unlinking billing account..."
      if gcloud_safe billing projects unlink "${automation_project}" 2>/dev/null; then
        log_info "  Billing unlinked successfully"
      else
        log_info "  No billing to unlink or already unlinked"
      fi

      # Disable problematic APIs
      log_info "Step 3: Disabling APIs that might block deletion..."
      apis_to_disable=("cloudresourcemanager.googleapis.com" "serviceusage.googleapis.com")
      for api in "${apis_to_disable[@]}"; do
        gcloud_safe services disable "$api" --project="${automation_project}" --force 2>/dev/null || log_info "  $api not enabled or already disabled"
      done

      # Wait for changes to propagate
      log_info "Step 4: Waiting 30 seconds for changes to propagate..."
      sleep 30

      # Attempt deletion
      log_info "Step 5: Attempting to delete project ${automation_project}..."
      if gcloud_safe projects delete "${automation_project}" --quiet; then
        log_info "Successfully deleted automation project ${automation_project}"
      else
        log_error "Failed to delete automation project ${automation_project}"
        log_error "This may require manual deletion or additional permissions"
        log_error "To delete manually, run: gcloud projects delete ${automation_project}"
        log_error "You may need to grant additional roles at: https://console.cloud.google.com/iam-admin/iam?organizationId=${ORGANIZATION_ID}"
      fi
    else
      log_info "Automation project ${automation_project} does not exist or was already deleted"
    fi
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

  if promptUser "Would you like to delete your .terraform dir and related files?"; then
    # Comprehensive terraform cleanup for stage 0
    if [[ -d ".terraform" ]]; then
      rm -rf .terraform
      log_info "Deleted .terraform directory"
    else
      log_warn ".terraform directory does not exist"
    fi

    # Remove terraform lock file
    if [[ -f ".terraform.lock.hcl" ]]; then
      rm -f .terraform.lock.hcl
      log_info "Deleted .terraform.lock.hcl"
    else
      log_warn ".terraform.lock.hcl does not exist"
    fi

    # Remove any backup state files
    if [[ -f "terraform.tfstate.backup" ]]; then
      rm -f terraform.tfstate.backup
      log_info "Deleted terraform.tfstate.backup"
    fi
  fi

  if promptUser "Would you like to delete your local .tfstate file?"; then
    if [[ -f "terraform.tfstate" ]]; then
      rm -f terraform.tfstate
      log_info "Deleted terraform.tfstate"
    else
      log_warn "terraform.tfstate does not exist"
    fi
  fi
fi

########### Final Cleanup - Orphaned Resources ############
echo -e "\n#######################################################"
echo "#######################################################"
echo "#######################################################"

if promptUser "Would you like to check for and clean up any orphaned resources?"; then
  log_info "Scanning for orphaned projects and folders..."

  # Check for orphaned projects in known folders
  orphaned_projects=$(gcloud projects list --filter="parent.id:${AW_FOLDER_ID:-} OR parent.id:${COMMON_SERVICES_FOLDER_ID:-} OR name~'${PREFIX}-'" --format="value(projectId)" 2>/dev/null | grep "^${PREFIX}-" || echo "")

  if [[ -n "$orphaned_projects" ]]; then
    log_warn "Found orphaned projects: $orphaned_projects"
    if promptUser "Would you like to delete these orphaned projects?"; then

      for project in $orphaned_projects; do
        log_info "Deleting orphaned project: $project"

        # Systematic approach to remove all blockers before deletion
        log_info "Checking for and removing project deletion blockers..."

        # 1. Check for liens (common blocker)
        project_number=$(gcloud projects describe "$project" --format="value(projectNumber)" 2>/dev/null || echo "")
        if [[ -n "$project_number" ]]; then
          liens=$(gcloud alpha resource-manager liens list --project="$project_number" --format="value(name)" 2>/dev/null || echo "")
          if [[ -n "$liens" ]]; then
            log_warn "Found project liens blocking deletion: $liens"
            for lien in $liens; do
              log_info "Removing lien: $lien"
              gcloud_safe alpha resource-manager liens delete "$lien" || log_warn "Failed to remove lien $lien"
            done
          fi
        fi

        # 2. Unlink billing (common blocker)
        log_info "Unlinking billing account from project $project"
        gcloud_safe billing projects unlink "$project" || log_warn "Failed to unlink billing or already unlinked"

        # 3. Disable APIs that might have dependencies
        log_info "Disabling problematic APIs that might block deletion"
        apis_to_disable=("compute.googleapis.com" "container.googleapis.com" "sql.googleapis.com" "cloudfunctions.googleapis.com")
        for api in "${apis_to_disable[@]}"; do
          gcloud_safe services disable "$api" --project="$project" --force || log_warn "Failed to disable $api or not enabled"
        done

        # 4. Remove IAM policies that might have external dependencies
        log_info "Clearing project IAM policies"
        gcloud_safe projects set-iam-policy "$project" <(echo '{"bindings":[]}') || log_warn "Failed to clear IAM policies"

        # 5. Wait for changes to propagate
        log_info "Waiting for deletion blockers removal to propagate..."
        sleep 30

        # 6. Try deletion
        if ! gcloud_safe projects delete "$project" --quiet; then
          log_error "Project $project still cannot be deleted after removing blockers"

          # Advanced debugging
          log_info "Performing advanced diagnostics for project $project..."

          # Check project state
          project_state=$(gcloud projects describe "$project" --format="value(lifecycleState)" 2>/dev/null || echo "UNKNOWN")
          log_info "Project lifecycle state: $project_state"

          # Check for organization policies blocking deletion
          org_policies=$(gcloud resource-manager org-policies list --organization="${ORGANIZATION_ID}" --filter="displayName~delete" --format="value(displayName)" 2>/dev/null || echo "")
          if [[ -n "$org_policies" ]]; then
            log_warn "Organization policies that might block deletion: $org_policies"
          fi

          # Last resort: try force delete with specific flags
          log_info "Attempting force deletion with additional flags..."
          if ! gcloud_safe projects delete "$project" --quiet --verbosity=debug; then
            log_error "Force deletion failed for project $project"
            log_error "This project may require manual intervention or have Assured Workloads protection"

            # Extract project creation info for debugging
            creation_time=$(gcloud projects describe "$project" --format="value(createTime)" 2>/dev/null || echo "Unknown")
            log_info "Project creation time: $creation_time"

            # Check if part of Assured Workloads and handle automatically
            if gcloud assured workloads list --organization="${ORGANIZATION_ID}" --location="${AW_REGION:-us-east4}" 2>/dev/null | grep -q "$project"; then
              log_warn "Project $project is part of Assured Workloads - attempting automatic cleanup"

                        # Find the specific workload containing this project
                        containing_workload=$(gcloud assured workloads list \
                          --organization="${ORGANIZATION_ID}" \                --location="${AW_REGION:-us-east4}" \
                --format="table(name)" --filter="resources.resourceId:projects/$project" \
                --format="value(name)" 2>/dev/null | head -1)

              if [[ -n "$containing_workload" ]]; then
                log_info "Found workload containing project: $containing_workload"

                            # Grant Assured Workloads admin if needed
                            current_account=$(gcloud config list --format 'value(core.account)')
                            if ! gcloud organizations get-iam-policy "${ORGANIZATION_ID}" --flatten="bindings[].members" --format="table(bindings.role,bindings.members)" | grep -q "roles/assuredworkloads.admin.*$current_account"; then                  log_info "Granting Assured Workloads admin role to $current_account"
                  gcloud_safe organizations add-iam-policy-binding "${ORGANIZATION_ID}" \
                    --member="user:$current_account" \
                    --role="roles/assuredworkloads.admin"
                  sleep 30
                fi

                # Try to delete the entire workload (which should delete projects)
                log_info "Attempting to delete workload $containing_workload (which will delete project $project)"
                if gcloud_safe assured workloads delete "$containing_workload" --location="${AW_REGION:-us-east4}"; then
                  log_info "Successfully deleted workload and project via Assured Workloads"
                else
                  log_error "Failed to delete workload automatically"
                  log_error "Go to: https://console.cloud.google.com/assuredworkloads and delete the workload manually"
                fi
              else
                log_error "Could not identify specific workload containing project $project"
                log_error "Go to: https://console.cloud.google.com/assuredworkloads and delete the workload manually"
              fi
            fi
          else
            log_info "Force deletion succeeded for project $project"
          fi
        else
          log_info "Successfully deleted project $project"
        fi
      done
    fi
  else
    log_info "No orphaned projects found"
  fi

  # Check for empty folders to clean up
  if [[ -n "${COMMON_SERVICES_FOLDER_ID:-}" ]]; then
    if promptUser "Would you like to delete the Common Services folder (${COMMON_SERVICES_FOLDER_ID})?"; then
      if ! gcloud_safe resource-manager folders delete "${COMMON_SERVICES_FOLDER_ID}"; then
        log_warn "Failed to delete Common Services folder - it may still contain resources"
      fi
    fi
  fi

  if [[ -n "${AW_FOLDER_ID:-}" ]]; then
    if promptUser "Would you like to delete the main Assured Workloads folder (${AW_FOLDER_ID})?"; then
      if ! gcloud_safe resource-manager folders delete "${AW_FOLDER_ID}"; then
        log_warn "Failed to delete main folder - it may still contain resources or be managed by Assured Workloads"
      fi
    fi
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
