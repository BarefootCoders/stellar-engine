#CIS Compliance Benchmark 2.1
resource "null_resource" "audit_config" {
  provisioner "local-exec" {
    command = <<EOF
    gcloud projects get-iam-policy ${var.project_id} > tmp_project_policy.yaml
    printf "auditConfigs: \n- auditLogConfigs: \n  - logType: DATA_WRITE \n  - logType: DATA_READ \n  service: allServices" >> tmp_project_policy.yaml
    echo y | gcloud projects set-iam-policy ${var.project_id} tmp_project_policy.yaml 
    EOF
  }
}