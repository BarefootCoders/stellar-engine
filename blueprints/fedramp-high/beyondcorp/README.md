# BeyondCorp Blueprint
This blueprint simplifies the deployment and configuration of BeyondCorp resources in your cloud environment.

## Introduction to BeyondCorp
BeyondCorp is Google Cloud's zero-trust network security framework, enabling secure access to applications and resources without relying on traditional VPNs.

## Disclaimer
- The present GCP Terraform Module in this project is set up and intended to be implemented in a FEDRAMP High environment using the Assured Workdloads within the Google Cloud Platform (GCP) organization.

### Oauth2 Consent Screen

At the Org-level, configure an Oauth2 Consent screen for your project here https://console.cloud.google.com/apis/credentials/consent

It doesn't matter if it's external or internal, so do whatever meets your system requirements. Internal is better for testing.
For test setup, just use all the defaults and don't assign any extra scopes.


Once it's created, create credentials by going to the API&Services -> Credentials. Click on Create Credentials and use "Web Application" as an application type. Once Credentials are created, save the oauth_client_id and oauth_client_secret into your terraform.tfvars.

### Access Policy ID number

To get Access Policy ID number, run the following commmand:

gcloud access-context-manager policies list

The name is the ID.
## Sucessful Deployment

Use GCP Console to verify if resources were created

To check endpoint: Go to Access Context Manager (NOTE: This is created at the ORG level)
To check IAP backend: Go to Network Services -> Load balancer -> Backends
To check if IAP is attached to user: Go to IAMs and search for User. See if IAP-secured Web App User is listed
To check if iap.googleapis.com, cloudresourcemanager.googleapis.com and accesscontextmanager.googleapis.com is attached to project: Go to IAM and search for project. See if those roles are listed.
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [endpoint_name](variables.tf#L1) | Name for endpoint. | <code>string</code> | ✓ |  |
| [iap_user_email](variables.tf#L6) | User or group email for IAP access. | <code>string</code> | ✓ |  |
| [oauth_client_id](variables.tf#L11) | OAuth Client ID for IAP. | <code>string</code> | ✓ |  |
| [oauth_client_secret](variables.tf#L16) | OAuth Client Secret for IAP. | <code>string</code> | ✓ |  |
| [organization_id](variables.tf#L21) | GCP Organization ID. | <code>string</code> | ✓ |  |
| [policy_title](variables.tf#L26) | Title for the Access Context Manager Policy. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L31) | GCP Project ID. | <code>string</code> | ✓ |  |
| [region](variables.tf#L36) | Region for deployment. | <code>string</code> | ✓ |  |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [endpoint_name](outputs.tf#L1) | Name of the endpoint that was created. |  |
<!-- END TFDOC -->
