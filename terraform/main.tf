provider "google" {
  project = "microservice-test-385004"
  region  = "us-central1"
}

data "google_client_config" "default" {}

resource "google_container_cluster" "gke_cluster" {
  name     = "weather-app"
  location = "us-central1-a"

  initial_node_count = 1

  node_config {
    machine_type = "e2-small"
  }
}

resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = "app"
  }

  depends_on = [
    google_container_cluster.gke_cluster
  ]
}


provider "kubernetes" {
  host                   = "https://${google_container_cluster.gke_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.gke_cluster.master_auth[0].cluster_ca_certificate)
}

resource "kubernetes_deployment" "location_service" {
  metadata {
    name      = "location-service"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "location-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "location-service"
        }
      }

      spec {
        container {
          name  = "location-service"
        #   image = "<YOUR_DOCKERHUB_USERNAME>/location-service"
          image = "gcr.io/microservice-test-385004/location-service:good"
          image_pull_policy = "Always"


          port {
            container_port = 5001
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "frontend_ui" {
  metadata {
    name      = "frontend-ui"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "frontend-ui"
      }
    }

    template {
      metadata {
        labels = {
          app = "frontend-ui"
        }
      }

      spec {
        container {
          name  = "frontend-ui"
        #   image = "<YOUR_DOCKERHUB_USERNAME>/frontend-ui"
          image = "gcr.io/microservice-test-385004/frontend-ui:final"
          image_pull_policy = "Always"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "frontend_ui_service" {
  metadata {
    name      = "frontend-ui-service"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  spec {
    selector = {
      app = "frontend-ui"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_deployment" "aggregated_data_service" {
  metadata {
    name      = "aggregated-service"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "aggregated-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "aggregated-service"
        }
      }

      spec {
        container {
          name  = "aggregated-service"
          image = "gcr.io/microservice-test-385004/aggregated-service:final3"
          image_pull_policy = "Always"

          port {
            container_port = 5003
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "weather_data_service" {
  metadata {
    name      = "weather-service"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    annotations = {
      "kubectl.kubernetes.io/restartedAt" = timestamp()
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "weather-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "weather-service"
        }
      }

      spec {
        container {
          name  = "weather-service"
          image = "gcr.io/microservice-test-385004/weather-service:final"
          image_pull_policy = "Always"

          port {
            container_port = 5002
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "location_service_service" {
  metadata {
    name      = "location-service-service"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  spec {
    selector = {
      app = "location-service"
    }

    port {
      port        = 5001
      target_port = 5001
    }
  }
}

resource "kubernetes_service" "weather_data_service_service" {
  metadata {
    name      = "weather-service-service"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  spec {
    selector = {
      app = "weather-service"
    }

    port {
      port        = 5002
      target_port = 5002
    }
  }
}

resource "kubernetes_service" "aggregated_data_service_service" {
  metadata {
    name      = "aggregated-service-service"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  spec {
    selector = {
      app = "aggregated-service"
    }

    port {
      port        = 5003
      target_port = 5003
    }
  }
}


# kubectl get services --namespace=app

# cd ../location-service
# docker tag location-service:final gcr.io/microservice-test-385004/location-service:final
# docker build -t location-service:final .
# docker push gcr.io/microservice-test-385004/location-service:good

# cd ../frontend-ui
# docker tag frontend-ui:final gcr.io/microservice-test-385004/frontend-ui:final
# docker build -t frontend-ui:final .
# docker push gcr.io/microservice-test-385004/frontend-ui:final

# cd ../weather-service
# docker tag weather-service:final gcr.io/microservice-test-385004/weather-service:final
# docker build -t weather-service:final .
# docker push gcr.io/microservice-test-385004/weather-service:final

# cd ../agg-service
# docker tag aggregated-service:final2 gcr.io/microservice-test-385004/aggregated-service:final2
# docker build -t aggregated-service:final2 .
# docker push gcr.io/microservice-test-385004/aggregated-service:final3
