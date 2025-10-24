# Vertex AI Search (Discovery Engine) for Agent Space

This Terraform module provisions the necessary Google Cloud infrastructure to power Vertex AI Search capabilities for an Agent Space or Gemini Enterprise application.

## Resources Created

*   **KMS:** Customer-Managed Encryption Keys (CMEK) for securing data at rest.
*   **GCS:** A bucket for staging data to be indexed by Vertex AI Search.
*   **BigQuery:** A sample dataset and table to demonstrate the BigQuery Connector.
*   **Vertex AI Search:**
    *   Data Store and Search Engine for data imported from GCS.
    *   Data Connector, Data Store, and Search Engine for data from BigQuery.
    *   ACL Configuration for access control.
*   **Service Enablement:** Ensures required APIs are enabled.

## How it Works

This module sets up the backend components. Your application will interact with the `google_discovery_engine_search_engine` resources created here by using their respective Engine IDs to perform search queries.

## Usage

1.  Create a `terraform.tfvars` file in this directory to provide values for the variables defined in `variables.tf` (e.g., `main_project_id`, `region`, `geolocation`).
2.  Initialize Terraform: `terraform init`
3.  Review the plan: `terraform plan`
4.  Apply the configuration: `terraform apply`

The outputs will provide the names and IDs of the created Search Engines, which you can then use to configure your application.

## Creating the Application Layer

This Terraform code only sets up the *backend* infrastructure. To build the user-facing application:

1.  **Vertex AI Search UI (Console):** Use the Google Cloud Console under Vertex AI Search. You can create an automatic Gemini Enterprise webapp, or you can call the APIs directly. In the configuration, you will need to select the discovery-engine IDs created by this Terraform to get a ready-made, testable UI and embeddable widget.
2.  **Custom Application:** A user could also build their own web, mobile, or backend application using Google Cloud client libraries or REST APIs to query the Vertex AI Search API (us-discoveryengine.googleapis.com), using the Search Engine IDs provided in the Terraform outputs.

Custom Application: 

## Integration with Gemini Enterprise

Gemini Enterprise uses the Vertex AI Search backend created by this module as a grounded knowledge source. Gemini Enterprise connects to the Search Engine IDs, sends user queries to Vertex AI Search, and then uses its LLM capabilities to synthesize, summarize, and provide intelligent, conversational answers based on the search results.
