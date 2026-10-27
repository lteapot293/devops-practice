# 1. Настройка провайдера для работы с Yandex Cloud
terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.90"
    }
  }
}

provider "yandex" {
  # Переменные авторизации (для репозитория оставляем в виде заглушек)
  token     = "YOUR_OAUTH_TOKEN"
  cloud_id  = "YOUR_CLOUD_ID"
  folder_id = "YOUR_FOLDER_ID"
  zone      = "ru-central1-a"
}

# 2. Создание виртуальной сети и подсети
resource "yandex_vpc_network" "practice_network" {
  name = "practice-network"
}

resource "yandex_vpc_subnet" "practice_subnet" {
  name           = "practice-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.practice_network.id
  v4_cidr_blocks = ["10.0.1.0/24"]
}

# 3. Динамическое создание 3 виртуальных машин через count
resource "yandex_compute_instance" "vm_nodes" {
  count = 3
  
  # Назначаем имена по индексу: vm-0, vm-1, vm-2
  name        = "vm-${count.index}"
  hostname    = "vm-${count.index}"
  platform_id = "standard-v3" # Самая базовая платформа

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      # Образ Ubuntu 22.04 LTS
      image_id = "fd80bm0rh4rk929wca4l" 
      size     = 15
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.practice_subnet.id
    nat       = true # Выделяем публичный IP для доступа по SSH
  }

  # Метаданные для проброса SSH-ключа, как требует задание
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }
}

# 4. Вывод публичных IP-адресов созданных машин для Ansible
output "external_ip_addresses" {
  value = {
    for instance in yandex_compute_instance.vm_nodes :
    instance.name => instance.network_interface.0.nat_ip_address
  }
}
