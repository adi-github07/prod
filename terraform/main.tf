provider "aws" {
    region = "ap-south-1"
}

resource "aws_vpc" "cicd_vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "cicd-vpc"
    }
}

resource "aws_subnet" "cicd_subnet" {
    count = 2
    vpc_id            = aws_vpc.cicd_vpc.id
    cidr_block       =  cidrsubnet(aws_vpc.cicd_vpc.cidr_block, 8, count.index)
    availability_zone = element(["ap-south-1a", "ap-south-1b"], count.index )
    map_public_ip_on_launch = true
    tags = {
        Name = "cicd-subnet1"
    }
  
}

resource "aws_internet_gateway" "cicd_igw" {
    vpc_id = aws_vpc.cicd_vpc.id
    tags = {
        Name = "cicd-igw"
    }
    
}

resource "aws_route_table" "cicd_route_table" {
    vpc_id = aws_vpc.cicd_vpc.id
    route {
        cidr_block =  "0.0.0.0/0" 
        gateway_id = aws_internet_gateway.cicd_igw.id
    }
}

resource "aws_route_table_association" "cicd_association" {
    count = 2
    subnet_id      = element(aws_subnet.cicd_subnet[*].id, count.index)
    route_table_id = aws_route_table.cicd_route_table.id
  
}

resource "aws_security_group" "cicd_cluster_sg" {
    vpc_id = aws_vpc.cicd_vpc.id
    name   = "cicd-sg"
    description = "Allow all inbound traffic"
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "cicd_node_sg" {
    vpc_id = aws_vpc.cicd_vpc.id
    name   = "cicd-node-sg"
    description = "Allow all inbound traffic"
    ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/16"]
    }
}

resource "aws_eks_cluster" "cicd" {
    name     = "cicd-cluster"
    role_arn = aws_iam_role.cicd_cluster_role.arn

    vpc_config {
        subnet_ids = aws_subnet.cicd_subnet[*].id
        security_group_ids = [aws_security_group.cicd_cluster_sg.id]
    }


}

resource "aws_eks_addon" "ebs_csi_driver" {
    cluster_name = aws_eks_cluster.cicd.name
    addon_name   = "aws-ebs-csi-driver"
    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "OVERWRITE" 
}

resource "aws_eks_node_group" "cicd" {
    cluster_name    = aws_eks_cluster.cicd.name
    node_group_name = "cicd-node-group"
    node_role_arn   = aws_iam_role.cicd_node_group_role.arn
    subnet_ids      = aws_subnet.cicd_subnet[*].id
    instance_types  = ["t2.medium"]
    scaling_config {
        desired_size = 2
        max_size     = 3
        min_size     = 1
    }
    remote_access {
        ec2_ssh_key = var.ssh_key_name
        source_security_group_ids = [aws_security_group.cicd_node_sg.id]
    }
}

resource "aws_iam_role" "cicd_cluster_role" {
  name = "cicd-eks-cluster-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "cicd_cluster_role_policy" {
    role       = aws_iam_role.cicd_cluster_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  
}

resource "aws_iam_role" "cicd_node_group_role" {
  name = "cicd-eks-node-group-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "cicd_node_group_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.cicd_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}



resource "aws_iam_role_policy_attachment" "cicd_node_group_AmazonEKS_CNI_Policy" {
    role       = aws_iam_role.cicd_node_group_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  
}

resource "aws_iam_role_policy_attachment" "cicd_node_group_AmazonEC2ContainerRegistryReadOnly" {
    role       = aws_iam_role.cicd_node_group_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  
}

resource "aws_iam_role_policy_attachment"  "cicd_eks_node_group_ebs"{
    role       = aws_iam_role.cicd_node_group_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"

}
