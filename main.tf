terraform {
  required_providers {
    hostinger = {
      source  = "hostinger/hostinger"
      version = "~> 1.0"
    }
  }
}

provider "hostinger" {
  api_token = var.hostinger_token
}

variable "hostinger_token" {
  type      = string
  sensitive = true
  default   = ""
}

resource "hostinger_vps" "laravel_vps" {
  plan        = "vps_kvm2"
  os          = "ubuntu_22_04"
  location    = "asia"
  hostname    = "irimsv-vps"
}

# Run provisioning after VPS creation
resource "null_resource" "setup" {
  depends_on = [hostinger_vps.laravel_vps]

  connection {
    type        = "ssh"
    host        = hostinger_vps.laravel_vps.ip_address
    user        = "root"
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [

      # -------------------------
      # System setup
      # -------------------------
      "apt update -y",
      "apt install -y git curl unzip",

      # -------------------------
      # Install Docker
      # -------------------------
      "curl -fsSL https://get.docker.com | sh",
      "systemctl enable docker",
      "systemctl start docker",

      # -------------------------
      # Install Docker Compose
      # -------------------------
      "apt install -y docker-compose",

      # -------------------------
      # Create IRIMSV folder (outside containers)
      # -------------------------
      "mkdir -p /irimsv",
      "cd /irimsv",

      # -------------------------
      # GitHub setup folder
      # -------------------------
      "git config --global init.defaultBranch main",

      # -------------------------
      # Create Laravel Docker stack
      # -------------------------
      "mkdir -p /opt/laravel",
      "cd /opt/laravel",

      "cat > docker-compose.yml << 'EOF'\n\
version: '3.9'\n\
services:\n\
  app:\n\
    image: laravelsail/php83-composer\n\
    container_name: laravel_app\n\
    volumes:\n\
      - ./:/var/www/html\n\
    ports:\n\
      - '8000:80'\n\
    depends_on:\n\
      - db\n\
\n\
  db:\n\
    image: postgres:latest\n\
    container_name: laravel_db\n\
    restart: always\n\
    environment:\n\
      POSTGRES_DB: laravel\n\
      POSTGRES_USER: laravel\n\
      POSTGRES_PASSWORD: secret\n\
    ports:\n\
      - '5432:5432'\n\
    volumes:\n\
      - pgdata:/var/lib/postgresql/data\n\
\n\
volumes:\n\
  pgdata:\n\
EOF",

      # -------------------------
      # Start containers
      # -------------------------
      "docker-compose up -d"
    ]
  }
}
