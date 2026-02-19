terraform {
  required_providers {
    hostinger = {
      source  = "hostinger/hostinger"
      version = "~> 0.1"
    }
  }
}

provider "hostinger" {
  // api_token is set via HOSTINGER_API_TOKEN environment variable
}

variable "vps_plan" {
  description = "The ID of the VPS plan (e.g., hostingercom-vps-kvm2-usd-1m)"
  type        = string
}

variable "data_center_id" {
  description = "The ID of the data center"
  type        = number
}

variable "template_id" {
  description = "The ID of the OS template (e.g., Ubuntu 22.04)"
  type        = number
}

variable "hostname" {
  description = "The hostname for the VPS"
  type        = string
  default     = "laravel-vps.example.com"
}

variable "password" {
  description = "The root password for the VPS"
  type        = string
  sensitive   = true
}

data "hostinger_vps_plans" "all" {}
data "hostinger_vps_data_centers" "all" {}
data "hostinger_vps_templates" "all" {}

// Optional: Output available options for reference
output "available_plans" {
  value = data.hostinger_vps_plans.all.plans
}

output "available_data_centers" {
  value = data.hostinger_vps_data_centers.all.data_centers
}

output "available_templates" {
  value = data.hostinger_vps_templates.all.templates
}

resource "hostinger_vps_post_install_script" "setup" {
  name    = "Install Docker and Setup"
  content = <<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get upgrade -y
    apt-get install -y docker.io git
    systemctl start docker
    systemctl enable docker

    # Pull latest PostgreSQL image
    docker pull postgres:latest

    # Build latest Laravel image
    mkdir /tmp/laravel-build
    cd /tmp/laravel-build
    cat <<EOF > Dockerfile
    FROM php:8.3-fpm

    RUN apt-get update && apt-get install -y \\
        build-essential \\
        libpng-dev \\
        libjpeg62-turbo-dev \\
        libfreetype6-dev \\
        locales \\
        zip \\
        jpegoptim optipng pngquant gifsicle \\
        vim \\
        unzip \\
        git \\
        curl \\
        libonig-dev \\
        libzip-dev

    RUN apt-get clean && rm -rf /var/lib/apt/lists/*

    RUN docker-php-ext-install pdo_mysql mbstring zip exif pcntl
    RUN docker-php-ext-configure gd --with-freetype --with-jpeg
    RUN docker-php-ext-install gd

    RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

    WORKDIR /app
    RUN composer create-project --prefer-dist laravel/laravel .

    EXPOSE 9000
    CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=9000"]
    EOF

    docker build -t my-laravel:latest .

    # Create irimsv folder and setup git
    mkdir /irimsv
    cd /irimsv
    git init
    # To setup GitHub, add your remote manually: git remote add origin <your-repo-url>
    # For now, just initialized the repo

  EOT
}

resource "hostinger_vps" "laravel_vps" {
  plan                   = var.vps_plan
  data_center_id         = var.data_center_id
  template_id            = var.template_id
  hostname               = var.hostname
  password               = var.password
  post_install_script_id = hostinger_vps_post_install_script.setup.id
  // Add ssh_key_ids if you have SSH keys defined
}
