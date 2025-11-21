# Required IAM Permissions

This document outlines the necessary Identity and Access Management (IAM) permissions required to successfully run the `deploy.sh` script and the associated Terraform configurations for the Gemini Enterprise Blueprint.

## Overview

The deployment process involves interacting with Google Cloud resources across multiple stages. The user running the deployment must have sufficient privileges to:
1.  **Run the Deployment Script:** Access Cloud Storage for state management and query project metadata.
2.  **Discover Shared VPC Resources:** List networks and subnets in the Shared VPC Host Project (if applicable).
3.  **Provision Infrastructure (Stage 0):** Create networking, load balancing, and security resources.
4.  **Deploy Application (Stage 1):** Deploy Cloud Run services, manage Service Accounts, and configure secrets.

## 1. Deployment Script Prerequisites (`deploy.sh`)

The script itself performs pre-flight checks and state management.

**Required Roles:**
*   `roles/storage.admin` (or `roles/storage.objectAdmin` + `roles/storage.legacyBucketReader`) on the State Bucket.
*   `roles/browser` (or `roles/viewer`) on the Target Project.

**Specific Permissions:**
*   `storage.buckets.get`
*   `storage.objects.get`
*   `storage.objects.create`
*   `storage.objects.delete`
*   `resourcemanager.projects.get`
*   `serviceusage.services.list` (to check enabled APIs)

## 2. Shared VPC Discovery

If you are using a Shared VPC, the deployment user needs permissions to discover and use resources in the **Host Project**.

**Required Roles on Host Project:**
*   `roles/compute.networkViewer` (Minimum for discovery)
*   `roles/compute.networkUser` (Required for attaching resources to the subnets)

**Specific Permissions:**
*   `compute.projects.get` (on Host Project)
*   `compute.networks.list` (on Host Project)
*   `compute.subnetworks.list` (on Host Project)
*   `compute.subnetworks.listUsable` (on Host Project)
*   `compute.subnetworks.use` (on the specific subnets)

> **Note:** The fallback discovery mechanism specifically relies on `compute.subnetworks.list` to query the Host Project directly if `list-usable` returns empty results.

## 3. Terraform Stage 0: Infrastructure

Stage 0 provisions the core networking and security infrastructure.

**Required Roles on Target Project:**
*   `roles/compute.admin` (Network, LB, Firewall management)
*   `roles/iap.admin` (IAP configuration)
*   `roles/resourcemanager.projectIamAdmin` (Setting IAM policies)
*   `roles/secretmanager.admin` (If creating secrets)
*   `roles/dns.admin` (If managing Cloud DNS)

**Specific Permissions:**
*   `compute.networks.*`
*   `compute.subnetworks.*`
*   `compute.firewalls.*`
*   `compute.routers.*`
*   `compute.addresses.*`
*   `compute.forwardingRules.*`
*   `compute.regionBackendServices.*`
*   `compute.regionHealthChecks.*`
*   `compute.regionNetworkEndpointGroups.*`
*   `compute.sslCertificates.*`
*   `compute.targetHttpProxies.*`
*   `compute.urlMaps.*`
*   `compute.globalAddresses.*`
*   `compute.securityPolicies.*`
*   `iap.brands.*`
*   `iap.identityAwareProxyClients.*`
*   `resourcemanager.projects.setIamPolicy`

## 4. Terraform Stage 1: Application

Stage 1 deploys the Gemini Enterprise application on Cloud Run.

**Required Roles on Target Project:**
*   `roles/run.admin` (Cloud Run management)
*   `roles/iam.serviceAccountAdmin` (Service Account creation)
*   `roles/artifactregistry.admin` (If managing repositories)
*   `roles/secretmanager.admin` (Secret management)
*   `roles/serviceusage.serviceUsageAdmin` (Enabling APIs)

**Specific Permissions:**
*   `run.services.*`
*   `run.services.setIamPolicy`
*   `iam.serviceAccounts.create`
*   `iam.serviceAccounts.setIamPolicy`
*   `iam.serviceAccounts.actAs`
*   `artifactregistry.repositories.*`
*   `secretmanager.secrets.*`
*   `secretmanager.versions.add`
*   `serviceusage.services.enable`

## Summary of Recommended Roles

For a smooth deployment experience, we recommend granting the following roles to the deployment user (or Service Account):

**On the Target Project:**
*   `roles/owner` (Simplest, covers most requirements)
*   OR
*   `roles/editor`
*   `roles/compute.networkAdmin`
*   `roles/iap.admin`
*   `roles/run.admin`
*   `roles/secretmanager.admin`
*   `roles/resourcemanager.projectIamAdmin`

**On the Shared VPC Host Project (if applicable):**
*   `roles/compute.networkUser`
*   `roles/compute.networkViewer`

**On the Terraform State Bucket:**
*   `roles/storage.admin`
