#!/bin/bash

echo "--- Verifying Deployment Service Account Status ---"
echo ""

# Discover the Infrastructure-as-Code (IaC) core project
IAC_PROJECT=$(gcloud projects list --filter="projectId~'-prod-iac-core-0$'" --format="value(projectId)")

# Check if a unique project was found
if [ -z "$IAC_PROJECT" ]; then
  echo "⚠️ WARNING: No IaC core project found ending in '-prod-iac-core-0'."
  exit 1
elif [ $(echo "$IAC_PROJECT" | wc -l) -ne 1 ]; then
  echo "⚠️ WARNING: Multiple possible IaC core projects found. Please verify manually:"
  echo "$IAC_PROJECT"
  exit 1
fi

echo "✅ Found IaC Core Project: $IAC_PROJECT"

# Find and check the status of each key service account
SA_LIST=$(gcloud iam service-accounts list --project="$IAC_PROJECT" \
  --filter="email ~ '(bootstrap-0|resman-0|prod-resman-net-0|security-0)@'" \
  --format="value(email)")

if [ -z "$SA_LIST" ]; then
    echo "⚠️ WARNING: No standard deployment service accounts found in $IAC_PROJECT."
else
    for sa in $SA_LIST; do
      STATUS=$(gcloud iam service-accounts describe "$sa" --project="$IAC_PROJECT" --format="value(disabled)")
      if [ "$STATUS" == "True" ]; then
        echo "✅ SUCCESS: $sa is disabled."
      else
        echo "❌ FAILED: $sa is still enabled."
      fi
    done
fi

echo ""
echo "--- Verification Complete ---"
