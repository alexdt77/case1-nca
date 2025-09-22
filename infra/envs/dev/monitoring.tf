data "aws_iam_policy_document" "amp_write" {
  statement {
    actions   = ["aps:RemoteWrite","aps:QueryMetrics","aps:GetSeries","aps:GetLabels","aps:GetMetricMetadata"]
    resources = [aws_prometheus_workspace.main.arn]
  }
}
resource "aws_iam_policy" "amp_write" {
  name   = "ecs-amp-remote-write"
  policy = data.aws_iam_policy_document.amp_write.json
}
resource "aws_iam_role_policy_attachment" "task_amp_write" {
  role       = aws_iam_role.task.name   #bestaande ECS task role
  policy_arn = aws_iam_policy.amp_write.arn
}
