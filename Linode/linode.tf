resource "linode_lke_cluster" "siteops" {
    label = "demo"
    k8s_version = "1.15"
    region = var.region
    tags = ["staging"]

    pool {
        type = "g6-standard-2"
        count = 3
    }
}

variable "token" {
    description = "Your API access token"
}

variable region {
    description = "The region of Cluster"
}

provider "linode" {
    token = var.token
}
