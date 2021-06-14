output "client_key" {
  value = azurerm_kubernetes_cluster.k8s_cluster.kube_config.0.client_key
}

output "client_certificate" {
  value = azurerm_kubernetes_cluster.k8s_cluster.kube_config.0.client_certificate
}

output "cluster_ca_certificate" {
  value = azurerm_kubernetes_cluster.k8s_cluster.kube_config.0.cluster_ca_certificate
}

output "cluster_username" {
  value = azurerm_kubernetes_cluster.k8s_cluster.kube_config.0.username
}

output "cluster_password" {
  value = azurerm_kubernetes_cluster.k8s_cluster.kube_config.0.password
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.k8s_cluster.kube_config_raw
  sensitive = true
}

output "host" {
  value = azurerm_kubernetes_cluster.k8s_cluster.kube_config.0.host
}

output "azurerm_user_assigned_identity" {
  value = "${azurerm_kubernetes_cluster.k8s_cluster.name}-agentpool"
}

output "k8s_cluster_name" {
  value = azurerm_kubernetes_cluster.k8s_cluster.name
}

output "k8s_cluster_rg_name" {
  value = azurerm_resource_group.k8s_rg.name
}

output "k8s_cluster_node_resource_group" {
  value = azurerm_kubernetes_cluster.k8s_cluster.node_resource_group
}

output "mi_principal_id" {
  value = azurerm_kubernetes_cluster.k8s_cluster.identity[0].principal_id
}

output "mi_tenant_id" {
  value = azurerm_kubernetes_cluster.k8s_cluster.identity[0].tenant_id
}

output "kubelet_client_id" {
  value = azurerm_kubernetes_cluster.k8s_cluster.kubelet_identity[0].client_id
}

output "kubelet_object_id" {
  value = azurerm_kubernetes_cluster.k8s_cluster.kubelet_identity[0].object_id
}

output "ambassador_public_ip" {
  value = data.azurerm_public_ip.ambassador-ingress.ip_address
}
