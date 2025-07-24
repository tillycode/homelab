## Steps to Bootstrap a RKE2 cluster

1. Install rke2-hasee.bootstrap on the first server node
2. Copy rke2 kubeconfig from the first server node to the local machine. Change the IP
3. Run ` helm upgrade --install kube-vip kube-vip/kube-vip --namespace kube-system -f k8s/kube-vip/values.yaml`. Change the kubeconfig IP to vip address.
4. Save rke2 token to the in-repo secret file
5. Install rke2-hasee.server on the other server nodes
