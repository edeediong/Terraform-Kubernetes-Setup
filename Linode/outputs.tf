output "kube_config" {
   value = linode_lke_cluster.siteops.kubeconfig
   sensitive = true
   description = "This is the KUBECONFIG for the cluster created"
}

output "api_endpoints" {
   value = linode_lke_cluster.siteops.api_endpoints
   sensitive = true
   description = "The API endpoints to check status of the cluster"
}

output "status" {
   value = linode_lke_cluster.siteops.status
   description = "Displays status of the cluster"
}

output "id" {
   value = linode_lke_cluster.siteops.id
   description = "The ID of the cluster"
}

output "pool" {
   value = linode_lke_cluster.siteops.pool
   sensitive = true
   description = "The pool details of the cluster"
}

output "loadbalancer_ip" {
   value = kubernetes_ingress.my_new_ingress.load_balancer_ingress[0].ip
}