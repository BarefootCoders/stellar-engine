#!/usr/bin/env bash

# Assign Organization ID
ORG=$(gcloud organizations list --format='value(ID)')
if [[ -z "${ORG}" ]]; then
  echo "Error: Failed to get organization ID." >&2
  exit 1
fi

# Import Organization Policies - get all existing policies
policies=$(gcloud resource-manager org-policies list \
  --organization="${ORG}" \
  --format='value(constraint)' 2>/dev/null)

if [[ -z "${policies}" ]]; then
  echo "No existing organization policies found to import. This is normal for a fresh deployment."
else
  echo -e "Importing policies...\n"

  failed_imports=()

  # Policy Iteration
  while IFS= read -r constraint_path; do
    constraint_name=${constraint_path##*/}
    constraint_self_link="organizations/${ORG}/policies/${constraint_name}"

    # Check Policy State
    if terraform state show "module.organization.google_org_policy_policy.default[\"${constraint_name}\"]" > /dev/null 2>&1; then
      # Skip Import
      echo "${constraint_name} already managed, skipping import."
    else

      # Attempt Import
      if ! terraform import \
        "module.organization.google_org_policy_policy.default[\"${constraint_name}\"]" \
        "${constraint_self_link}"; then
        echo "Error: terraform import failed for constraint: ${constraint_name}" >&2
        failed_imports+=("${constraint_name}")
      fi
    fi
  done <<< "$policies"

  if [[ ${#failed_imports[@]} -gt 0 ]]; then
    echo -e "\nError: The following organizational policies failed to import:" >&2
    for failed_policy in "${failed_imports[@]}"; do
      echo "- ${failed_policy}" >&2
    done
    exit 1
  else
    echo -e "\nOrganization Policy import operation is complete!"
  fi
fi
