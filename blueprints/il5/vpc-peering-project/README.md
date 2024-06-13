# Google Virtual Private Cloud (VPC) Project
This blueprint contains all the necessary Terraform modules to build and deploy a Virtual Private Cloud (VPC) and allows creation and management of VPC networks including VPC Peering.


## Introduction
Google Cloud VPC is global, scalable, and flexible. It provides networking for Compute Engine VM, GKE containers, and the App Engine environment.

1. Enforce the Best Practices for the Google VPC with Subnet CIDR, VPC Peering to the Host Main Project
2. The CIDR's are divided starting from 10.200.12.0/23, Subnet A = 10.200.12.0/25, Subnet B = 10.200.12.0/25, Subnet C = 10.200.12.0/25
3. The VPC is created and it is Peered/Connected to Another Main Landing VPC that is in another Project

## Pre-requisite
1. The Principal (user or group) must have GCP VPC Networking Admin permission at the GCP Level.
2. Have access to the GCP Project ID
3.  You will need an existing [project](https://cloud.google.com/resource-manager/docs/creating-managing-projects) with [billing enabled](https://cloud.google.com/billing/docs/how-to/modify-project) and a user with the “Project owner” [IAM](https://cloud.google.com/iam) role on that project. __Note__: to grant a user a role, take a look at the [Granting and Revoking Access](https://cloud.google.com/iam/docs/granting-changing-revoking-access#grant-single-role) documentation.


## How to deploy the Terraform Code. The Deployment Steps
You should see this README and some terraform files.
1. Update the Variables in the variables.tf 
2. There is a sample ```terraform.tfvars.sample``` available as well.
3. Although each use case is somehow built around the previous one they are self-contained so you can deploy any of them at your will. The usual terraform commands will do the work:

```bash
terraform init
terraform plan
terraform apply
```

It will take a few minutes. When complete, you should see an output stating the command completed successfully, a list of the created resources.

The Output will look like following
```
Plan: 8 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + local_network_peering         = {
      + export_custom_routes                = true
      + export_subnet_routes_with_public_ip = true
      + id                                  = (known after apply)
      + import_custom_routes                = true
      + import_subnet_routes_with_public_ip = null
      + name                                = (known after apply)
      + network                             = "https://www.googleapis.com/compute/v1/projects/yyyyyyy/global/networks/xxxxxxx"
      + peer_network                        = (known after apply)
      + stack_type                          = "IPV4_ONLY"
      + state                               = (known after apply)
      + state_details                       = (known after apply)
      + timeouts                            = null
    }
  + peer_network_peering          = [
      + {
          + export_custom_routes                = true
          + export_subnet_routes_with_public_ip = true
          + id                                  = (known after apply)
          + import_custom_routes                = true
          + import_subnet_routes_with_public_ip = null
          + name                                = (known after apply)
          + network                             = (known after apply)
          + peer_network                        = "https://www.googleapis.com/compute/v1/projects/yyyyyyy/global/networks/xxxxxxx"
          + stack_type                          = "IPV4_ONLY"
          + state                               = (known after apply)
          + state_details                       = (known after apply)
          + timeouts                            = null
        },
    ]
  + subnet_ipv6_external_prefixes = {
      + "us-east4/subnet-xxxxxx-a"                = (known after apply)
      + "us-east4/subnet-xxxxxx-no-pga-b"         = (known after apply)
      + "us-east4/subnet-xxxxxx-secondary-ranges" = (known after apply)
    }
  + subnet_regions                = {
      + "us-east4/subnet-xxxxxx-a"                = "us-east4"
      + "us-east4/subnet-xxxxxx-no-pga-b"         = "us-east4"
      + "us-east4/subnet-xxxxxx-secondary-ranges" = "us-east4"
    }
  + subnet_secondary_ranges       = {
      + "us-east4/subnet-xxxxxx-a"                = {}
      + "us-east4/subnet-xxxxxx-no-pga-b"         = {}
      + "us-east4/subnet-xxxxxx-secondary-ranges" = {
          + a = "x.x.x.x/24"
          + b = "x.x.x.x/24"
        }
    }
  + subnet_self_links             = {
      + "us-east4/subnet-xxxxxx-a"                = (known after apply)
      + "us-east4/subnet-xxxxxx-no-pga-b"         = (known after apply)
      + "us-east4/subnet-xxxxxx-secondary-ranges" = (known after apply)
    }
  + subnets                       = {
      + "us-east4/subnet-xxxxxx-a"                = {
          + creation_timestamp         = (known after apply)
          + description                = "Subnet a simple subnet"
          + external_ipv6_prefix       = (known after apply)
          + fingerprint                = (known after apply)
          + gateway_address            = (known after apply)
          + id                         = (known after apply)
          + internal_ipv6_prefix       = (known after apply)
          + ip_cidr_range              = "x.x.x.x/25"
          + ipv6_access_type           = null
          + ipv6_cidr_range            = (known after apply)
          + log_config                 = []
          + name                       = "subnet-xxxxxx-a"
          + network                    = "vpc-project-xxxxxx"
          + private_ip_google_access   = true
          + private_ipv6_google_access = (known after apply)
          + project                    = "project-name"
          + purpose                    = (known after apply)
          + region                     = "us-east4"
          + role                       = null
          + secondary_ip_range         = []
          + self_link                  = (known after apply)
          + stack_type                 = (known after apply)
          + timeouts                   = null
        }
      + "us-east4/subnet-xxxxxx-no-pga-b"         = {
          + creation_timestamp         = (known after apply)
          + description                = "Subnet b with no PGA"
          + external_ipv6_prefix       = (known after apply)
          + fingerprint                = (known after apply)
          + gateway_address            = (known after apply)
          + id                         = (known after apply)
          + internal_ipv6_prefix       = (known after apply)
          + ip_cidr_range              = "x.x.x.x/25"
          + ipv6_access_type           = null
          + ipv6_cidr_range            = (known after apply)
          + log_config                 = []
          + name                       = "subnet-xxxxxx-no-pga-b"
          + network                    = "vpc-project-xxxxxx"
          + private_ip_google_access   = false
          + private_ipv6_google_access = (known after apply)
          + project                    = "project-name"
          + purpose                    = (known after apply)
          + region                     = "us-east4"
          + role                       = null
          + secondary_ip_range         = []
          + self_link                  = (known after apply)
          + stack_type                 = (known after apply)
          + timeouts                   = null
        }
      + "us-east4/subnet-xxxxxx-secondary-ranges" = {
          + creation_timestamp         = (known after apply)
          + description                = "Subnet c with secondary ranges"
          + external_ipv6_prefix       = (known after apply)
          + fingerprint                = (known after apply)
          + gateway_address            = (known after apply)
          + id                         = (known after apply)
          + internal_ipv6_prefix       = (known after apply)
          + ip_cidr_range              = "x.x.x.x/25"
          + ipv6_access_type           = null
          + ipv6_cidr_range            = (known after apply)
          + log_config                 = []
          + name                       = "subnet-xxxxxx-secondary-ranges"
          + network                    = "vpc-project-xxxxxx"
          + private_ip_google_access   = true
          + private_ipv6_google_access = (known after apply)
          + project                    = "tnbsea-dev-tapand-dev"
          + purpose                    = (known after apply)
          + region                     = "us-east4"
          + role                       = null
          + secondary_ip_range         = [
              + {
                  + ip_cidr_range = "x.x.x.x/24"
                  + range_name    = "a"
                },
              + {
                  + ip_cidr_range = "x.x.x.x/24"
                  + range_name    = "b"
                },
            ]
          + self_link                  = (known after apply)
          + stack_type                 = (known after apply)
          + timeouts                   = null
        }
    }
  + vpc-network                   = {
      + id        = (known after apply)
      + name      = "vpc-project-xxxxxx"
      + self_link = (known after apply)
    }
  + vpc-network-id                = (known after apply)
  + vpc-network-name              = "vpc-project-xxxxxx"
  + vpc-network-self_link         = (known after apply)
  + vpc-network_attachment_ids    = {}
  + vpc-subnet_ids                = {
      + "us-east4/subnet-xxxxxx-a"                = (known after apply)
      + "us-east4/subnet-xxxxxx-no-pga-b"         = (known after apply)
      + "us-east4/subnet-xxxxxx-secondary-ranges" = (known after apply)
    }
  + vpc-subnet_ips                = {
      + "us-east4/subnet-xxxxxx-a"                = "x.x.x.x/25"
      + "us-east4/subnet-xxxxxx-no-pga-b"         = "x.x.x.x/25"
      + "us-east4/subnet-xxxxxx-secondary-ranges" = "x.x.x.x/25"
    }
```

## Verification of a successful deployment for GCP VPC Network

- Go to the GCP VPC Networks in the GCP Console.
![GCP VPC Networks ](./images/vpc1.png?raw=true " GCP VPC Networks ")

- Go to the GCP VPC Networks in the VPC Peering Tab in the GCP Console.
![GCP VPC Networks ](./images/vpc2.png?raw=true " GCP VPC Networks ")


## Cleanup
Once the project is deployed, to ensure clean up, please apply following command.
```bash
terraform destory
```
