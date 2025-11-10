# Gemini Enterprise on GCP - FedRAMP High (gemini-stage-0)

This blueprint deploys the necessary infrastructure to host a Gemini Enterprise application on Google Cloud Platform, adhering to FedRAMP High compliance standards. It provisions a secure environment with networking, load balancing, access controls, and data stores for Vertex AI Search.

## Prerequisites & Manual Steps Before Apply

Before applying this Terraform module, ensure the following manual steps and configurations are completed:

1.  **Chrome Enterprise Premium:**
    *   Manually enable and configure Chrome Enterprise Premium within the Google Cloud Console for your organization. This is required for certain contextual awareness policies and configurations, adding to your zero-trust security posture.

2.  **Google Workspace Groups for IAP:**
    *   In the Google Workspace Admin Console, create the following groups:
        *   `gcp-agentspace-admins@<your-domain>`
        *   `gcp-agentspace-users@<your-domain>`
    *   Add the necessary users to these groups who will need access to the Gemini Enterprise application through the Identity-Aware Proxy.

3.  **OAuth Consent Screen:**
    *   In the Google Cloud Console, navigate to "APIs & Services" > "OAuth consent screen".
    *   Configure the OAuth consent screen. Select "Internal" user type if only for your organization. Provide an app name (e.g., "Gemini Enterprise IAP"), user support email, and developer contact information.

**IMPORTANT:** This blueprint is designed to be deployed in a **FedRAMP High GCP project**, to ensure a clean slate for meeting stringent FedRAMP High security and compliance requirements.

## Overall Architecture

The blueprint sets up the following key components:

1.  **Networking:** A dedicated Virtual Private Cloud (VPC) with subnets
    *   Private Google Access subnet
    *   Regional Managed Proxy subnet (for the regional https load balancer)
    *   Regional Network Endpoint Group (INTERNET_FQDN_PORT) pointing to `vertexaisearch.cloud.google.com`.

2.  **Load Balancing:**
    *   **Stage 0 (This Blueprint):** Deploys a Regional External HTTP Load Balancer to direct all HTTP traffic to HTTPS.
    *   **Stage 1 (gemini-stage-1):** After you upload a Google-managed certificate and launch the Gemini Enterprise application using the `gem4gov` CLI, the `gemini-stage-1` blueprint will configure the main Regional External HTTPS Load Balancer. This will include the frontend configuration, certificate attachment, and routing rules to the Gemini Enterprise application instance.

3.  **Security:**
    *   **Identity-Aware Proxy (IAP):** Enabled on the backend service in `load_balancer.tf`. IAP is configured to use pre-defined Access Context Manager levels to enforce contextual awareness policies for the prerequisite Google Workspace groups:
        *   `gcp-agentspace-admins@<your-domain>`: Requires the `strict_device` policy. This level enforces:
            *   US-based access.
            *   Access only during business hours (Mon-Fri, 7 AM - 9 PM ET).
            *   Access expiring at the end of 2026.
            *   Device must be Corp-owned, encrypted, have a screen lock, and be running macOS or Windows.
        *   `gcp-agentspace-users@<your-domain>`: Requires the `moderate_device` policy. This level enforces:
            *   US-based access.
            *   Access only during business hours (Mon-Fri, 7 AM - 9 PM ET).
            *   Access expiring at the end of 2026.
    *   **Chrome Enterprise Premium & Managed Browsers:** To meet the device policy requirements (especially for `strict_device`), users will typically need to use Chrome browsers managed by your Google Workspace organization through Chrome Enterprise Premium. This allows your organization to enforce security settings, extensions, and report on browser status, which feeds into the Access Context Manager device policy evaluation. Configuration is done within the Google Workspace Admin Console under Chrome Browser management.
    *   **Cloud Armor:** Regional security policy to allow US traffic and deny others.
    *   **Organization Policies:** Enforce security constraints.
    *   **IAM policies and Service Accounts:** Follow the principle of least privilege.
    *   **Access Context Manager:** Policies defined in `access_policy.tf` for geo-location, time, and device attributes are bound to IAP in `load_balancer.tf`.

4.  **Data Stores:** CMEK-encrypted GCS buckets and BigQuery datasets for Vertex AI Search, managed by the `discovery-engine` module.

## Deployment Steps

1.  Navigate to `blueprints/fedramp-high/gemini-enterprise/gemini-stage-0/`.
2.  Create a `terraform.tfvars` file based on the `terraform.tfvars.sample` sample, filling in all required values.
3.  Initialize Terraform: `terraform init`
4.  Review the plan: `terraform plan`
5.  Apply the configuration: `terraform apply`
6.  Complete the "Manual Steps After Apply".

## Manual Steps After Apply

1.  **Populate Data Stores:**
    *   **GCS:** Upload your documents to the GCS buckets created by Terraform (see outputs `gcs_agent_space_data_buckets`).
    *   **BigQuery:** Ensure your BigQuery tables (defined in `var.bq_data_store_configs`) are populated with data.

2.  **Import Data to Discovery Engine:**
    *   **GCS:** Manually trigger data import from GCS to the Discovery Engine data stores. Example for one Data Store:
        ```bash
        # Obtain the Data Store ID from Terraform outputs gcs_discovery_engine_data_stores
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
    *   **BigQuery:** The Data Connector will periodically refresh data. Check the status in the console.

3.  **Proceed to gemini-stage-1:** Once this stage is fully applied and manual steps are completed, you will run the `gem4gov` CLI to create the application engine, and then deploy the `gemini-stage-1` blueprint to configure the main load balancer frontend & routing rules to your customer instance.

## Outputs

This module provides outputs such as:

*   `gcs_discovery_engine_data_stores`: A map of the created GCS-based Data Store names.
*   `gcs_agent_space_data_buckets`: A map of the created GCS bucket names.
*   `bq_discovery_engine_data_store_ids`: A map of the Data Store IDs managed by the BigQuery connectors.
*   `gemini_enterprise_ip_address`: The reserved static IP for the load balancer.

These outputs are used by the "gem for Gov CLI" tool and the `gemini-stage-1` blueprint.