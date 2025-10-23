
CICD Devsecops project

My first complete end to end CICD and Devsecops best pratices project

**First run  the terraform script**
1. It will create a VPC,2 subnets,attaches a internet gateway,route table is attached to subnets so that it connects to internet.
2. Then it creates aws_eks_clutser which is control plane  and aws_eks_node_group for worker nodes
3. Once it is done run the following command so that EKS is configured

```bash
aws eks --region <region> update-kubeconfig --name <cluter-anme>
```
        
3. Now associate iam oidc with eks so that  it connects and communicates  with ebs by running the below command 

```bash
eksctl utils associate-iam-oidc-provider \
  --region <region> \
  --cluster <cluter-anme> \
  --approve
```

 Create IAM Service Account for EBS CSI Driver
 ```bash
eksctl create iamserviceaccount \
  --region ap-south-1 \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster devopsshack-cluster \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --override-existing-serviceaccounts
```

4.Add add-ons so that AWS EBS CSI driver lets Kubernetes automatically create, attach, and manage EBS volumes.
 ```bash
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/ecr/?ref=release-1.11"
```

5.Apply RBAC manifests (Role, RoleBinding, ClusterRole, ClusterRoleBinding) to set proper permissions for the driver and other components: 


