## Introduction to Google Cloud IDS
Google Cloud Intrusion Detection System (IDS) is a network security service designed to provide comprehensive threat detection and monitoring for workloads deployed in Google Cloud. It leverages cutting-edge technology to identify malicious activity, unauthorized access, and other potential security threats in real time, enabling organizations to protect their applications and data more effectively.

Google Cloud IDS is an essential tool for organizations aiming to strengthen their security framework in the cloud. By offering robust threat detection and actionable insights, it empowers security teams to mitigate risks effectively and ensure a secure cloud environment.

## Cloud IDS Blueprint

This blueprint demonstrates how to deploy a cloud IDS service into a network project on Google Cloud Platform (GCP). This blueprint creates 4 different resources:

<mark>IDS private IP address:</mark> Allocates a private IP range for VPC peering.<br />
<mark>Private VPC connection:</mark>  Establishes a private VPC connection for service networking.<br />
<mark>IDS endpoint:</mark>  Creates a Cloud IDS (Intrusion Detection System) endpoint.<br />
<mark>Cloud IDS packet mirroring:</mark>  Configures a packet mirroring policy to send traffic to the IDS endpoint for analysis.<br />

For more information, pleade look at the the Cloud IDS [Overview](https://cloud.google.com/intrusion-detection-system/docs/overview).

## Disclaimer
- The present GCP Terraform Module in this project is set up and intended to be implemented in a FEDRAMP High environment using the Assured Workloads within the Google Cloud Platform (GCP) organization.

## Deployment Steps

You should see this README and some terraform files.
1. Run cp terraform.tfvars.sample terraform.tfvars to copy the sample variables to your own tfvars file.

2. Update the variables as necessary in your tfvars file.
3. The usual terraform commands will do the work. To provision this example, run the following from within this directory:

```terraform init ```<br />
```terraform plan``` to see the infrastructure plan<br />
```terraform apply``` to apply the infrastructure build<br />
```terraform destroy``` to destroy the built infrastructure<br />

## Verifciation of a succesful deployment

Use GCP console to verify if the resources have been created.

```To verifiy the creation of Cloud IDS: Go to IDS Endpoints``` <br />
```To verify cloud packet mirroring: Go to IDS Endpoints ---> Listed under attached policies``` <br />
```To verify IDS private IP adress: Go to VPC network ---> Private Service Access``` <br />
```To verify IAM roles: Go to IAM and search for project. See if those roles are listed``` <br />
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [ids_name](variables.tf#L1) | Name for ids. | <code>string</code> | ✓ |  |
| [landing_project_id](variables.tf#L12) | The Landing Project ID. | <code>string</code> | ✓ |  |
| [network](variables.tf#L17) | VPC network. | <code>string</code> | ✓ |  |
| [project](variables.tf#L34) | The GCP Project name. | <code>string</code> | ✓ |  |
| [region](variables.tf#L39) | GCP Region to deploy into. | <code>string</code> | ✓ |  |
| [ids_private_ip_prefix_length](variables.tf#L6) | The length of the IDS Private IP Prefix. | <code>number</code> |  | <code>24</code> |
| [packet_mirroring_policy_name](variables.tf#L22) | Name of packet mirror policy. | <code>string</code> |  | <code>&#34;cnap-packet-mirror&#34;</code> |
| [prefix](variables.tf#L28) | Prefix for naming resources in this blueprint. | <code>string</code> |  | <code>&#34;cnap&#34;</code> |
| [severity](variables.tf#L44) | Impact of an incident on a system. | <code>string</code> |  | <code>&#34;MEDIUM&#34;</code> |
| [subnet](variables.tf#L50) | Subnet for deploying the instances. | <code>string</code> |  | <code>&#34;default-us-east4&#34;</code> |
| [subnet_list](variables.tf#L56) | Subnet list to monitor with Cloud IDS. | <code>list&#40;any&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [ids_name](outputs.tf#L1) | The name of the Cloud IDS instance. |  |
| [ids_private_ip_range_name](outputs.tf#L6) | The private IP range name for the IDS. |  |
| [packet_mirroring_policy_name](outputs.tf#L11) | The name of the packet mirroring policy. |  |
<!-- END TFDOC -->
