# AMP workspace
resource "aws_prometheus_workspace" "main" {
  alias = "nca-metrics"
}

output "amp_workspace_id"  { value = aws_prometheus_workspace.main.id }
output "amp_workspace_arn" { value = aws_prometheus_workspace.main.arn }
