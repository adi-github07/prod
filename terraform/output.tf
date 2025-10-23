output "cluster_id" {
  value = aws_eks_cluster.cicd.id
}

output "node_group_id" {
  value = aws_eks_addon.ebs_csi_driver.id
}

output "vpc_id" {
  value = aws_vpc.cicd_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.cicd_subnet.*.id
}