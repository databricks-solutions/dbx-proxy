dbx_proxy_image_version = "test"
dbx_proxy_health_port   = 8080

dbx_proxy_listener = [
  {
    name  = "database-5432"
    mode  = "tcp"
    port  = 5432
    routes = [
      {
        name    = "database"
        domains = ["test.database.domain"]
        destinations = [
          { name = "database-1", host = "test-backend-database", port = 5432 },
        ]
      }
    ]
  },
  {
    name  = "https-443"
    mode  = "http"
    port  = 443
    routes = [
      {
        name    = "app-a"
        domains = ["app-a.application.domain"]
        destinations = [
          { name = "app-a-1", host = "test-backend-app-a", port = 443 },
        ]
      },
      {
        name    = "app-b"
        domains = ["app-b.application.domain"]
        destinations = [
          { name = "app-b-1", host = "test-backend-app-b", port = 443 },
        ]
      },
    ]
  },
]
