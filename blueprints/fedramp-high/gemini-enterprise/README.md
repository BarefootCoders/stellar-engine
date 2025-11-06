# Gemini Enterprise on GCP - FedRAMP High

This blueprint deploys the necessary infrastructure to host a Gemini Enterprise application on Google Cloud Platform, adhering to FedRAMP High compliance standards. It provisions a secure environment with networking, load balancing, access controls, and data stores for Vertex AI Search.

**IMPORTANT:** This blueprint is designed to be deployed in a **FedRAMP High GCP project**, to ensure a clean slate for meeting stringent FedRAMP High security and compliance requirements.

## Overall Architecture

The blueprint sets up the following key components:

1.  **Networking:** A dedicated Virtual Private Cloud (VPC) with subnets 
    *   Private Google Access subnet
    *   Regional Managed Proxy subnet (for the regional https load balancer)
    
2.  **Load Balancing:** A Regional External HTTPS Load Balancer to direct traffic.
    *   Front end (which will be applied, after you do the following):
        * Upload your certificate to Google Cloud, validating you own the domain, manually
        * Point your reserved IP made via this blueprint, to your domain on your registrar.
    *   Back end (which will create a load balancer backend service via the created Regional Network Endpoint Group). 
    *   Routing Rules (which will point to the FQDN and redirect to the customer ID, which will be applied, after you do the following):
        * Run the Gem4Gov CLI & bootstrap the Gemini Enterprise instance, which will auto-configure the application to run in a FedRAMP High compliant manner. This will give you your customer-id, which you can then take and add to your routing rules of the load balancer.

3.  **Security:**
    *   Identity-Aware Proxy (IAP) to control access to the application, tied to the backend service.
    *   Cloud Armor for web application firewall capabilities, tied to the backend service.
    *   Organization Policies to enforce security constraints.
    *   IAM policies and Service Accounts following the principle of least privilege.
4.  **Data Stores:** CMEK-encrypted GCS buckets and BigQuery datasets for Vertex AI Search, managed by the `discovery-engine` module.

## Resources Created by Blueprint

Below is a breakdown of resources created, organized by their primary configuration files within the `blueprints/fedramp-high/gemini-enterprise/` directory:

### `network.tf`

*   **VPC Network:** A custom mode VPC (`google_compute_network`) providing network isolation.
*   **Subnets:**
    *   A primary subnet (`google_compute_subnetwork`) for application resources.
    *   A proxy-only subnet (`google_compute_subnetwork`) required for the internal load balancer used by IAP.
*   **Firewall Rules:** (Implicitly, a default deny ingress is assumed, with specific allows as needed - though not explicitly shown in open files).
*   **Cloud NAT:** (`google_compute_router` and `google_compute_router_nat`) to allow private subnet resources to access the internet without external IPs.

### `load_balancer.tf`

*   **External IP Address:** A static IP (`google_compute_address`) for the load balancer.
*   **SSL Certificate:** A Google-managed SSL certificate (`google_compute_managed_ssl_certificate`) for HTTPS.
*   **Health Check:** (`google_compute_region_health_check`) to monitor backend health.
*   **Backend Service:** (`google_compute_region_backend_service`) defines how traffic is distributed to backends, with IAP enabled.
*   **URL Map:** (`google_compute_region_url_map`) to route incoming requests to the backend service.
*   **Target HTTPS Proxy:** (`google_compute_target_https_proxy`) to terminate HTTPS traffic.
*   **Forwarding Rule:** (`google_compute_forwarding_rule`) to link the external IP and port to the target proxy.

### `iap.tf` (Assumed to be part of the Load Balancer setup)

*   **IAP Configuration:** Enabled on the Backend Service, restricting access based on IAM permissions.
*   **OAuth Brand & Client:** (`google_iap_brand`, `google_iap_client`) for the IAP consent screen.
*   **IAM Bindings:** Granting specific groups/users the `roles/iap.httpsResourceAccessor` role on the backend service (may require manual gcloud commands as noted in the original README).

### `cloud_armor.tf` (If present, not in open files)

*   **Security Policy:** (`google_compute_security_policy`) to define WAF rules, IP blacklists/whitelists, and rate limiting.

### `iam.tf` (Assumed)

*   **Service Accounts:** Dedicated service accounts for different components with minimal necessary permissions.
*   **IAM Policies:** Bindings on project, service accounts, and resources to enforce least privilege.

### `org-policy.tf`

*   **Organization Policy Constraints:** Enforces policies such as:
    *   `constraints/compute.restrictLoadBalancerCreationForTypes`: Allowing only specific load balancer types (e.g., Regional External HTTPS).
    *   Domain Restricted Sharing (`constraints/iam.allowedPolicyMemberDomains`).
    *   Other policies relevant to FedRAMP High.

### `discovery-engine/discovery-engine.tf`

This submodule focuses on the Vertex AI Search data layer:

*   **API Enablement:** `discoveryengine`, `cloudkms`, `bigquery`, `storage`.
*   **KMS Keyring/Key:** (`google_kms_key_ring`, `google_kms_crypto_key`) for CMEK.
*   **IAM for KMS:** Grants service agents access to the CMEK.
*   **Discovery Engine CMEK Config:** (`google_discovery_engine_cmek_config`) sets the default CMEK for the service.
*   **GCS Buckets:** (`google_storage_bucket`) dynamically created based on `var.gcs_data_store_names`, CMEK encrypted.
*   **GCS Data Stores:** (`google_discovery_engine_data_store`) linked to each GCS bucket.
*   **BigQuery Datasets/Tables:** (`google_bigquery_dataset`, `google_bigquery_table`) dynamically created based on `var.bq_data_store_configs`, CMEK encrypted.
*   **BigQuery Data Connectors:** (`google_discovery_engine_data_connector`) to sync BigQuery data to Vertex AI Search.
*   **Discovery Engine ACL Config:** (`google_discovery_engine_acl_config`) for GSUITE IDP.

### `discovery-engine/provider.tf`

*   Configures `google` and `google-beta` providers.
*   **Service Identities:** (`google_project_service_identity`) Creates service agents for Discovery Engine and Storage.
*   **Time Sleep:** Introduces delays to allow for API enablement and service agent propagation.

## Key Variables

These variables are typically defined in the `terraform.tfvars` file in the `blueprints/fedramp-high/gemini-enterprise/` directory.

| Variable                 | Description                                                                                                | File(s) Where Used                                  |
| :----------------------- | :--------------------------------------------------------------------------------------------------------- | :-------------------------------------------------- |
| `main_project_id`        | The target GCP Project ID for deployment.                                                                  | All files                                           |
| `region`                 | The GCP region for regional resources (e.g., subnets, load balancer).                                        | `network.tf`, `load_balancer.tf`, `discovery-engine/*` |
| `domain`                 | The domain name to use for the IAP and SSL certificate.                                                    | `load_balancer.tf`                                  |
| `org_id`                 | The GCP Organization ID.                                                                                   | `org-policy.tf`                                     |
| `access_policy_number`   | The ID of the Access Context Manager policy for the organization.                                          | `iap.tf` (assumed)                                  |
| `oauth_brand_number`     | The OAuth brand ID for the IAP consent screen.                                                             | `iap.tf` (assumed)                                  |
| `geolocation`            | Location for Discovery Engine resources (e.g., "us", "eu").                                                | `discovery-engine/*`                                |
| `gcs_data_store_names`   | List of names for creating GCS buckets and associated Data Stores.                                         | `discovery-engine/discovery-engine.tf`              |
| `bq_data_store_configs`  | List of objects defining BigQuery datasets and tables for Data Connectors.                                 | `discovery-engine/discovery-engine.tf`              |
| `gcs_label_environment`  | Label for GCS bucket environment.                                                                          | `discovery-engine/discovery-engine.tf`              |

## Deployment Steps

1.  Navigate to `blueprints/fedramp-high/gemini-enterprise/`.
2.  Create a `terraform.tfvars` file based on the sample, filling in all required values.
3.  Initialize Terraform: `terraform init`
4.  Review the plan: `terraform plan`
5.  Apply the configuration: `terraform apply`
6.  Perform any manual steps indicated (e.g., IAP IAM bindings if needed).
7.  Populate GCS buckets and BigQuery tables with data.
8.  Run manual import for GCS Data Stores as described in the `discovery-engine/README.md`.
9.  Use the "gem for Gov CLI" tool to create the Gemini Enterprise application, linking the Data Store IDs from the Terraform outputs.

## Manual Data Import & Synchronization

*   **GCS:** After `terraform apply`, upload your documents to the created GCS buckets. Then, use the gcloud CLI or Cloud Console to import data from the GCS bucket into the corresponding Data Store. Example for one Data Store:
    ```bash
    # Obtain the Data Store ID from Terraform outputs
    DATA_STORE_ID="<e.g., company-docs-gcs-data-store>"
    BUCKET_NAME="<e.g., your-gcp-project-id-company-docs-data>"
    PROJECT_ID=$(gcloud config get-value project)
    GEOLOCATION="us" # Match var.geolocation

    gcloud discovery-engine data-stores import $DATA_STORE_ID \
      --project=$PROJECT_ID \
      --location=$GEOLOCATION \
      --gcs-source=gs://${BUCKET_NAME}/* \
      --data-schema=content
    ```
    Repeat for each GCS-based data store.

*   **BigQuery:** Ensure your BigQuery tables are populated with data. The schema should ideally match the default schema provided in `discovery-engine.tf` or be adapted as needed. The Data Connector will periodically refresh data from the BigQuery table into Vertex AI Search based on the `refresh_interval` (currently daily).

## Application Layer

The Gemini Enterprise application itself is NOT created by this Terraform. The "gem for Gov CLI" tool is expected to be used to:

1.  Create the Gemini Enterprise application instance.
2.  Prompt the user for the Data Store ID(s) (from the Terraform outputs of this module) to connect to the application.
3.  Support single Data Store (standard search) or multiple Data Stores (blended search).
4.  Apply necessary feature flags and configurations (like disabling analytics) to the application, which are not yet fully supported in the Terraform provider for the Search Engine resource.

## Outputs

This module provides outputs such as:

*   `gcs_discovery_engine_data_stores`: A map of the created GCS-based Data Store names.
*   `gcs_agent_space_data_buckets`: A map of the created GCS bucket names.
*   `bq_discovery_engine_data_store_ids`: A map of the Data Store IDs managed by the BigQuery connectors.

These outputs are used by the "gem for Gov CLI" tool.