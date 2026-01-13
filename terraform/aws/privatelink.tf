# PrivateLink endpoint service for Databricks
resource "aws_vpc_endpoint_service" "this" {
  acceptance_required         = true
  network_load_balancer_arns  = [aws_lb.this.arn]
  allowed_principals          = local.allowed_principals

  tags = local.tags
}
