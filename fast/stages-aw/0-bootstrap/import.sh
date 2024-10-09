#!/bin/bash

export ORG=$(gcloud organizations list | grep -v 'DISPLAY_NAME' | awk '{print $2}')
gcloud resource-manager org-policies list --organization=$ORG | grep 'SET' | awk -F '[/ ]' '{print $2}'  | xargs -n 1 -I {} terraform import "module.organization.google_org_policy_policy.default[\"{}\"]" "organizations/$ORG/policies/{}"