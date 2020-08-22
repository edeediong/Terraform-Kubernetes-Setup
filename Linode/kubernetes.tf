provider "helm" {
  version = "~>1.0.0"
  kubernetes {
    config_path = "lke-cluster-config.yaml"
  }
}
data "helm_repository" "incubator" {
  name = "stable"
  url = "https://kubernetes-charts.storage.googleapis.com"
}

resource "helm_release" "nginx" {
  chart = "nginx-ingress"
  repository = data.helm_repository.incubator.url
  name = "siteopsproxy"
}

resource "kubernetes_deployment" "backend" {
  metadata {
    name = "backend"

    labels = {
      "app" = "backend"
    }

  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        "app" = "backend"
      }
    }

    template {
      metadata {
        labels = {
          "app" = "backend"
        }
      }

      spec {
        container {
          name  = "backend"
          image = "edeediong/backendsiteops:12"

          port {
            container_port = 4000
          }

          env {
            name = "DATABASE_URL"

            value_from {
              config_map_key_ref {
                name = "backend-backend--env"
                key  = "DATABASE_URL"
              }
            }
          }

          image_pull_policy = "Always"
        }

        restart_policy = "Always"

      }
    }
  }
}

resource "kubernetes_deployment" "frontendsiteops" {
  metadata {
    name = "frontendsiteops"

    labels = {
      "app" = "frontendsiteops"
    }

  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        "app" = "frontendsiteops"
      }
    }

    template {
      metadata {
        labels = {
          "app" = "frontendsiteops"
        }
      }

      spec {
        container {
          name  = "frontendsiteops"
          image = "edeediong/frontendsiteops:12"

          port {
            container_port = 3000
          }

          image_pull_policy = "Always"
        }

        restart_policy = "Always"

      }
    }
  }
}

resource "kubernetes_ingress" "my_new_ingress" {
  metadata {
    name = "my-new-ingress"

    annotations = {
      namespace = "default"

      "nginx.ingress.kubernetes.io/rewrite-target" = "/$2"
    }
  }

  spec {
    rule {
      http {
        path {
          path = "/graphql(/|$)(.*)"

          backend {
            service_name = "backend"
            service_port = "4000"
          }
        }

        path {
          path = "/*(/|$)(.*)"

          backend {
            service_name = "frontendsiteops"
            service_port = "3000"
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "mysql_data" {
  metadata {
    name = "mysql-data"

    labels = {
      "app" = "mysql-data"
    }
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "100Mi"
      }
    }
  }
}

resource "kubernetes_deployment" "mysql" {
  metadata {
    name = "mysql"

    labels = {
      "app" = "mysql"
    }

  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        "app" = "mysql"
      }
    }

    template {
      metadata {
        labels = {
          "app" = "mysql"
        }
      }

      spec {
        volume {
          name = "mysql-data"

          persistent_volume_claim {
            claim_name = "mysql-data"
          }
        }

        container {
          name  = "mysql"
          image = "mysql:8.0.20"

          port {
            container_port = 3306
          }

          env {
            name  = "MYSQL_ALLOW_EMPTY_PASSWORD"
            value = "yes"
          }

          env {
            name  = "MYSQL_DATABASE"
            value = "prismasite"
          }

          env {
            name  = "MYSQL_PASSWORD"
            value = "password"
          }

          env {
            name  = "MYSQL_USER"
            value = "prismauser"
          }

          volume_mount {
            name       = "mysql-data"
            mount_path = "/bitname/mysql/data"
          }
        }

        restart_policy = "Always"
      }
    }

    strategy {
      type = "Recreate"
    }
  }
}

resource "kubernetes_service" "mysql" {
  metadata {
    name = "mysql"

    labels = {
      "app" = "mysql"
    }

  }

  spec {
    port {
      name        = "3306"
      port        = 3306
      target_port = "3306"
    }

    selector = {
      "app" = "mysql"
    }
  }
}

resource "kubernetes_config_map" "backend_backend__env" {
  metadata {
    name = "backend-backend--env"

    labels = {
      "app" = "backend-backend--env"
    }
  }

  data = {
    DATABASE_URL = "mysql://prismauser:password@mysql:3306/prismasite"
  }
}

resource "kubernetes_service" "backend" {
  metadata {
    name = "backend"

    labels = {
      "app" = "backend"
    }

  }

  spec {
    port {
      name        = "http"
      protocol    = "TCP"
      port        = 4000
      target_port = "4000"
    }

    selector = {
      "app" = "backend"
    }
  }
}

resource "kubernetes_service" "frontendsiteops" {
  metadata {
    name = "frontendsiteops"
  }

  spec {
    port {
      name        = "http"
      protocol    = "TCP"
      port        = 3000
      target_port = "3000"
    }

    selector = {
      "app" = "frontendsiteops"
    }
  }
}
