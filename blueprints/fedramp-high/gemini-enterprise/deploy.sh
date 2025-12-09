#!/bin/bash
set -e

# Ensure gem4gov can be found in the python path
export PYTHONPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/gem4gov-cli:$PYTHONPATH"

# --- Global Configuration ---
# These variables are used across multiple functions
PROJECT_ID=""
ORG_ID=""
PREFIX=""
REGION=""
DOMAIN=""
DEPLOYMENT_CHOICE=""
IS_BROWNFIELD="false"
IS_CUSTOM="false"
BUCKET_NAME=""
STATE_BUCKET=""
TENANT_IAC_PROJECT=""
DEFAULT_CMEK_KEY=""
KMS_KEY_ID=""
SKIP_PROMPTS="false"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Helper Functions ---

get_tfvar_value() {
    local file="$1"
    local key="$2"
    if [[ -f "$file" ]]; then
        grep "^${key}\s*=" "$file" | head -n 1 | cut -d'=' -f2- | tr -d ' "'
    fi
}

print_header() {
    echo -e "${GREEN}============================================================${NC}"
    echo -e "${GREEN}   Gemini Enterprise FedRAMP High Blueprint Manager         ${NC}"
    echo -e "${GREEN}============================================================${NC}"
    echo ""
}

pause() {
    read -p "Press Enter to continue..."
}

check_dependencies() {
    local missing=0
    for cmd in gcloud terraform pip3 python3 jq; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${RED}Error: Required command '$cmd' not found.${NC}"
            missing=1
        fi
    done
    if [[ $missing -eq 1 ]]; then
        echo "Please install missing dependencies and try again."
        exit 1
    fi
}

configure_data_stores() {
    # Expects GCS_LIST and BQ_LIST to be defined arrays in the calling scope
    while true; do
        echo ""
        echo -e "${BLUE}--- Data Store Configuration ---${NC}"
        echo "1. Add Google Cloud Storage (GCS) Data Store"
        echo "2. Add BigQuery (BQ) Data Store"
        echo "3. Done"
        read -p "Select an option [1-3]: " DS_MENU_SEL
        
        case $DS_MENU_SEL in
            1)
                read -p "Enter Bucket Name (e.g., company-docs): " GCS_NAME
                if [[ -n "$GCS_NAME" ]]; then
                    GCS_LIST+=("\"$GCS_NAME\"")
                    echo -e "${GREEN}Added GCS Bucket: ${GCS_NAME}${NC}"
                else
                    echo -e "${RED}Invalid Bucket Name.${NC}"
                fi
                ;;
            2)
                read -p "Enter Dataset ID (must contain only letters (a-z, A-Z), numbers (0-9), or underscores (_)): " BQ_DATASET
                read -p "Enter Table ID: " BQ_TABLE
                if [[ -n "$BQ_DATASET" && -n "$BQ_TABLE" ]]; then
                    BQ_LIST+=("{dataset_id = \"$BQ_DATASET\", table_id = \"$BQ_TABLE\"}")
                    echo -e "${GREEN}Added BigQuery Table: ${BQ_DATASET}.${BQ_TABLE}${NC}"
                else
                    echo -e "${RED}Invalid Dataset or Table ID.${NC}"
                fi
                ;;
            3)
                break
                ;;
            *)
                echo "Invalid option."
                ;;
        esac
    done
}

# --- Authentication & Setup ---

auth_and_project_setup() {
    echo -e "${BLUE}--- Authentication & Project Selection ---${NC}"
    
    # 1. Google Account Check
    CURRENT_ACCOUNT=$(gcloud config get-value account 2>/dev/null)
    echo -e "Current Google Account: ${YELLOW}${CURRENT_ACCOUNT}${NC}"
    read -p "Is this the correct account? (y/N): " CONFIRM_ACCOUNT
    if [[ "$CONFIRM_ACCOUNT" != "y" && "$CONFIRM_ACCOUNT" != "Y" ]]; then
        echo "Starting authentication flow..."
        gcloud auth login
        CURRENT_ACCOUNT=$(gcloud config get-value account 2>/dev/null)
        echo -e "Now authenticated as: ${YELLOW}${CURRENT_ACCOUNT}${NC}"
    fi

    # 2. ADC Check
    echo "Checking Application Default Credentials (ADC)..."
    if gcloud auth application-default print-access-token &>/dev/null; then
        echo -e "${GREEN}ADC is configured.${NC}"
    else
        echo -e "${YELLOW}Application Default Credentials not found.${NC}"
        read -p "Do you want to authenticate ADC now? (y/N): " DO_AUTH
        if [[ "$DO_AUTH" == "y" || "$DO_AUTH" == "Y" ]]; then
            gcloud auth application-default login
        else
            echo "Warning: Proceeding without ADC. Terraform might fail."
        fi
    fi

    # 3. Project ID Selection
    CURRENT_PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    if [[ -n "$CURRENT_PROJECT_ID" ]]; then
        echo -e "Current Project ID: ${YELLOW}${CURRENT_PROJECT_ID}${NC}"
        read -p "Is this the correct Project ID for Gemini Enterprise? (y/N): " CONFIRM_PROJECT
        if [[ "$CONFIRM_PROJECT" == "y" || "$CONFIRM_PROJECT" == "Y" ]]; then
            PROJECT_ID=$CURRENT_PROJECT_ID
        else
            read -p "Enter the Google Cloud Project ID: " PROJECT_ID
            if [[ -n "$PROJECT_ID" ]]; then
                gcloud config set project "${PROJECT_ID}"
            fi
        fi
    fi

    if [[ -z "$PROJECT_ID" ]]; then
        read -p "Enter the Google Cloud Project ID: " PROJECT_ID
        if [[ -n "$PROJECT_ID" ]]; then
            gcloud config set project "${PROJECT_ID}"
        fi
    fi

    if [[ -z "$PROJECT_ID" ]]; then
        echo -e "${RED}Project ID is required.${NC}"
        return 1
    fi

    # Set billing quota project
    echo "Setting billing quota project..."
    gcloud config set billing/quota_project "${PROJECT_ID}"

    # Discover Org ID
    echo "Discovering Organization ID..."
    ORG_ID=$(gcloud projects get-ancestors "${PROJECT_ID}" --format="value(id)" | tail -n 1)
    echo -e "Found Organization ID: ${YELLOW}${ORG_ID}${NC}"

    # Discover Domain
    echo "Discovering Organization Domain..."
    ORG_DOMAIN=$(gcloud organizations list --filter="name:organizations/${ORG_ID}" --format="value(displayName)" 2>/dev/null)
    if [[ -n "$ORG_DOMAIN" ]]; then
        DOMAIN="${ORG_DOMAIN}"
        echo -e "Found Organization Domain: ${YELLOW}${DOMAIN}${NC}"
    else
        echo -e "${YELLOW}Warning: Could not auto-discover Organization Domain.${NC}"
    fi
    
    return 0
}

enable_apis() {
    echo -e "${BLUE}--- Enabling Required APIs ---${NC}"
    echo "Enabling: Assured Workloads, Access Context Manager, Org Policy, KMS, Storage, IAM, Service Usage..."
    if ! gcloud services enable \
        assuredworkloads.googleapis.com \
        accesscontextmanager.googleapis.com \
        compute.googleapis.com \
        orgpolicy.googleapis.com \
        cloudkms.googleapis.com \
        storage.googleapis.com \
        iam.googleapis.com \
        cloudresourcemanager.googleapis.com \
        serviceusage.googleapis.com \
        --project "${PROJECT_ID}"; then
        echo -e "${RED}Error: Failed to enable required APIs. Check your permissions.${NC}"
        return 1
    fi
    echo -e "${GREEN}APIs enabled successfully.${NC}"
    return 0
}

# --- Deployment Configuration ---

select_deployment_type() {
    echo -e "${BLUE}--- Deployment Type Selection ---${NC}"
    echo "1. Brownfield (Stellar Engine Integration)"
    echo "2. Greenfield (New GCP Project Deployment)"
    echo "3. Custom Brownfield (Manual Configuration)"
    read -p "Select an option [1-3]: " DEPLOYMENT_CHOICE

    if [[ ! "$DEPLOYMENT_CHOICE" =~ ^[1-3]$ ]]; then
        echo -e "${RED}Invalid selection.${NC}"
        return 1
    fi

    if [[ "$DEPLOYMENT_CHOICE" == "1" ]]; then # Brownfield
        DEPLOYMENT_TYPE_TEXT="Brownfield (Stellar Engine Integration)"
        IS_BROWNFIELD="true"
        IS_CUSTOM="false"
        PREFIX=$(echo "$PROJECT_ID" | cut -d'-' -f1 | cut -d'-' -f1-6)
        echo -e "Derived Prefix: ${YELLOW}${PREFIX}${NC}"
    elif [[ "$DEPLOYMENT_CHOICE" == "2" ]]; then # Greenfield
        DEPLOYMENT_TYPE_TEXT="Greenfield (New GCP Project Deployment)"
        IS_BROWNFIELD="false"
        IS_CUSTOM="false"
        read -p "Enter a prefix for your resources: " PREFIX
    elif [[ "$DEPLOYMENT_CHOICE" == "3" ]]; then # Custom Brownfield
        DEPLOYMENT_TYPE_TEXT="Custom Brownfield (Manual Configuration)"
        IS_BROWNFIELD="false"
        IS_CUSTOM="true"
        read -p "Enter a prefix for your resources (default: sedev): " INPUT_PREFIX
        PREFIX=${INPUT_PREFIX:-"sedev"}
    fi
    
    echo -e "Using Prefix: ${YELLOW}${PREFIX}${NC}"
    return 0
}

discover_brownfield_resources() {
    if [[ "$IS_BROWNFIELD" == "true" ]]; then
        echo -e "${BLUE}--- Brownfield Discovery ---${NC}"
        
        # 1. Derive iac-core-0 project
        BASE_NAME=$(echo "$PROJECT_ID" | sed 's/-main-0$//')
        TENANT_IAC_PROJECT="${BASE_NAME}-iac-core-0"
        
        if ! gcloud projects describe "${TENANT_IAC_PROJECT}" &>/dev/null; then
            echo -e "${YELLOW}Warning: Tenant IaC Core Project '${TENANT_IAC_PROJECT}' not found.${NC}"
            read -p "Please enter the Tenant IaC Core Project ID: " INPUT_IAC_PROJECT
            TENANT_IAC_PROJECT="${INPUT_IAC_PROJECT}"
        fi
        
        if [[ -z "$TENANT_IAC_PROJECT" ]]; then
             echo -e "${RED}Error: Tenant IaC Core Project ID is required.${NC}"
             return 1
        fi
        echo -e "Found Tenant IaC Project: ${YELLOW}${TENANT_IAC_PROJECT}${NC}"

        # 2. Discover State Bucket
        echo "Looking for state bucket in ${TENANT_IAC_PROJECT}..."
        TENANT_BUCKETS=$(gcloud storage ls --project "${TENANT_IAC_PROJECT}" 2>/dev/null)
        STATE_BUCKET=$(echo "$TENANT_BUCKETS" | grep "iac-0/$" | head -n 1)
        
        if [[ -z "$STATE_BUCKET" ]]; then
            echo -e "${YELLOW}Warning: No Terraform state bucket found.${NC}"
            read -p "Please enter the State Bucket Name (e.g., gs://my-bucket): " INPUT_BUCKET
            STATE_BUCKET="${INPUT_BUCKET}"
        fi
        
        if [[ -z "$STATE_BUCKET" ]]; then
            echo -e "${RED}Error: State Bucket is required.${NC}"
            return 1
        fi
        
        BUCKET_NAME=$(echo "$STATE_BUCKET" | sed 's/gs:\/\///' | sed 's/\/$//')
        echo -e "Using Tenant State Bucket: ${YELLOW}${BUCKET_NAME}${NC}"
        
        # 3. Discover CMEK
        # We need a region first to look for keys
        REGION=$(gcloud config get-value compute/region 2>/dev/null)
        REGION=${REGION:-"us-east4"}
        
        echo "Looking for default CMEK key..."

        # 3a. Check for existing US Multi-Region Key (Gemini Enterprise specific)
        # This key is created by Stage 0 if Geolocation is "us". We prioritize it for Discovery Engine compatibility.
        US_KEY_NAME="gemini-enterprise-us-key"
        US_KEYRING_NAME="gemini-enterprise-us-keyring"
        echo "Checking for existing US multi-region key in ${PROJECT_ID}..."
        US_KEY_ID=$(gcloud kms keys describe "${US_KEY_NAME}" --keyring "${US_KEYRING_NAME}" --location "us" --project "${PROJECT_ID}" --format="value(name)" 2>/dev/null)

        if [[ -n "$US_KEY_ID" ]]; then
             echo -e "Found US Multi-Region Key: ${YELLOW}${US_KEY_ID}${NC}"
             DEFAULT_CMEK_KEY="${US_KEY_ID}"
        else
             # 3b. Fallback: Look for default CMEK key in Tenant IaC Project (Regional)
             echo "Looking for default CMEK key in ${TENANT_IAC_PROJECT} (Location: ${REGION})..."
             KEYRINGS=$(gcloud kms keyrings list --location "${REGION}" --project "${TENANT_IAC_PROJECT}" --format="value(name)" 2>/dev/null)
             
             for keyring_path in $KEYRINGS; do
                 keyring_name=$(basename "$keyring_path")
                 KEY=$(gcloud kms keys describe "default" --keyring "$keyring_name" --location "${REGION}" --project "${TENANT_IAC_PROJECT}" --format="value(name)" 2>/dev/null)
                 if [[ -n "$KEY" ]]; then
                     DEFAULT_CMEK_KEY=$KEY
                     break
                 fi
             done
        fi
        
        if [[ -n "$DEFAULT_CMEK_KEY" ]]; then
            echo -e "Found Default CMEK Key: ${YELLOW}${DEFAULT_CMEK_KEY}${NC}"
            KMS_KEY_ID="${DEFAULT_CMEK_KEY}"
            
            if [[ "$KMS_KEY_ID" == *"/locations/us/"* ]]; then
                echo -e "${GREEN}Success: Using US Multi-Region Key.${NC}"
            else
                echo -e "${YELLOW}Note: Using Regional Key (not US multi-region).${NC}"
            fi
            read -p "Press Enter to confirm key selection and continue..."
        else
            echo -e "${YELLOW}Warning: Could not find default CMEK key.${NC}"
        fi
        
    elif [[ "$IS_CUSTOM" == "true" ]]; then
        echo -e "${BLUE}--- Custom Brownfield Configuration ---${NC}"
        
        # Try to read from tfvars first
        TFVARS_FILE="gemini-stage-0/terraform.tfvars"
        if [[ -f "$TFVARS_FILE" ]]; then
            STATE_BUCKET=$(get_tfvar_value "$TFVARS_FILE" "bucket")
            KMS_KEY_ID=$(get_tfvar_value "$TFVARS_FILE" "kms_key_id")
        fi
        
        if [[ -z "$STATE_BUCKET" ]]; then
            read -p "Enter your Terraform State Bucket Name: " STATE_BUCKET
        fi
        BUCKET_NAME=$(echo "$STATE_BUCKET" | sed 's/gs:\/\///' | sed 's/\/$//')
        
        if [[ -z "$BUCKET_NAME" ]]; then
             echo -e "${RED}Error: State Bucket is required.${NC}"
             return 1
        fi
        echo -e "Using State Bucket: ${YELLOW}${BUCKET_NAME}${NC}"
        
        # Validate CMEK on bucket
        BUCKET_KEY=$(gcloud storage buckets describe "gs://${BUCKET_NAME}" --format="value(encryption.defaultKmsKeyName)" 2>/dev/null || true)
        if [[ -z "$BUCKET_KEY" ]]; then
             echo -e "${RED}ERROR: State Bucket is NOT encrypted with CMEK.${NC}"
             return 1
        fi
        
        if [[ -z "$KMS_KEY_ID" ]]; then
             KMS_KEY_ID="$BUCKET_KEY"
        fi
        echo -e "Using Resource CMEK Key: ${YELLOW}${KMS_KEY_ID}${NC}"
        
    else
        # Greenfield
        if [[ -n "$PREFIX" && -n "$PROJECT_ID" ]]; then
            BUCKET_NAME="${PREFIX}-gemini-enterprise-tf-state-${PROJECT_ID}"
            echo -e "State Bucket will be: ${YELLOW}${BUCKET_NAME}${NC}"
        fi
    fi
    return 0
}

# --- Stage 0 Functions ---

check_org_policies() {
    echo "Checking Organization Policies..."
    local failed=0

    # 1. compute.disableInternetNetworkEndpointGroup
    echo -n "Checking compute.disableInternetNetworkEndpointGroup... "
    POLICY_JSON=$(gcloud org-policies describe compute.disableInternetNetworkEndpointGroup --project="${PROJECT_ID}" --effective --format="json" 2>/dev/null || true)
    
    if [[ -z "$POLICY_JSON" ]]; then
        echo -e "${YELLOW}Unable to verify (Check Manually)${NC}"
    else
        # Check both v1 (booleanPolicy) and v2 (spec.rules) formats
        # If any rule enforces it, we consider it enforced.
        IS_ENFORCED=$(echo "$POLICY_JSON" | jq -r '(.booleanPolicy.enforced == true) or (try (.spec.rules[] | .enforce == true) catch false)' 2>/dev/null | grep "true" || true)
        
        if [[ -n "$IS_ENFORCED" ]]; then
            echo -e "${RED}Enforced (FAIL) - Internet NEGs are disabled${NC}"
            failed=1
        else
            echo -e "${GREEN}Disabled (OK)${NC}"
        fi
    fi

    # 2. compute.restrictLoadBalancerCreationForTypes (Only if External)
    if [[ "$DEPLOYMENT_TYPE" == "external" ]]; then
        echo -n "Checking compute.restrictLoadBalancerCreationForTypes... "
        POLICY_JSON=$(gcloud org-policies describe compute.restrictLoadBalancerCreationForTypes --project="${PROJECT_ID}" --effective --format="json" 2>/dev/null || true)
        
        if [[ -z "$POLICY_JSON" ]]; then
            echo -e "${YELLOW}Unable to verify (Check Manually)${NC}"
        else
            # Extract v1 and v2 values
            ALL_VALUES=$(echo "$POLICY_JSON" | jq -r '.listPolicy.allValues // "Unspecified"' 2>/dev/null || echo "Error")
            V2_ALLOW_ALL=$(echo "$POLICY_JSON" | jq -r 'try (.spec.rules[] | select(.allowAll == true) | "true") catch empty' 2>/dev/null | head -n1)
            V2_DENY_ALL=$(echo "$POLICY_JSON" | jq -r 'try (.spec.rules[] | select(.denyAll == true) | "true") catch empty' 2>/dev/null | head -n1)
            
            HAS_ALLOWED_VALUES=$(echo "$POLICY_JSON" | jq -r 'if (.listPolicy? | has("allowedValues")) or (try any(.spec.rules[]?; .values? | has("allowedValues")) catch false) then "true" else "false" end' 2>/dev/null)
            
            ALLOWED_VALUES=$(echo "$POLICY_JSON" | jq -r '.listPolicy.allowedValues[]?, .spec.rules[].values.allowedValues[]?' 2>/dev/null || true)
            DENIED_VALUES=$(echo "$POLICY_JSON" | jq -r '.listPolicy.deniedValues[]?, .spec.rules[].values.deniedValues[]?' 2>/dev/null || true)
            
            if [[ "$ALL_VALUES" == "Error" ]]; then
                 echo -e "${YELLOW}Error parsing policy (Check Manually)${NC}"
            elif [[ "$ALL_VALUES" == "ALLOW" || "$V2_ALLOW_ALL" == "true" ]]; then
                 echo -e "${GREEN}Allowed (OK)${NC}"
            elif [[ "$ALL_VALUES" == "DENY" || "$V2_DENY_ALL" == "true" ]]; then
                 echo -e "${RED}Denied (FAIL) - Policy Enforces DENY ALL${NC}"
                 failed=1
            else
                 # Check allowed/denied lists
                 IS_ALLOWED="true" # Default to true if not explicitly restricted
                 
                 # If allowed_values is present (key exists), we MUST be in it
                 if [[ "$HAS_ALLOWED_VALUES" == "true" ]]; then
                     IS_ALLOWED="false"
                     if [[ -n "$ALLOWED_VALUES" ]]; then
                         if echo "$ALLOWED_VALUES" | grep -qE "EXTERNAL_HTTP_HTTPS|EXTERNAL_MANAGED_HTTP_HTTPS"; then
                             IS_ALLOWED="true"
                         fi
                     fi
                 fi
                 
                 # If denied_values is present, we MUST NOT be in it
                 if [[ -n "$DENIED_VALUES" ]]; then
                     if echo "$DENIED_VALUES" | grep -qE "EXTERNAL_HTTP_HTTPS|EXTERNAL_MANAGED_HTTP_HTTPS"; then
                         IS_ALLOWED="false"
                     fi
                 fi
                 
                 if [[ "$IS_ALLOWED" == "true" ]]; then
                     echo -e "${GREEN}Allowed (OK)${NC}"
                 else
                     echo -e "${RED}Denied (FAIL) - Policy restricts External Load Balancers${NC}"
                     failed=1
                 fi
            fi
        fi
    fi

    if [[ "$failed" -eq 1 ]]; then
        echo -e "${YELLOW}WARNING: One or more Organization Policies may prevent deployment.${NC}"
        read -p "Do you want to proceed anyway? (y/N): " PROCEED
        if [[ "$PROCEED" != "y" && "$PROCEED" != "Y" ]]; then
            return 1
        fi
    fi
    return 0
}

configure_stage_0() {
    echo -e "${BLUE}--- Configure Stage 0 (Infrastructure) ---${NC}"
    mkdir -p gemini-stage-0
    
    # Check if we can reuse existing config
    if [[ -f "gemini-stage-0/terraform.tfvars" ]]; then
        echo -e "${YELLOW}Found existing configuration.${NC}"
        read -p "Reuse existing configuration? (Y/n): " REUSE_CONFIG
        if [[ "$REUSE_CONFIG" != "n" && "$REUSE_CONFIG" != "N" ]]; then
            echo "Using existing configuration."
            return 0
        fi
    fi

    # 1. Assured Workloads Check
    read -p "Is this project deployed in a FedRAMP High Assured Workloads folder? (y/N): " IS_ASSURED
    if [[ "$IS_ASSURED" == "y" || "$IS_ASSURED" == "Y" ]]; then
        read -p "Enter the region (e.g., us-east4): " WORKLOAD_REGION
        if [[ -n "$WORKLOAD_REGION" ]]; then
            echo "Fetching FedRAMP High Assured Workload folders in ${WORKLOAD_REGION}..."
            WORKLOAD_NAME=$(gcloud assured workloads list --location="${WORKLOAD_REGION}" --organization="${ORG_ID}" --filter="complianceRegime=FEDRAMP_HIGH" --format="value(displayName)" 2>/dev/null | head -n 1)
            
            if [[ -z "$WORKLOAD_NAME" ]]; then
                echo -e "${RED}Error: Could not find FedRAMP High Assured Workload folder in ${WORKLOAD_REGION}.${NC}"
                return 1
            fi

            echo ""
            echo -e "${YELLOW}ACTION REQUIRED: Please update your Assured Workload environment manually.${NC}"
            echo -e "1. Navigate to the following URL in your browser:"
            echo -e "${BLUE}https://console.cloud.google.com/compliance/assuredworkloads?organizationId=${ORG_ID}${NC}"
            echo -e "2. Click on the FedRAMP High Assured Workload named: ${GREEN}${WORKLOAD_NAME}${NC}"
            echo -e "3. Click on the button to ${GREEN}\"Review available updates\"${NC} and apply them."
            echo ""
            read -p "Press Enter after you have confirmed the updates have been made..."
            echo -e "${GREEN}Assured Workload folder ${WORKLOAD_NAME} validated / updated${NC}"
            echo ""
        fi
    fi

    # 2. Shared VPC
    USE_SHARED_VPC="false"
    SHARED_VPC_HOST_PROJECT=""
    SHARED_VPC_NETWORK=""
    SHARED_VPC_SUBNET=""
    SHARED_VPC_PROXY_SUBNET=""
    
    read -p "Do you want to use an existing Shared VPC? (y/n) [n]: " USE_SHARED_VPC_CHOICE
    if [[ "$USE_SHARED_VPC_CHOICE" == "y" || "$USE_SHARED_VPC_CHOICE" == "Y" ]]; then
        USE_SHARED_VPC="true"
        
        # 1. Determine Host Project & Verify Attachment
        SHARED_VPC_HOST_PROJECT=$(gcloud compute shared-vpc get-host-project "${PROJECT_ID}" --format="value(name)" 2>/dev/null || true)

        # If not attached, fail and advise user
        if [[ -z "$SHARED_VPC_HOST_PROJECT" ]]; then
            POTENTIAL_HOST_PROJECT=$(echo "$PROJECT_ID" | cut -d'-' -f1-2 | sed 's/$/-net-host/')
            
            echo -e "${RED}ERROR: Project '${PROJECT_ID}' is not attached to a Shared VPC Host.${NC}"
            echo -e "${YELLOW}To proceed, you must:${NC}"
            echo -e "1. Attach this project to the Shared VPC Host Project."
            echo -e "   (Command: gcloud compute shared-vpc associated-projects add ${PROJECT_ID} --host-project ${POTENTIAL_HOST_PROJECT})"
            echo -e "2. Share the VPC Host Project subnets with this Service Project."
            echo -e "${YELLOW}Please configure this and rerun deploy.sh.${NC}"
            return 1
        fi
        
        echo -e "Using Shared VPC: ${GREEN}Yes${NC}"
        echo -e "Using Network Host Project: ${YELLOW}${SHARED_VPC_HOST_PROJECT}${NC}"

        # 2. Auto-discover Network and Subnets
        if [[ -z "$SHARED_VPC_NETWORK" ]]; then
            echo "Scanning for subnets shared from ${SHARED_VPC_HOST_PROJECT} to ${PROJECT_ID}..."
            
            # Get all subnets from the Host Project directly in JSON format
            USABLE_SUBNETS_JSON=$(gcloud compute networks subnets list --project "${SHARED_VPC_HOST_PROJECT}" --format="json" 2>/dev/null)
            
            if [[ -z "$USABLE_SUBNETS_JSON" || "$USABLE_SUBNETS_JSON" == "[]" ]]; then
                 echo -e "${RED}ERROR: No subnets found in Host Project '${SHARED_VPC_HOST_PROJECT}' or permission denied.${NC}"
                 echo -e "${YELLOW}Please ensure that:${NC}"
                 echo -e "1. The Host Project exists and you have permissions to list subnets."
                 echo -e "2. You have shared the necessary subnets with this Service Project."
                 echo -e "3. You are authenticated correctly."
                 return 1
            fi

            # 1. Discover Private Subnet & Network (Atomic operation to ensure consistency)
            # We pick the first usable PRIVATE subnet in the Host Project AND in the correct Region (defaulting to us-east4 if not set)
            DISCOVERY_REGION=$(gcloud config get-value compute/region 2>/dev/null)
            DISCOVERY_REGION=${DISCOVERY_REGION:-"us-east4"}
            
            # We also normalize 'selfLink' to 'subnetwork' to handle both 'list-usable' and 'list' output formats
            FIRST_USABLE_SUBNET_JSON=$(echo "$USABLE_SUBNETS_JSON" | jq -r ".[] | .subnetwork = (.subnetwork // .selfLink) | select(.network | contains(\"projects/${SHARED_VPC_HOST_PROJECT}/\")) | select(.subnetwork | contains(\"/${DISCOVERY_REGION}/\")) | select(.purpose == \"PRIVATE\" or .purpose == null) | {network: .network, subnetwork: .subnetwork} | tojson" | head -n 1)
            
            if [[ -n "$FIRST_USABLE_SUBNET_JSON" ]]; then
                SHARED_VPC_NETWORK_URL=$(echo "$FIRST_USABLE_SUBNET_JSON" | jq -r .network)
                SHARED_VPC_NETWORK=$(basename "$SHARED_VPC_NETWORK_URL")
                
                SHARED_VPC_SUBNET_URL=$(echo "$FIRST_USABLE_SUBNET_JSON" | jq -r .subnetwork)
                SHARED_VPC_SUBNET=$(basename "$SHARED_VPC_SUBNET_URL")
                
                # Extract Region from Subnet URL to ensure consistency
                # URL format: .../regions/REGION/subnetworks/SUBNET
                REGION=$(echo "$SHARED_VPC_SUBNET_URL" | sed -E 's/.*\/regions\/([^\/]+)\/.*/\1/')
            fi

            # 2. Discover Proxy Subnet (purpose=REGIONAL_MANAGED_PROXY, in the SAME Network and Region)
            if [[ -n "$SHARED_VPC_NETWORK_URL" ]]; then
                SHARED_VPC_PROXY_SUBNET_URL=$(echo "$USABLE_SUBNETS_JSON" | jq -r ".[] | .subnetwork = (.subnetwork // .selfLink) | select(.network == \"$SHARED_VPC_NETWORK_URL\") | select(.subnetwork | contains(\"/${REGION}/\")) | select(.purpose == \"REGIONAL_MANAGED_PROXY\") | .subnetwork" | head -n 1)
                SHARED_VPC_PROXY_SUBNET=$(basename "$SHARED_VPC_PROXY_SUBNET_URL")
            fi
        fi

        # Fallbacks if discovery fails
        if [[ -z "$SHARED_VPC_NETWORK" ]]; then
            read -p "Enter Shared VPC Network Name: " INPUT_NETWORK
            SHARED_VPC_NETWORK=${INPUT_NETWORK}
        fi
        if [[ -z "$SHARED_VPC_SUBNET" ]]; then
            read -p "Enter Shared VPC Subnet Name: " INPUT_SUBNET
            SHARED_VPC_SUBNET=${INPUT_SUBNET}
        fi
        if [[ -z "$SHARED_VPC_PROXY_SUBNET" ]]; then
            read -p "Enter Shared VPC Proxy Subnet Name: " INPUT_PROXY_SUBNET
            SHARED_VPC_PROXY_SUBNET=${INPUT_PROXY_SUBNET}
        fi
        
        echo -e "Network: ${YELLOW}${SHARED_VPC_NETWORK}${NC}"
        echo -e "Subnet: ${YELLOW}${SHARED_VPC_SUBNET}${NC}"
        echo -e "Proxy Subnet: ${YELLOW}${SHARED_VPC_PROXY_SUBNET}${NC}"
    fi

    # 3. Region
    if [[ -z "$REGION" ]]; then
        REGION=$(gcloud config get-value compute/region 2>/dev/null)
        REGION=${REGION:-"us-east4"}
        read -p "Enter Region [${REGION}]: " INPUT_REGION
        REGION=${INPUT_REGION:-$REGION}
    fi
    echo -e "Using Region: ${YELLOW}${REGION}${NC}"

    # 4. Domain
    if [[ -z "$DOMAIN" ]]; then
        ORG_DOMAIN=$(gcloud organizations list --filter="name:organizations/${ORG_ID}" --format="value(displayName)" 2>/dev/null)
        DOMAIN=${ORG_DOMAIN}
    fi

    if [[ -z "$DOMAIN" ]]; then
        read -p "Enter Domain (e.g., example.com): " DOMAIN
    else
        echo -e "Using Domain: ${YELLOW}${DOMAIN}${NC}"
    fi

    # 5. Identity Provider
    echo ""
    echo "Select Gemini Enterprise Identity Provider:"
    echo "----------------------------------------------------------------"
    echo "1) GSUITE (Default)"
    echo "   - Best for users with Google Workspace accounts."
    echo "   - Uses standard Google Groups (e.g., gcp-gemini-enterprise-admins@${DOMAIN})."
    echo "   - Simple setup, requires Cloud Identity or Google Workspace."
    echo ""
    echo "2) THIRD_PARTY (Workforce Identity Federation)"
    echo "   - Best for external identity providers (Okta, Azure AD, etc.)."
    echo "   - Syncless: No need to sync users to Google Cloud."
    echo "   - Uses Attribute-Based Access Control (ABAC)."
    echo "   - Requires a configured Workforce Identity Pool."
    echo "----------------------------------------------------------------"
    read -p "Enter selection [1]: " ACL_SELECTION
    
    ACL_IDP_TYPE="GSUITE"
    ACL_POOL_NAME=""
    ACL_PROVIDER_ID=""
    
    if [[ "$ACL_SELECTION" == "2" ]]; then
        ACL_IDP_TYPE="THIRD_PARTY"
        
        # Auto-discover Workforce Pools
        echo "Discovering Workforce Identity Pools..."
        POOLS_JSON=$(gcloud iam workforce-pools list --organization="${ORG_ID}" --location="global" --format="json" 2>/dev/null)
        
        if [[ -n "$POOLS_JSON" && "$POOLS_JSON" != "[]" ]]; then
            echo "Available Workforce Pools:"
            echo "$POOLS_JSON" | jq -r '.[] | "\(.name) (\(.displayName))"' | nl -w2 -s") "
            
            read -p "Select a Workforce Pool [1]: " POOL_SEL
            POOL_SEL=${POOL_SEL:-1}
            
            # Extract selected pool name (full resource name)
            ACL_POOL_NAME=$(echo "$POOLS_JSON" | jq -r ".[$((POOL_SEL-1))].name")
        fi
        
        if [[ -z "$ACL_POOL_NAME" ]]; then
            echo -e "${YELLOW}No pools found or invalid selection. Switching to manual entry.${NC}"
            read -p "Enter Workforce Pool ID: " ACL_POOL_ID
            ACL_POOL_NAME="locations/global/workforcePools/${ACL_POOL_ID}"
        else
            echo -e "Selected Pool: ${YELLOW}${ACL_POOL_NAME}${NC}"
        fi
        
        # Auto-discover Providers
        echo "Discovering Providers in ${ACL_POOL_NAME}..."
        PROVIDERS_JSON=$(gcloud iam workforce-pools providers list --workforce-pool="${ACL_POOL_NAME}" --location="global" --format="json" 2>/dev/null)
        
        if [[ -n "$PROVIDERS_JSON" && "$PROVIDERS_JSON" != "[]" ]]; then
            echo "Available Providers:"
            echo "$PROVIDERS_JSON" | jq -r '.[] | "\(.name) (\(.displayName))"' | nl -w2 -s") "
            
            read -p "Select a Provider [1]: " PROV_SEL
            PROV_SEL=${PROV_SEL:-1}
            
            # Extract selected provider ID (last part of name)
            FULL_PROV_NAME=$(echo "$PROVIDERS_JSON" | jq -r ".[$((PROV_SEL-1))].name")
            ACL_PROVIDER_ID=$(basename "$FULL_PROV_NAME")
        fi
        
        if [[ -z "$ACL_PROVIDER_ID" ]]; then
            echo -e "${YELLOW}No providers found or invalid selection. Switching to manual entry.${NC}"
            read -p "Enter Workforce Provider ID: " ACL_PROVIDER_ID
        else
            echo -e "Selected Provider: ${YELLOW}${ACL_PROVIDER_ID}${NC}"
        fi
        
        # Extract Pool ID for display/verification if needed (though we have full name now)
        ACL_POOL_ID=$(basename "$ACL_POOL_NAME")
        
        echo ""
        echo -e "${YELLOW}ACTION REQUIRED: Please verify the attribute mapping for your provider.${NC}"
        echo -e "1. Navigate to the Workforce Identity Pools page:"
        echo -e "${BLUE}https://console.cloud.google.com/iam-admin/workforce-identity-pools?orgonly=true&organizationId=${ORG_ID}&supportedpurview=organizationId${NC}"
        echo -e "2. Select the pool: ${GREEN}${ACL_POOL_ID}${NC}"
        echo -e "3. Go to the ${GREEN}Providers${NC} tab and select your provider: ${GREEN}${ACL_PROVIDER_ID}${NC}"
        echo -e "4. Click ${GREEN}EDIT${NC} and go to the ${GREEN}Attribute Mapping${NC} section."
        echo -e "5. Ensure that the attribute ${YELLOW}google.email${NC} is mapped from your identity provider's email attribute."
        echo -e "   (Example mapping: ${YELLOW}assertion.email${NC} or ${YELLOW}assertion.sub${NC})"
        echo ""
        read -p "Press Enter after you have confirmed the attribute mapping is correct..."
    fi

    # 6. Groups
    if [[ "$ACL_IDP_TYPE" == "GSUITE" ]]; then
        DEFAULT_ADMIN="gcp-gemini-enterprise-admins@${DOMAIN}"
        DEFAULT_USER="gcp-gemini-enterprise-users@${DOMAIN}"
        read -p "Enter Admin Group [${DEFAULT_ADMIN}]: " ADMIN_GROUP
        ADMIN_GROUP=${ADMIN_GROUP:-$DEFAULT_ADMIN}
        read -p "Enter User Group [${DEFAULT_USER}]: " USER_GROUP
        USER_GROUP=${USER_GROUP:-$DEFAULT_USER}
        
        # Add group: prefix
        [[ "$ADMIN_GROUP" != *":"* ]] && ADMIN_GROUP="group:${ADMIN_GROUP}"
        [[ "$USER_GROUP" != *":"* ]] && USER_GROUP="group:${USER_GROUP}"
    else
        echo ""
        echo -e "${YELLOW}For Workforce Identity, please enter the full Principal Set.${NC}"
        echo "This allows you to map groups or attributes from your IdP to IAM roles."
        echo ""
        echo "Examples:"
        echo " - All users in a specific IdP group:"
        echo "   principalSet://iam.googleapis.com/${ACL_POOL_NAME}/group/GROUP_ID"
        echo ""
        echo " - All users with a specific attribute (e.g., department=engineering):"
        echo "   principalSet://iam.googleapis.com/${ACL_POOL_NAME}/attribute.department/engineering"
        echo ""
        echo " - All users in the pool (Use with caution):"
        echo "   principalSet://iam.googleapis.com/${ACL_POOL_NAME}/*"
        echo ""
        
        read -p "Enter Admin Principal Set: " ADMIN_GROUP
        read -p "Enter User Principal Set: " USER_GROUP
    fi

    # 7. Access Policy
    echo "Discovering Access Policy..."
    ACCESS_POLICY_NUMBER=$(gcloud access-context-manager policies list --organization "${ORG_ID}" --format="value(name)" --quiet 2>/dev/null | head -n 1)
    if [ -z "$ACCESS_POLICY_NUMBER" ]; then
        echo -e "${YELLOW}Warning: Could not auto-discover Access Policy Number.${NC}"
        read -p "Enter Access Policy Number: " ACCESS_POLICY_NUMBER
        echo "An Access Policy is required for Access Context Manager."
        read -p "Do you want to create a new Access Policy? (y/N): " CREATE_POLICY
        if [[ "$CREATE_POLICY" == "y" || "$CREATE_POLICY" == "Y" ]]; then
            read -p "Enter a title for the new Access Policy [Gemini-Enterprise-Policy]: " POLICY_TITLE
            POLICY_TITLE=${POLICY_TITLE:-"Gemini-Enterprise-Policy"}
            
            echo "Creating Access Policy '${POLICY_TITLE}' in Organization ${ORG_ID}..."
            if gcloud access-context-manager policies create --organization "${ORG_ID}" --title "${POLICY_TITLE}" --quiet; then
                echo -e "${GREEN}Access Policy created successfully.${NC}"
                # Retrieve the new policy number
                ACCESS_POLICY_NUMBER=$(gcloud access-context-manager policies list --organization "${ORG_ID}" --format="value(name)" --quiet 2>/dev/null | head -n 1)
            else
                echo -e "${RED}Error: Failed to create Access Policy.${NC}"
                echo "Please ensure you have the 'Access Context Manager Admin' role at the Organization level."
                read -p "Enter Access Policy Number manually: " ACCESS_POLICY_NUMBER
            fi
        else
            read -p "Enter Access Policy Number: " ACCESS_POLICY_NUMBER
        fi
    else
        ACCESS_POLICY_NUMBER=$(basename "${ACCESS_POLICY_NUMBER}")
        echo -e "Found Access Policy Number: ${YELLOW}${ACCESS_POLICY_NUMBER}${NC}"
    fi

    if [[ -z "$ACCESS_POLICY_NUMBER" ]]; then
        echo -e "${RED}Error: Access Policy Number is required.${NC}"
        return 1
    fi

    # 8. Deployment Type (LB)
    echo ""
    echo -e "${YELLOW}Select Load Balancer Type:${NC}"
    echo "1) Regional External (Internet facing)"
    echo "2) Regional Internal"
    read -p "Enter selection [1]: " LB_SEL
    if [[ "$LB_SEL" == "2" ]]; then
        DEPLOYMENT_TYPE="internal"
    else
        DEPLOYMENT_TYPE="external"
    fi

    # 9. Chrome Enterprise Premium
    read -p "Enable Chrome Enterprise Premium (Zero Trust)? (y/N): " CEP_CHOICE
    ENABLE_CEP_BOOL="false"
    [[ "$CEP_CHOICE" == "y" || "$CEP_CHOICE" == "Y" ]] && ENABLE_CEP_BOOL="true"

    # 10. Data Stores
    read -p "Create Data Stores? (y/N): " DS_CHOICE
    CREATE_DS_BOOL="false"
    GCS_DATA_STORES="[]"
    BQ_DATA_STORES="[]"
    
    if [[ "$DS_CHOICE" == "y" || "$DS_CHOICE" == "Y" ]]; then
        CREATE_DS_BOOL="true"
        
        GCS_LIST=()
        BQ_LIST=()
        
        configure_data_stores
        
        if [[ ${#GCS_LIST[@]} -gt 0 ]]; then
            GCS_DATA_STORES="[$(IFS=,; echo "${GCS_LIST[*]}")]"
        fi
        if [[ ${#BQ_LIST[@]} -gt 0 ]]; then
            BQ_DATA_STORES="[$(IFS=,; echo "${BQ_LIST[*]}")]"
        fi
    fi

    # 11. Allowed IP Ranges
    echo ""
    echo -e "${BLUE}--- Allowed IP Ranges ---${NC}"
    echo "Enter IP ranges allowed to access the Load Balancer (CIDR format)."
    echo "RECOMMENDED: Set this to the IP range of the agency's corporate gateway to ensure that only authorized network traffic can reach the Load Balancer."
    echo "Leaving this empty will only enforce a US geolocation-based access policy."
    read -p "Enter IP Ranges (comma-separated, e.g., 203.0.113.0/24,192.168.1.0/24): " IP_RANGES_INPUT
    
    ALLOWED_IPS="[]"
    if [[ -n "$IP_RANGES_INPUT" ]]; then
        # Convert comma-separated string to JSON array
        # 1. Replace commas with spaces to iterate
        # 2. Wrap each in quotes
        # 3. Join with commas
        IFS=',' read -ra IP_ADDRS <<< "$IP_RANGES_INPUT"
        JSON_IPS=""
        for ip in "${IP_ADDRS[@]}"; do
            ip=$(echo "$ip" | xargs) # trim whitespace
            if [[ -n "$JSON_IPS" ]]; then
                JSON_IPS="$JSON_IPS, \"$ip\""
            else
                JSON_IPS="\"$ip\""
            fi
        done
        ALLOWED_IPS="[$JSON_IPS]"
    fi

    # Prerequisites Check
    echo ""
    check_org_policies
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    echo ""
    echo -e "${YELLOW}IMPORTANT: Before proceeding, ensure you have completed the following manual prerequisites:${NC}"
    echo "1. OAuth Consent Screen: Configured as Internal."
    echo -e "   Link: ${BLUE}https://console.cloud.google.com/auth/branding?orgonly=true&project=${PROJECT_ID}&supportedpurview=organizationId${NC}"
    echo "2. User Role Groups: Created admin/user groups in Cloud Identity / third-party identity provider (${ADMIN_GROUP}, ${USER_GROUP})."
    echo ""
    read -p "Have you completed these steps? (y/N): " CONFIRM_PRE
    if [[ "$CONFIRM_PRE" != "y" && "$CONFIRM_PRE" != "Y" ]]; then
        echo "Please complete the prerequisites and try again."
        return 1
    fi

    # Greenfield: Create KeyRing and Key if needed
    if [[ "$IS_BROWNFIELD" == "false" && "$IS_CUSTOM" == "false" && -z "$KMS_KEY_ID" ]]; then
        echo "Greenfield Deployment: Checking/Creating KMS KeyRing and Key..."
        KEYRING_NAME="gemini-enterprise-keyring"
        KEY_NAME="state-key"
        KEYRING_LOCATION="us"

        # Check/Create KeyRing
        if ! gcloud kms keyrings describe "$KEYRING_NAME" --location="$KEYRING_LOCATION" --project="$PROJECT_ID" &>/dev/null; then
            echo "Creating KeyRing ${KEYRING_NAME} in ${KEYRING_LOCATION}..."
            gcloud kms keyrings create "$KEYRING_NAME" --location="$KEYRING_LOCATION" --project="$PROJECT_ID"
        else
            echo "KeyRing ${KEYRING_NAME} already exists."
        fi

        # Check/Create Key
        if ! gcloud kms keys describe "$KEY_NAME" --keyring="$KEYRING_NAME" --location="$KEYRING_LOCATION" --project="$PROJECT_ID" &>/dev/null; then
            echo "Creating Key ${KEY_NAME} (HSM, 90-day rotation)..."
            # Calculate next rotation time (90 days from now) using Python for portability
            NEXT_ROTATION_TIME=$(python3 -c 'import datetime; print((datetime.datetime.utcnow() + datetime.timedelta(days=90)).strftime("%Y-%m-%dT%H:%M:%SZ"))')
            
            gcloud kms keys create "$KEY_NAME" \
                --keyring="$KEYRING_NAME" \
                --location="$KEYRING_LOCATION" \
                --purpose="encryption" \
                --protection-level="hsm" \
                --rotation-period="7776000s" \
                --next-rotation-time="$NEXT_ROTATION_TIME" \
                --project="$PROJECT_ID"
        else
            echo "Key ${KEY_NAME} already exists."
        fi
        
        KMS_KEY_ID="projects/${PROJECT_ID}/locations/${KEYRING_LOCATION}/keyRings/${KEYRING_NAME}/cryptoKeys/${KEY_NAME}"
        echo -e "Using KMS Key: ${YELLOW}${KMS_KEY_ID}${NC}"
    fi

    # Determine create_resource_keys
    # If Brownfield or Custom, and we have a KMS Key ID, we assume we are using existing keys
    # and do not need to create new ones.
    CREATE_RESOURCE_KEYS_BOOL="true"
    if [[ ("$IS_BROWNFIELD" == "true" || "$IS_CUSTOM" == "true") && -n "$KMS_KEY_ID" ]]; then
        CREATE_RESOURCE_KEYS_BOOL="false"
    fi

    # Generate tfvars
    cat > gemini-stage-0/terraform.tfvars <<EOF
deployment_type = "${DEPLOYMENT_TYPE}"
domain = "${DOMAIN}"
main_project_id = "${PROJECT_ID}"
prefix = "${PREFIX}"
region = "${REGION}"
geolocation = "us"
admin_group = "${ADMIN_GROUP}"
user_group = "${USER_GROUP}"
access_policy_number = ${ACCESS_POLICY_NUMBER}
create_data_stores = ${CREATE_DS_BOOL}
acl_idp_type = "${ACL_IDP_TYPE}"
acl_workforce_pool_name = "${ACL_POOL_NAME}"
acl_workforce_provider_id = "${ACL_PROVIDER_ID}"
kms_key_id = "${KMS_KEY_ID}"
enable_chrome_enterprise_premium = ${ENABLE_CEP_BOOL}
terraform_state_bucket = "${BUCKET_NAME}"
use_shared_vpc = ${USE_SHARED_VPC}
create_resource_keys = ${CREATE_RESOURCE_KEYS_BOOL}
allowed_ip_ranges = ${ALLOWED_IPS}
EOF

    if [[ "$USE_SHARED_VPC" == "true" ]]; then
        cat >> gemini-stage-0/terraform.tfvars <<EOF
network_project_id = "${SHARED_VPC_HOST_PROJECT}"
shared_vpc_network_name = "${SHARED_VPC_NETWORK}"
shared_vpc_subnet_name = "${SHARED_VPC_SUBNET}"
shared_vpc_proxy_subnet_name = "${SHARED_VPC_PROXY_SUBNET}"
EOF
    fi
    
    # Add example data stores
    cat >> gemini-stage-0/terraform.tfvars <<EOF
gcs_data_store_names = ${GCS_DATA_STORES}
bq_data_store_configs = ${BQ_DATA_STORES}
EOF

    echo -e "${GREEN}Configuration generated in gemini-stage-0/terraform.tfvars${NC}"
    return 0
}

deploy_stage_0() {
    echo -e "${BLUE}--- Deploying Stage 0 ---${NC}"
    
    # Ensure bucket exists if Greenfield
    if [[ "$IS_BROWNFIELD" == "false" ]]; then
        if ! gcloud storage buckets describe "gs://${BUCKET_NAME}" &>/dev/null; then
            echo "Creating state bucket gs://${BUCKET_NAME}..."
            
            # Grant Storage Service Agent access to CMEK if used
            if [[ -n "$KMS_KEY_ID" ]]; then
                PROJECT_NUMBER=$(gcloud projects describe "${PROJECT_ID}" --format="value(projectNumber)")
                STORAGE_SA="service-${PROJECT_NUMBER}@gs-project-accounts.iam.gserviceaccount.com"
                
                echo "Granting access to Storage Service Agent (${STORAGE_SA})..."
                gcloud kms keys add-iam-policy-binding "${KMS_KEY_ID}" \
                    --member="serviceAccount:${STORAGE_SA}" \
                    --role="roles/cloudkms.cryptoKeyEncrypterDecrypter" \
                    --project="${PROJECT_ID}" &>/dev/null || echo "Warning: Failed to grant IAM binding on key."
                
                gcloud storage buckets create "gs://${BUCKET_NAME}" --project "${PROJECT_ID}" --location "us" --uniform-bucket-level-access --default-encryption-key="${KMS_KEY_ID}"
            else
                gcloud storage buckets create "gs://${BUCKET_NAME}" --project "${PROJECT_ID}" --location "us" --uniform-bucket-level-access
            fi
        fi
    fi

    cd gemini-stage-0
    rm -f backend.tf
    
    echo "Initializing Terraform..."
    if ! terraform init -migrate-state -backend-config="bucket=${BUCKET_NAME}" -backend-config="prefix=terraform/state/stage-0"; then
        echo -e "${RED}Terraform Init failed! Please try resolving the error and running the Step again.${NC}"
        cd ..
        pause
        return 1
    fi
    
    echo "Applying Terraform..."
    if ! terraform apply; then
        echo -e "${RED}Terraform Apply failed! Please try resolving the error and running the Step again.${NC}"
        cd ..
        pause
        return 1
    fi
    
    GEMINI_IP=$(terraform output -raw gemini_enterprise_ip 2>/dev/null || echo "N/A")
    cd ..
    echo -e "${GREEN}Stage 0 Deployment Complete!${NC}"
    
    echo ""
    echo -e "${YELLOW}IMPORTANT NEXT STEPS:${NC}"
    echo -e "1. From the Main Menu select ${BLUE}Step 2 - Create Gemini Enterprise App (gem4gov-cli)${NC}."
    echo -e "2. Setup DNS A Record that points the desired Gemini Enterprise subdomain (i.e. gemini.yourdomain.com) to the provisioned Load Balancer IP address (${GEMINI_IP})."
    echo -e "3. Provision an SSL Certificate and upload it to Google Cloud Certificate Manager (${YELLOW}Helper Functions > Upload SSL Certificate${NC})."
    echo -e "4. From the Main Menu select ${BLUE}Step 3 - Configure & Deploy Load Balancer / Access Policies (gemini-stage-1)${NC}."
    pause
}

# --- Gem4Gov Functions ---

ensure_gem4gov_installed() {
    if ! command -v gem4gov &> /dev/null; then
        if [[ -d "gem4gov-cli" ]]; then
            echo "Installing gem4gov CLI..."
            pip3 install -e gem4gov-cli
            export PATH="$PATH:$(python3 -m site --user-base)/bin"
        else
            echo -e "${RED}gem4gov-cli directory not found.${NC}"
            return 1
        fi
    fi
    return 0
}

configure_gem4gov() {
    echo -e "${BLUE}--- Configure Gemini Enterprise App (gem4gov) ---${NC}"
    
    if ! ensure_gem4gov_installed; then
        return 1
    fi

    # Retrieve outputs from Stage 0 state
    echo "Retrieving state from gs://${BUCKET_NAME}/terraform/state/stage-0/default.tfstate..."
    STATE_CONTENT=$(gcloud storage cat "gs://${BUCKET_NAME}/terraform/state/stage-0/default.tfstate" 2>/dev/null || echo "{}")
    
    # Parse needed values
    PROJECT_ID_STATE=$(echo "$STATE_CONTENT" | jq -r '.outputs.main_project_id.value // empty')
    PROJECT_ID=${PROJECT_ID_STATE:-$PROJECT_ID}
    
    # Parse Load Balancer IP for display
    GEMINI_IP=$(echo "$STATE_CONTENT" | jq -r '.outputs.gemini_enterprise_ip.value // "N/A"')
    
    # Construct command
    CMD="gem4gov app create --project-id ${PROJECT_ID} --compliance-regime FEDRAMP_HIGH"
    
    # 1. Extract Data Store IDs
    # Retrieve both GCS and BQ Data Store IDs from outputs and concatenate them
    ALL_IDS_LIST=$(echo "$STATE_CONTENT" | jq -r '.outputs.gcs_data_store_ids.value[], .outputs.bq_data_store_ids.value[]' 2>/dev/null)
    
    # Join with commas for the CLI argument
    ALL_IDS=$(echo "$ALL_IDS_LIST" | tr '\n' ',' | sed 's/,$//')
    
    if [[ -n "$ALL_IDS" ]]; then
        CMD="$CMD --data-stores $ALL_IDS"
    fi

    # 2. Extract Workforce Identity Details
    POOL_NAME=$(echo "$STATE_CONTENT" | jq -r '.outputs.acl_workforce_pool_name.value // empty')
    PROVIDER_ID=$(echo "$STATE_CONTENT" | jq -r '.outputs.acl_workforce_provider_id.value // empty')
    
    # Check IdP Type for debugging/validation
    IDP_TYPE=$(echo "$STATE_CONTENT" | jq -r '.outputs.acl_idp_type.value // empty')

    if [[ "$IDP_TYPE" == "THIRD_PARTY" ]]; then
        if [[ -z "$POOL_NAME" || -z "$PROVIDER_ID" ]]; then
             echo -e "${RED}Error: Third Party IdP selected but Pool/Provider details missing in state.${NC}"
             echo "Please ensure Stage 0 was deployed with Third Party configuration."
        fi
    fi
    
    if [[ -n "$POOL_NAME" && -n "$PROVIDER_ID" ]]; then
        # Extract Pool ID from full name (locations/global/workforcePools/POOL_ID)
        POOL_ID=$(basename "$POOL_NAME")
        CMD="$CMD --workforce-pool-id $POOL_ID --workforce-provider-id $PROVIDER_ID"
    fi


    echo "Running: $CMD"
    $CMD
    
    echo -e "${GREEN}Gemini Enterprise Application configured.${NC}"

    echo ""
    echo -e "${YELLOW}IMPORTANT NEXT STEPS:${NC}"
    echo -e "1. Take note of the ${GREEN}Gemini Enterprise Widget Config ID${NC} from the output above for the configuration of the Load Balancer.${NC}"
    echo -e "2. Setup DNS A Record that points the desired Gemini Enterprise subdomain (i.e. gemini.yourdomain.com) to the provisioned Load Balancer IP address (${GEMINI_IP})."
    echo -e "3. Provision an SSL Certificate and upload it to Google Cloud Certificate Manager (${YELLOW}Helper Functions > Upload SSL Certificate${NC})."
    echo -e "4. From the Main Menu select ${BLUE}Step 3 - Configure & Deploy Load Balancer / Access Policies (gemini-stage-1)${NC}."
    echo ""
    echo -e "${GREEN}NOTE: Please wait approximately 10 minutes before using your Gemini Enterprise application as it finishes provisioning.${NC}"
    pause
}

update_app_compliance() {
    echo -e "${BLUE}--- Update Gemini Enterprise App Compliance ---${NC}"

    if ! ensure_gem4gov_installed; then
        return 1
    fi

    # Ensure Project ID is set
    if [[ -z "$PROJECT_ID" ]]; then
        echo -e "${RED}Project ID is required. Please select a project first.${NC}"
        return 1
    fi

    read -p "Enter Gemini Enterprise Engine ID: " ENGINE_ID
    if [[ -z "$ENGINE_ID" ]]; then
        echo -e "${RED}Engine ID is required.${NC}"
        return 1
    fi

    echo "Select Compliance Regime:"
    echo "1. FedRAMP High"
    echo "2. IL4"
    read -p "Select an option [1-2]: " COMPLIANCE_SEL

    COMPLIANCE_REGIME=""
    if [[ "$COMPLIANCE_SEL" == "1" ]]; then
        COMPLIANCE_REGIME="FEDRAMP_HIGH"
    elif [[ "$COMPLIANCE_SEL" == "2" ]]; then
        COMPLIANCE_REGIME="IL4"
    else
        echo -e "${RED}Invalid selection.${NC}"
        return 1
    fi

    CMD="gem4gov app update-compliance --project-id ${PROJECT_ID} --engine-id ${ENGINE_ID} --compliance-regime ${COMPLIANCE_REGIME}"
    
    echo "Running: $CMD"
    $CMD
    
    pause
}

# --- Helper Functions ---

upload_ssl_certificate() {
    echo -e "${BLUE}--- Upload SSL Certificate ---${NC}"
    
    # Ensure Project ID is set
    if [[ -z "$PROJECT_ID" ]]; then
        echo -e "${RED}Project ID is required. Please select a project first.${NC}"
        return 1
    fi

    echo -e "${YELLOW}Requirements for Self-Managed SSL Certificates:${NC}"
    echo -e "1. Certificate and Key must be in ${BLUE}PEM format${NC}."
    echo -e "2. Private Key must ${RED}NOT${NC} be protected by a passphrase."
    echo -e "3. Encryption algorithm must be either ${BLUE}RSA${NC} or ${BLUE}ECDSA${NC}."
    echo -e "   - RSA-2048 or ECDSA P-256 are recommended."
    echo ""
    echo -e "For more details, see: https://docs.cloud.google.com/load-balancing/docs/ssl-certificates/self-managed-certs#create-key-and-cert"
    echo ""

    read -p "Enter Certificate Name (e.g., my-cert): " CERT_NAME
    if [[ -z "$CERT_NAME" ]]; then
        echo -e "${RED}Certificate Name is required.${NC}"
        return 1
    fi

    # Default region
    DEFAULT_REGION=${REGION:-"us-east4"}
    read -p "Enter Region [${DEFAULT_REGION}]: " INPUT_REGION
    CERT_REGION=${INPUT_REGION:-$DEFAULT_REGION}

    while true; do
        read -p "Enter path to Certificate File (.crt/.pem): " CERT_PATH
        # Expand tilde if present
        CERT_PATH="${CERT_PATH/#\~/$HOME}"
        if [[ -f "$CERT_PATH" ]]; then
            if grep -qE -e "-----BEGIN CERTIFICATE-----" "$CERT_PATH"; then
                break
            else
                echo -e "${RED}Error: File does not appear to be a PEM-formatted certificate (missing '-----BEGIN CERTIFICATE-----').${NC}"
            fi
        else
            echo -e "${RED}File not found: $CERT_PATH${NC}"
        fi
    done

    while true; do
        read -p "Enter path to Private Key File (.key/.pem): " KEY_PATH
        # Expand tilde if present
        KEY_PATH="${KEY_PATH/#\~/$HOME}"
        if [[ -f "$KEY_PATH" ]]; then
            if grep -qE -e "-----BEGIN .*PRIVATE KEY-----" "$KEY_PATH"; then
                break
            else
                echo -e "${RED}Error: File does not appear to be a PEM-formatted private key (missing '-----BEGIN ... PRIVATE KEY-----').${NC}"
            fi
        else
            echo -e "${RED}File not found: $KEY_PATH${NC}"
        fi
    done

    echo ""
    echo "Creating Regional SSL Certificate..."
    echo "Name: ${CERT_NAME}"
    echo "Region: ${CERT_REGION}"
    echo "Certificate: ${CERT_PATH}"
    echo "Key: ${KEY_PATH}"
    echo ""
    
    if gcloud compute ssl-certificates create "$CERT_NAME" \
        --certificate="$CERT_PATH" \
        --private-key="$KEY_PATH" \
        --region="$CERT_REGION" \
        --project="$PROJECT_ID"; then
        echo -e "${GREEN}SSL Certificate '${CERT_NAME}' created successfully!${NC}"
    else
        echo -e "${RED}Failed to create SSL Certificate.${NC}"
    fi
    
    pause
}

replace_gemini_app() {
    echo -e "${BLUE}--- Replace Gemini Enterprise Application / Load Balancer Routing ---${NC}"
    echo -e "${YELLOW}WARNING: This will create a NEW Gemini Enterprise Application and update the Load Balancer to route traffic to it.${NC}"
    echo -e "${YELLOW}The old application will NOT be deleted automatically.${NC}"
    echo ""
    read -p "Are you sure you want to proceed? (y/N): " CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        return 0
    fi

    # 1. Create new App
    configure_gem4gov

    # 2. Update Networking (Stage 1)
    echo ""
    echo -e "${YELLOW}IMPORTANT: When prompted to 'Reuse existing configuration' for Stage 1, answer 'n' (No).${NC}"
    echo -e "${YELLOW}You MUST enter the NEW Gemini Enterprise Widget Config ID from the previous step.${NC}"
    echo ""
    pause

    configure_stage_1 || return 1
    deploy_stage_1
}

helper_menu() {
    while true; do
        clear
        print_header
        echo -e "${BLUE}--- Helper Functions ---${NC}"
        echo "1. Update Gemini Enterprise App Compliance (gem4gov-cli)"
        echo "2. Replace Gemini Enterprise Application / Load Balancer Routing"
        echo "3. Upload SSL Certificate"
        echo "4. Back to Main Menu"
        echo "-----------------------------------"
        read -p "Select an option [1-4]: " OPTION

        case $OPTION in
            1)
                update_app_compliance
                ;;
            2)
                replace_gemini_app
                ;;
            3)
                upload_ssl_certificate
                ;;
            4)
                return 0
                ;;
            *)
                echo "Invalid option."
                pause
                ;;
        esac
    done
}

# --- Stage 1 Functions ---

configure_stage_1() {
    echo -e "${BLUE}--- Configure Stage 1 (Networking) ---${NC}"
    mkdir -p gemini-stage-1
    
    if [[ -f "gemini-stage-1/terraform.tfvars" ]]; then
        read -p "Reuse existing configuration? (Y/n): " REUSE_CONFIG
        if [[ "$REUSE_CONFIG" != "n" && "$REUSE_CONFIG" != "N" ]]; then
            return 0
        fi
    fi

    # Retrieve Region from Stage 0 state if not set
    if [[ -z "$REGION" ]]; then
        echo "Retrieving region from state..."
        STATE_CONTENT=$(gcloud storage cat "gs://${BUCKET_NAME}/terraform/state/stage-0/default.tfstate" 2>/dev/null || echo "{}")
        REGION=$(echo "$STATE_CONTENT" | jq -r '.outputs.region.value // empty')
        
        if [[ -z "$REGION" ]]; then
             # Try to get it from the bucket location or default
             REGION="us-central1"
             echo -e "${YELLOW}Warning: Could not retrieve region from state. Using default: ${REGION}${NC}"
        else
             echo -e "Region retrieved: ${YELLOW}${REGION}${NC}"
        fi
    fi

    read -p "Enter Gemini Enterprise Domain (e.g., gemini.example.com): " GEMINI_DOMAIN
    
    # Validate DNS
    echo "Validating DNS for ${GEMINI_DOMAIN}..."
    if [[ -z "$STATE_CONTENT" ]]; then
        STATE_CONTENT=$(gcloud storage cat "gs://${BUCKET_NAME}/terraform/state/stage-0/default.tfstate" 2>/dev/null || echo "{}")
    fi
    
    LB_IP=$(echo "$STATE_CONTENT" | jq -r '.outputs.gemini_enterprise_ip.value // empty')
    
    if [[ -n "$LB_IP" ]]; then
        CURRENT_IP=$(dig +short "$GEMINI_DOMAIN" | grep "$LB_IP")
        if [[ -n "$CURRENT_IP" ]]; then
             echo -e "${GREEN}DNS Validation Successful: ${GEMINI_DOMAIN} resolves to ${LB_IP}${NC}"
        else
             RESOLVED_IPS=$(dig +short "$GEMINI_DOMAIN" | tr '\n' ' ')
             echo -e "${YELLOW}WARNING: DNS Validation Failed!${NC}"
             echo -e "Expected IP: ${LB_IP}"
             echo -e "Resolved IPs: ${RESOLVED_IPS:-None}"
             echo -e "${YELLOW}Please ensure your DNS A record is correctly pointing to ${LB_IP}.${NC}"
             read -p "Continue anyway? (y/N): " CONFIRM_DNS
             if [[ "$CONFIRM_DNS" != "y" && "$CONFIRM_DNS" != "Y" ]]; then
                 return 1
             fi
        fi
    else
        echo -e "${YELLOW}Warning: Could not retrieve Load Balancer IP from state. Skipping DNS validation.${NC}"
    fi
    
    # Auto-discover SSL Certificates
    echo "Discovering SSL Certificates in Region ${REGION}..."
    CERTS_JSON=$(gcloud compute ssl-certificates list --filter="region:(${REGION})" --format="json" 2>/dev/null)
    
    if [[ -n "$CERTS_JSON" && "$CERTS_JSON" != "[]" ]]; then
        echo "Available SSL Certificates:"
        echo "$CERTS_JSON" | jq -r '.[] | "\(.name) (\(.type))"' | nl -w2 -s") "
        
        read -p "Select an SSL Certificate [1]: " CERT_SEL
        CERT_SEL=${CERT_SEL:-1}
        
        SSL_CERT_NAME=$(echo "$CERTS_JSON" | jq -r ".[$((CERT_SEL-1))].name")
        echo -e "Selected Certificate: ${YELLOW}${SSL_CERT_NAME}${NC}"
    else
        echo -e "${YELLOW}No SSL Certificates found in region ${REGION}.${NC}"
        read -p "Enter SSL Certificate Name (must exist in GCP): " SSL_CERT_NAME
    fi

    read -p "Enter Gemini Widget Config ID (from gem4gov step): " GEMINI_CONFIG_ID
    
    cat > gemini-stage-1/terraform.tfvars <<EOF
stage_0_state_bucket = "${BUCKET_NAME}"
gemini_enterprise_domain = "${GEMINI_DOMAIN}"
ssl_certificate_name = "${SSL_CERT_NAME}"
gemini_config_id = "${GEMINI_CONFIG_ID}"
EOF

    # Add Shared VPC vars if needed (simple check)
    if [[ -n "$SHARED_VPC_NETWORK" ]]; then
        echo "network_name = \"${SHARED_VPC_NETWORK}\"" >> gemini-stage-1/terraform.tfvars
        echo "host_project_id = \"${SHARED_VPC_HOST_PROJECT}\"" >> gemini-stage-1/terraform.tfvars
    fi

    echo -e "${GREEN}Configuration generated in gemini-stage-1/terraform.tfvars${NC}"
    return 0
}

deploy_stage_1() {
    echo -e "${BLUE}--- Deploying Stage 1 ---${NC}"
    
    cd gemini-stage-1
    rm -f backend.tf
    
    echo "Initializing Terraform..."
    if ! terraform init -migrate-state -backend-config="bucket=${BUCKET_NAME}" -backend-config="prefix=terraform/state/stage-1"; then
        echo -e "${RED}Terraform Init failed! Please try resolving the error and running the Step again.${NC}"
        cd ..
        pause
        return 1
    fi
    
    echo "Applying Terraform..."
    if ! terraform apply -var-file="terraform.tfvars"; then
        echo -e "${RED}Terraform Apply failed! Please try resolving the error and running the Step again.${NC}"
        cd ..
        pause
        return 1
    fi
    
    cd ..
    echo -e "${GREEN}Stage 1 Deployment Complete!${NC}"
    
    # Post-Deployment: Third Party OAuth Setup
    # We need to check ACL_IDP_TYPE, but it might not be set if we just ran Stage 1.
    # We can try to read it from Stage 0 state if missing.
    if [[ -z "$ACL_IDP_TYPE" ]]; then
         STATE_CONTENT=$(gcloud storage cat "gs://${BUCKET_NAME}/terraform/state/stage-0/default.tfstate" 2>/dev/null || echo "{}")
         ACL_IDP_TYPE=$(echo "$STATE_CONTENT" | jq -r '.outputs.acl_idp_type.value // empty')
         ACL_POOL_NAME=$(echo "$STATE_CONTENT" | jq -r '.outputs.acl_workforce_pool_name.value // empty')
    fi

    if [[ "$ACL_IDP_TYPE" == "THIRD_PARTY" ]]; then
        echo ""
        echo -e "${YELLOW}ACTION REQUIRED: Complete the Identity-Aware Proxy (IAP) configuration manually.${NC}"
        echo -e "Because you selected THIRD_PARTY (Workforce Identity Federation), you must configure the OAuth Client and IAP settings manually."
        
        BACKEND_SERVICE_NAME="${PREFIX}-backend-service"

        echo ""
        echo -e "${BLUE}Step 1: Create an OAuth Client${NC}"
        echo -e "1. Navigate to APIs & Services > Credentials: ${BLUE}https://console.cloud.google.com/apis/credentials?project=${PROJECT_ID}${NC}"
        echo "2. Click 'Create Credentials' > 'OAuth client ID'."
        echo "3. Application type: 'Web application'."
        echo "4. Name: 'Gemini Enterprise IAP Client'."
        echo "5. Click 'Create'. (Do not add redirect URIs yet)."
        echo "6. Copy the 'Client ID' and 'Client Secret'."
        echo -e "${NC}"
        read -p "Press Enter after you have created the client..."

        echo ""
        echo -e "${BLUE}Step 2: Update Redirect URI${NC}"
        echo "1. Edit the newly created OAuth Client."
        echo -e "2. Add the following Authorized redirect URI (replace [CLIENT_ID] with the actual ID you just copied): ${YELLOW}https://iap.googleapis.com/v1/oauth/clientIds/[CLIENT_ID]:handleRedirect${NC}"
        echo "3. Save the changes."
        echo -e "${NC}"
        read -p "Press Enter after you have updated the redirect URI..."

        echo ""
        echo -e "${BLUE}Step 3: Configure IAP for Workforce Identity${NC}"
        echo -e "1. Navigate to IAP: ${BLUE}https://console.cloud.google.com/security/iap?project=${PROJECT_ID}${NC}"
        echo -e "2. Locate the Backend Service: ${GREEN}${BACKEND_SERVICE_NAME}${NC}"
        echo "3. Select the \"Settings\" in the 3-dots menu next to the backend service resource."
        echo "4. Select \"Custom OAuth (for specific control, branding, or external users)\" and configure the following:"
        echo "   - OAuth client ID: (Paste from Step 1)"
        echo "   - OAuth client secret: (Paste from Step 1)"
        echo "6. Click 'Save'."
        echo -e "${NC}"
        read -p "Press Enter after you have configured IAP..."
        echo ""
        echo -e "${GREEN}OAuth and IAP Manual Configuration marked as complete.${NC}"
    fi
    
    echo ""
    echo -e "Welcome to your ${BLUE}G${RED}o${YELLOW}o${BLUE}g${GREEN}l${RED}e${NC} Cloud Gemini Enterprise App! Access your app at https://${GEMINI_DOMAIN}"
    pause
}

# --- Main Menu ---

main_menu() {
    while true; do
        clear
        print_header
        echo -e "Current Project: ${YELLOW}${PROJECT_ID:-None}${NC}"
        echo -e "Deployment Type: ${YELLOW}${DEPLOYMENT_TYPE_TEXT:-None}${NC}"
        echo "-----------------------------------"
        echo -e "1. ${BLUE}Step 1${NC} - Configure & Deploy Infrastructure (gemini-stage-0)"
        echo -e "2. ${BLUE}Step 2${NC} - Create Gemini Enterprise App (gem4gov-cli)"
        echo -e "3. ${BLUE}Step 3${NC} - Configure & Deploy Load Balancer / Access Policies (gemini-stage-1)"
        echo -e "4. ${YELLOW}Helper Functions${NC}"
        echo -e "5. ${YELLOW}Re-select Deployment Type / Project${NC}"
        echo -e "6. ${RED}Exit${NC}"
        echo "-----------------------------------"
        read -p "Select an option [1-6]: " OPTION

        case $OPTION in
            1)
                if [[ -z "$PROJECT_ID" ]]; then
                    echo -e "${RED}Please select a project first (Option 5).${NC}"
                    pause
                    continue
                fi
                configure_stage_0 || continue
                deploy_stage_0 || continue
                ;;
            2)
                if [[ -z "$PROJECT_ID" ]]; then
                    echo -e "${RED}Please select a project first (Option 5).${NC}"
                    pause
                    continue
                fi
                configure_gem4gov || continue
                ;;
            3)
                if [[ -z "$PROJECT_ID" ]]; then
                    echo -e "${RED}Please select a project first (Option 5).${NC}"
                    pause
                    continue
                fi
                configure_stage_1 || continue
                deploy_stage_1 || continue
                ;;
            4)
                helper_menu || continue
                ;;
            5)
                auth_and_project_setup || continue
                enable_apis || continue
                select_deployment_type || continue
                discover_brownfield_resources || continue
                ;;
            6)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo "Invalid option."
                pause
                ;;
        esac
    done
}

# --- Entry Point ---

check_dependencies
auth_and_project_setup
enable_apis
select_deployment_type
discover_brownfield_resources
main_menu
