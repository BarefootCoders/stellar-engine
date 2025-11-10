# Gemini Enterprise for FedRAMP High Blueprint

This blueprint deploys a secure and compliant environment for hosting Gemini Enterprise on Google Cloud Platform, specifically tailored for FedRAMP High requirements. It leverages Vertex AI Search and Discovery Engine. The deployment is divided into two main Terraform stages (`gemini-stage-0` and `gemini-stage-1`) and interacts with the `gem4gov` CLI tool.

## Overall Goal

The primary goal is to provide a turnkey solution for setting up Gemini Enterprise, enabling government customers and other regulated entities to utilize its AI-powered search and assistant capabilities while adhering to strict security and compliance mandates.

## Architecture Overview

The blueprint establishes a robust infrastructure including:

1.  **Dedicated Networking:** A new VPC with private subnets to isolate the environment.
2.  **Data Storage:** CMEK-encrypted Google Cloud Storage (GCS) buckets and BigQuery datasets to securely store data for Discovery Engine.
3.  **Discovery Engine:** Configuration of Discovery Engine data stores, and connectors for GCS and BigQuery.
4.  **Load Balancing:** A Regional External HTTPS Load Balancer to securely expose the Gemini Enterprise application.
5.  **Security Controls:**
    *   **Identity-Aware Proxy (IAP):** Enforces fine-grained access control based on user identity and context.
    *   **Access Context Manager:** Defines and enforces granular access policies based on attributes like user identity, device security status, time of day, and geo-location.
    *   **Cloud Armor:** Provides WAF capabilities and DDoS protection, initially configured to only allow traffic from the US.
    *   **CMEK:** Ensures data at rest in GCS, BigQuery, and Discovery Engine is encrypted with customer-managed keys.
    *   **IAM:** Least privilege IAM roles and service accounts.
    *   **Org Policies:** Enforces organizational constraints to maintain compliance.

## Deployment Stages

### Stage 0: Infrastructure Foundation (`gemini-stage-0`)

This stage provisions the core infrastructure.

**Key Resources Created:**

*   **APIs Enabled (`main.tf`):** Enables necessary APIs such as Discovery Engine, KMS, BigQuery, Storage, IAP, Access Context Manager, etc.
*   **Service Identities (`main.tf`):** Creates service agents for Discovery Engine, Storage, and IAP.
*   **Networking (`network.tf`):**
    *   `google_compute_network`: Creates the `gemini-enterprise-vpc`.
    *   `google_compute_subnetwork`: Creates subnets for general use and a `REGIONAL_MANAGED_PROXY` subnet for the load balancer.
    *   `google_compute_address`: Reserves a static external IP address (`gemini-enterprise-ip`) for the load balancer.
    *   `google_compute_region_network_endpoint_group`: Creates an Internet NEG (`INTERNET_FQDN_PORT`) pointing to `vertexaisearch.cloud.google.com`.
*   **KMS (`discovery-engine.tf`):**
    *   `google_kms_key_ring`: Creates a KeyRing (`gemini-enterprise-cmek-keyring`).
    *   `google_kms_crypto_key`: Creates a CryptoKey (`gemini-enterprise-cmek-key`) for CMEK with a 90-day rotation.
    *   `google_kms_crypto_key_iam_member`: Grants Discovery Engine, GCS, and BigQuery service agents encrypt/decrypt permissions on the CMEK key.
*   **Discovery Engine - Data Stores (`discovery-engine.tf`):**
    *   `google_discovery_engine_cmek_config`: Configures Discovery Engine to use the created CMEK key by default.
    *   `google_storage_bucket`: Creates GCS buckets based on `var.gcs_data_store_names`, encrypted with the CMEK key.
    *   `google_discovery_engine_data_store`: Creates GCS-based Data Stores in Discovery Engine.
    *   `google_bigquery_dataset`: Creates BigQuery datasets based on `var.bq_data_store_configs`, encrypted with the CMEK key.
    *   `google_bigquery_table`: Creates BigQuery tables with a default schema.
    *   `google_discovery_engine_data_connector`: Sets up BigQuery connectors to ingest data into Discovery Engine.
    *   `google_discovery_engine_acl_config`: Configures GSUITE as the IDP for Discovery Engine.
*   **IAM (`iam.tf`):**
    *   `google_project_iam_member`: Assigns roles (`roles/discoveryengine.admin`, `roles/aiplatform.admin`, etc.) to the admin group (`var.admin_group`) and user group (`var.user_group`).
*   **Security Policies:**
    *   **Access Context Manager (`access_policy.tf`):** Defines `google_access_context_manager_access_levels`:
        *   `us`: Restricts to US region.
        *   `time`: Restricts to business hours (Mon-Fri, 7 AM - 9 PM ET).
        *   `expire`: Access expires at the end of 2026.
        *   `lenient_device`: Combines `us`.
        *   `moderate_device`: Combines `us`, `time`, `expire`.
        *   `strict_device`: Combines `us`, `time`, `expire`, and requires screen lock, specific OS (Mac/Windows), device encryption, and corp-owned device.
    *   **Cloud Armor (`cloudarmor.tf`):**
        *   `google_compute_region_security_policy`: Creates a policy (`gemini-enterprise-security-policy`) to allow US traffic and deny all other traffic by default.
    *   **Org Policies (`org-policy.tf`):**
        *   `google_org_policy_policy`: Allows `EXTERNAL_MANAGED_HTTP_HTTPS` load balancer creation.
*   **Load Balancer - HTTP Redirect (`load_balancer.tf`):**
    *   `google_compute_region_backend_service`: Defines the backend service `gemini-enterprise-backend-service` pointing to the Internet NEG, with IAP enabled.
    *   `google_compute_region_url_map`: Sets up an HTTP URL map to redirect all traffic to HTTPS.
    *   `google_compute_region_target_http_proxy`: HTTP proxy for the redirect.
    *   `google_compute_forwarding_rule`: Forwarding rule for port 80 to handle HTTP redirection.

**Prerequisites for Stage 0:**

*   Chrome Enterprise Premium enabled.
*   Google Workspace Groups (`gcp-agentspace-admins`, `gcp-agentspace-users`) created.
*   OAuth Consent Screen configured.
*   A clean FedRAMP High GCP project.

**Manual Steps After Stage 0:**

*   Populate GCS buckets and BigQuery tables with data.
*   Manually trigger data import from GCS to Discovery Engine.

### The `gem4gov` CLI Tool

This CLI tool is run *between* Stage 0 and Stage 1. Its main purpose is to:

*   Authenticate the user and validate permissions.
*   Configure the Identity Provider for Discovery Engine.
*   Register the CMEK key with Discovery Engine.
*   Create/Select Discovery Engine Data Stores.
*   **Provision the Gemini Enterprise Search Engine, linking the data stores.**
*   Apply compliance configurations (e.g., disable non-FedRAMP compliant features).
*   Output the **`config_id`** (Customer ID) required for Stage 1.

### Stage 1: Load Balancer Frontend & IAP (`gemini-stage-1`)

This stage configures the main HTTPS frontend for the application.

**Key Resources Created:**

*   **SSL Certificate (`load_balancer.tf`):**
    *   `data "google_compute_region_ssl_certificate"`: Retrieves the details of the manually uploaded SSL certificate.
*   **Load Balancer - HTTPS Frontend (`load_balancer.tf`):**
    *   `google_compute_region_url_map`: The main URL map (`cnap_url_map`) for HTTPS traffic.
        *   Includes a `route_rules` with `url_rewrite` to direct traffic to the correct Vertex AI Search path, incorporating the `customer_id` from `var.gemini_config_id` (e.g., `/us/home/cid/{customer_id}`).
    *   `google_compute_region_target_https_proxy`: The HTTPS proxy using the uploaded SSL certificate.
    *   `google_compute_forwarding_rule`: The main forwarding rule for port 443, directing traffic to the HTTPS proxy.
*   **IAP IAM Bindings (`load_balancer.tf`):**
    *   `google_iap_web_backend_service_iam_member`: Grants access through IAP to the backend service.
        *   `iap_admin`: Grants `roles/iap.httpsResourceAccessor` to `var.admin_group` with the `strict_device` access level condition.
        *   `iap_user`: Grants `roles/iap.httpsResourceAccessor` to `var.user_group` with the `moderate_device` access level condition.

**Prerequisites for Stage 1:**

*   Stage 0 successfully applied.
*   `gem4gov onboard` CLI process completed, obtaining the `customer_id`.
*   SSL Certificate uploaded to Google Cloud Certificate Manager.
*   DNS 'A' record pointing to the static IP from Stage 0.
*   `terraform.tfvars` file updated with `customer_id`, `ssl_certificate_name`, etc.

## Security and Compliance

*   **Data Residency:** Resources are regionalized, and KMS keys are in the "us" multi-region to meet data residency requirements.
*   **Encryption:** CMEK is used for GCS, BigQuery, and Discovery Engine. Data in transit is protected by HTTPS.
*   **Access Control:** IAP and Access Context Manager provide strong, context-aware access control. Cloud Armor filters traffic at the edge.
*   **Least Privilege:** IAM roles are scoped to minimize permissions.

## Deployment Flow

1.  Meet prerequisites for Stage 0.
2.  Apply Stage 0 Terraform: `terraform init`, `terraform apply`.
3.  Perform manual steps after Stage 0 (data loading).
4.  Run the `gem4gov onboard` CLI to configure the application engine and get the `customer_id`.
5.  Meet prerequisites for Stage 1 (SSL cert, DNS).
6.  Apply Stage 1 Terraform: `terraform init`, `terraform apply`.

This multi-stage approach ensures that infrastructure is in place before application-level configuration and frontend exposure, maintaining a secure and orderly deployment.
