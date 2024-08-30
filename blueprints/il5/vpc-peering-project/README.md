# Google Virtual Private Cloud (VPC) Project
This blueprint contains all of the necessary Terraform modules to build and deploy a Virtual Private Cloud (VPC) and allows creation and management of VPC networks including VPC Peering.

## Introduction
Google Cloud VPC is global, scalable, and flexible. It provides networking for Compute Engine VM, GKE containers, and the App Engine environment.

1. Enforce the Best Practices for the Google VPC with Subnet CIDR, VPC Peering to the Host Main Project
2. The CIDR's are divided starting from 10.200.12.0/23, Subnet A = 10.200.12.0/25, Subnet B = 10.200.12.0/25, Subnet C = 10.200.12.0/25
3. The VPC is created and it is Peered/Connected to Another Main Landing VPC that is in another Project

## Pre-requisite
1. The Principal (user or group) must have GCP VPC Networking Admin permission at the GCP Level.
2. Have access to the GCP Project ID
3.  You will need an existing [project](https://cloud.google.com/resource-manager/docs/creating-managing-projects) with [billing enabled](https://cloud.google.com/billing/docs/how-to/modify-project) and a user with the "Project owner" [IAM](https://cloud.google.com/iam) role on that project. __Note__: to grant a user a role, take a look at the [Granting and Revoking Access](https://cloud.google.com/iam/docs/granting-changing-revoking-access#grant-single-role) documentation.

## Disclaimer
- The present GCP Terraform Module in this project is set up and intended to be implemented in an IL5 Impact Level 5 environment using the Assured Workdloads within the Google Cloud Platform (GCP) organization.
- An Assured Workloads and IL5 environments ensures that sensitive data and workloads in GCP adhere to the rigorous security standards mandated by the DoD, making it suitable for government agencies.

## How to deploy the Terraform Code. The Deployment Steps
You should see this README and some terraform files.
1. Update the Variables in the variables.tf
2. There is a sample ```terraform.tfvars.sample``` available as well.
3. Although each use case is somehow built around the previous one they are self-contained so you can deploy any of them at your will. The usual terraform commands will do the work:
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [current_project_id](variables.tf#L17) | Project ID. | <code>string</code> | ✓ |  |
| [project](variables.tf#L29) | GCP Project to deploy into. | <code>string</code> | ✓ |  |
| [region](variables.tf#L34) | GCP Region to deploy into. | <code>string</code> | ✓ |  |
| [secondary_ip_ranges_cidr_a](variables.tf#L39) | The Secondary IP CIDR. | <code>string</code> | ✓ |  |
| [secondary_ip_ranges_cidr_b](variables.tf#L45) | The Secondary IP CIDR. | <code>string</code> | ✓ |  |
| [subnet_prefix_name](variables.tf#L51) | The name of the Subnet Prefix. | <code>string</code> | ✓ |  |
| [subnets_cidr_a](variables.tf#L57) | The Subnet CIDR. | <code>string</code> | ✓ |  |
| [subnets_cidr_b](variables.tf#L63) | The Subnet CIDR. | <code>string</code> | ✓ |  |
| [subnets_cidr_c](variables.tf#L69) | The Subnet CIDR. | <code>string</code> | ✓ |  |
| [vpc_name](variables.tf#L75) | The name of the VPC. | <code>string</code> | ✓ |  |
| [vpc_network_name](variables.tf#L81) | The name of the VPC. | <code>string</code> | ✓ |  |
| [location](variables.tf#L23) | Location of the Shielded Compute VM. | <code>string</code> |  | <code>&#34;us-east4&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [local_network_peering](outputs.tf#L17) | Network peering resource. |  |
| [peer_network_peering](outputs.tf#L22) | Peer network peering resource. |  |
| [subnet_ipv6_external_prefixes](outputs.tf#L27) | Map of subnet external IPv6 prefixes keyed by name. |  |
| [subnet_regions](outputs.tf#L32) | Map of subnet regions keyed by name. |  |
| [subnet_secondary_ranges](outputs.tf#L37) | Map of subnet secondary ranges keyed by name. |  |
| [subnet_self_links](outputs.tf#L42) | Map of subnet self links keyed by name. |  |
| [subnets](outputs.tf#L47) | Subnet resources. |  |
| [vpc-network](outputs.tf#L52) | Network resource. |  |
| [vpc-network-self_link](outputs.tf#L57) | Network self link. |  |
| [vpc-network_attachment_ids](outputs.tf#L62) | IDs of network attachments. |  |
| [vpc-subnet_ids](outputs.tf#L67) | Map of subnet IDs keyed by name. |  |
| [vpc-subnet_ips](outputs.tf#L72) | Map of subnet address ranges keyed by name. |  |
<!-- END TFDOC -->
