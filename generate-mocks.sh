SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Generate mock provider files for all stages in stages-aw
echo 'terraform {
  required_version = ">= 1.7.4"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.24.0"
    }
    google-beta = {
      source = "hashicorp/google-beta"
      version = ">=1.0.0"
    }
    local = {
      source = "hashicorp/local"
      version = ">=2.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">=0.0.0"
    }
    external = {
      source  = "hashicorp/external"
      version = ">=0.0.0"
    }
   random = {
      source  = "hashicorp/random"
      version = ">=3.0.0"
    }
   tls = {
      source  = "hashicorp/tls"
      version = ">=3.0.0"
    }
  }
}' | tee ${SCRIPT_DIR}/fast/stages-aw/0-bootstrap/mock-versions.tf \
         ${SCRIPT_DIR}/fast/stages-aw/1-resman/mock-versions.tf \
         ${SCRIPT_DIR}/fast/stages-aw/2-networking-c-nva/mock-versions.tf \
         ${SCRIPT_DIR}/fast/stages-aw/2-networking-f-ngfw/mock-versions.tf \
         ${SCRIPT_DIR}/fast/stages-aw/2-security/mock-versions.tf \
         ${SCRIPT_DIR}/fast/stages-aw/3-project-factory/dev/mock-versions.tf

echo '{
    "automation": {
        "federated_identity_pool": null,
        "federated_identity_providers": {},
        "outputs_bucket": "tflint-prod-iac-core-outputs-0",
        "project_id": "tflint-prod-iac-core-0",
        "project_number": "1234567890123",
        "service_accounts": {
            "bootstrap": "tflint-prod-bootstrap-0@tflint-prod-iac-core-0.iam.gserviceaccount.com",
            "bootstrap-r": "tflint-prod-bootstrap-0r@tflint-prod-iac-core-0.iam.gserviceaccount.com",
            "resman": "tflint-prod-resman-0@tflint-prod-iac-core-0.iam.gserviceaccount.com",
            "resman-r": "tflint-prod-resman-0r@tflint-prod-iac-core-0.iam.gserviceaccount.com"
        }
    },
    "custom_roles": {
        "gcve_network_admin": "organizations/123456789012/roles/gcveNetworkAdmin",
        "organization_admin_viewer": "organizations/123456789012/roles/organizationAdminViewer",
        "organization_iam_admin": "organizations/123456789012/roles/organizationIamAdmin",
        "service_project_network_admin": "organizations/123456789012/roles/serviceProjectNetworkAdmin",
        "storage_viewer": "organizations/123456789012/roles/storageViewer",
        "tag_viewer": "organizations/123456789012/roles/tagViewer",
        "tenant_network_admin": "organizations/123456789012/roles/tenantNetworkAdmin"
    },
    "logging": {
        "project_id": "tflint-prod-audit-logs-0",
        "project_number": "1234567890123",
        "writer_identities": {
            "audit-logs": "serviceAccount:service-org-123456789012@gcp-sa-logging.iam.gserviceaccount.com",
            "vpc-sc": "serviceAccount:service-org-123456789012@gcp-sa-logging.iam.gserviceaccount.com",
            "workspace-audit-logs": "serviceAccount:service-org-123456789012@gcp-sa-logging.iam.gserviceaccount.com"
        }
    },
    "org_policy_tags": {
        "key_id": "tagKeys/123456789012345",
        "key_name": "org-policies",
        "values": {
            "allowed-policy-member-domains-all": "tagValues/123456789012345"
        }
    }
}' | tee ${SCRIPT_DIR}/fast/stages-aw/1-resman/mock-variables.auto.tfvars.json \
         ${SCRIPT_DIR}/fast/stages-aw/2-networking-a-fedramp-high/dev/mock-variables.auto.tfvars.json \
         ${SCRIPT_DIR}/fast/stages-aw/2-networking-c-nva/mock-variables.auto.tfvars.json \
         ${SCRIPT_DIR}/fast/stages-aw/2-networking-f-ngfw/mock-variables.auto.tfvars.json \
         ${SCRIPT_DIR}/fast/stages-aw/2-security/mock-variables.auto.tfvars.json \
         ${SCRIPT_DIR}/fast/stages-aw/3-project-factory/dev/mock-variables.auto.tfvars.json

# Generate mock tfvars file
echo 'host_project_ids = { prod-landing = "" }' >>  "${SCRIPT_DIR}/fast/stages-aw/3-project-factory/dev/terraform.tfvars"
