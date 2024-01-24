create:
	eksctl create cluster spring-petclinic

	eksctl create iamserviceaccount \
    --name ebs-csi-controller-sa \
    --namespace kube-system \
    --cluster spring-petclinic \
    --role-name AmazonEKS_EBS_CSI_DriverRole \
    --role-only \
    --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
    --approve

	ACCOUNT_ID=`aws sts get-caller-identity --output text --query "Account"` && \
	eksctl create addon --name aws-ebs-csi-driver --cluster my-cluster \
	--service-account-role-arn arn:aws:iam::$(ACCOUNT_ID):role/AmazonEKS_EBS_CSI_DriverRole --force

	helm install postgres oci://registry-1.docker.io/bitnamicharts/postgresql

	kubectl apply -f main-app.yaml
destroy:
	eksctl delete cluster -n spring-petclinic


