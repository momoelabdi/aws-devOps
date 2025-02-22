
# ****** Securing AWS EKS Networking with Security Groups ***********
# -> In the realm of AWS EKS, securing the network traffic to and from the k8s cluster is paramount.
# -> Security groups serve as the first line of diffence, defining the rules that allow 
# -> or deny network traffic to the EKS cluster and worker nodes.

# ****** Default SG ***********
# -> Assign default SG to current VPC
resource "aws_default_security_group" "main" {
  vpc_id = aws_vpc.main.id
}

# ********** EKS cluster SG ********************
# -> The eks SG acts as shield for the control plane,
# -> governing the traffic to the k8s api server,
# -> it's critical for enabling secure communication
# -> between the worker nodes and the controle plane.
resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.cluster_name}-eks-cluster-sg"
  description = "Security group for EKS cluster control plane communication with worker nodes"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "${var.cluster_name}-eks-cluster-sg"
  }
}

# ************* Ingress for worker nodes **************
# -> Allow inbound traffic on port 443 from worker nodes to the control plane,
# -> facilitating k8s API calls.
resource "aws_security_group_rule" "eks_cluster_ingress_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_sg.id
  source_security_group_id = aws_security_group.eks_nodes_sg.id
  description              = "Allow inbound traffic from the worker nodes on the Kubernetes API endpoint port"
}

# ******* Egress to kubelet **********************
# -> Permit the control plane to initiate traffic to the kubelet 
# -> running on each worker node.
resource "aws_security_group_rule" "eks_cluster_engress_kublet" {
  type                     = "egress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_sg.id
  source_security_group_id = aws_security_group.eks_nodes_sg.id
  description              = "Allow control plane to node egress for kubelet"
}

# ************** Worker nodes SG ****************
# -> Worker nodes Security group safeguards the worker nodes.
# -> It control both inbound and outbound traffic to ensure only 
# -> legitimate and secure communication occurs.
resource "aws_security_group" "eks_nodes_sg" {
  name        = "${var.cluster_name}-eks-nodes-sg"
  description = "Security group for all nodes in the cluster"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name                                        = "${var.cluster_name}-eks-nodes-sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# ******** Control plane to Worker node rule **************
# -> Though the cluster has a security goup has an egress rule to the Worker Nodes on the kubelet port 10250, 
# -> the worker nodes security group still has to allow that traffic.
resource "aws_security_group_rule" "worker_node_ingress_kublet" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes_sg.id
  source_security_group_id = aws_security_group.eks_cluster_sg.id
  description              = "Allow control plane to node ingress for kubelet"
}

# ********** Node to Node Communication *************************
# -> Allow nodes to communicate among themselves.
resource "aws_security_group_rule" "worker_node_to_worker_node_ingress_ephemeral" {
  type              = "ingress"
  from_port         = 1025
  to_port           = 65535
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.eks_nodes_sg.id
  description       = "Allow workers nodes to communicate with each other on ephemeral ports"
}

# ********** Egress to the Internet ****************************
#-> Enables nodes to initiate outbound connections to the internet via the NAT Gateway,
#-> vital for pulling container images or reaching external services.
#-> This also covers any other extra egress rules that would be needed,
#-> such as being able to communicate to the control plane on port 443.
resource "aws_security_group_rule" "worker_node_egress_internet" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_nodes_sg.id
  description       = "Allow outbound internet access"
}

# ****************** Core DNS Rules **********************
# -> CoreDNS rules for managing DNS resolution and traffic flow between pods
# -> what is crucial for the stability and performance of the deployed services. 
# -> CoreDNS plays a vital role in this ecosystem, serving as the cluster DNS
# -> service that enables DNS-based service discovery in Kubernetes.
resource "aws_security_group_rule" "worker_node_to_worker_node_ingress_coredns_tcp" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  security_group_id = aws_security_group.eks_nodes_sg.id
  self              = true
  description       = "Allow workers nodes to communicate with each other for coredns TCP"
}

resource "aws_security_group_rule" "worker_node_to_worker_node_ingress_coredns_udp" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  security_group_id = aws_security_group.eks_nodes_sg.id
  self              = true
  description       = "Allow workers nodes to communicate with each other for coredns UDP"
}