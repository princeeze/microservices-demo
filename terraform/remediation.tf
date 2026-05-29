# Kubernetes RBAC so incident-console Cloud Run SA can PATCH deployments (rollout restart).

resource "null_resource" "incident_console_rbac" {
  count = var.incident_console_sa_email != "" ? 1 : 0

  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command     = <<-EOT
      kubectl apply -f - <<'YAML'
      apiVersion: rbac.authorization.k8s.io/v1
      kind: Role
      metadata:
        name: incident-console-deployment-restarter
        namespace: ${var.namespace}
      rules:
        - apiGroups: ["apps"]
          resources: ["deployments"]
          verbs: ["get", "patch"]
      ---
      apiVersion: rbac.authorization.k8s.io/v1
      kind: RoleBinding
      metadata:
        name: incident-console-deployment-restarter
        namespace: ${var.namespace}
      subjects:
        - kind: User
          name: ${var.incident_console_sa_email}
      roleRef:
        apiGroup: rbac.authorization.k8s.io
        kind: Role
        name: incident-console-deployment-restarter
      YAML
    EOT
  }

  depends_on = [
    module.gcloud,
    resource.null_resource.apply_deployment,
  ]
}
