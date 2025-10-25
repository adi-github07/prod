
CICD Devsecops project

My first complete end to end CICD and Devsecops best pratices project

**First run  the terraform script**
1. It will create a VPC,2 subnets,attaches a internet gateway,route table is attached to subnets so that it connects to internet.
2. Then it creates aws_eks_clutser which is control plane  and aws_eks_node_group for worker nodes
3. Once it is done run the following command so that EKS is configured

   ```bash
   aws eks --region <region> update-kubeconfig --name <cluter-name>
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
   --cluster <cluster-name> \
   --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
   --approve \
   --override-existing-serviceaccounts
   ```

4.Add add-ons so that AWS EBS CSI driver lets Kubernetes automatically create, attach, and manage EBS volumes.
   ```bash
   kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/ecr/?ref=release-1.11"
   ```

5.Apply RBAC manifests (Role, RoleBinding, ClusterRole, ClusterRoleBinding) to set proper permissions for the driver and other components: 

6.Install nginx ingress controller as it acts as entrypoint to EKS
Create ingress-nginx  and creates a load balancer type service (ELB) 
  ```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
   ```

7. Install Cert-Manager
Cert-Manager automates the creation and renewal of TLS/SSL certificates.
It works together with the Ingress Controller to enable secure (HTTPS) traffic for your applications.
  ```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.yaml
   ```
8.We create a Kubernetes Service Account with a secret token so that Jenkins on EC2 can securely authenticate and interact with our EKS cluster, while RBAC ensures it only has the permissions it needs.

9.Now in another EC2 instance install Java and jenkins which is on <aws ip>:8080 and is accessible 

10.Add and install all plugins for accessing sonarqube,docker,kubernetes

11. Then using pipeline add the JenkinsFile script and add sonarqube token and url in the jenkins so that it can access and run the scan for code quality check .static analysis,code smells,duplication etc..

12.After all pods are deployed get the ELB domain and run the command
  ```bash
nslookup <ELB>
   ```

The above helps to verify IP and ELB.By using ELB, we create a Cname record where we add the ELB address to our DNS provider