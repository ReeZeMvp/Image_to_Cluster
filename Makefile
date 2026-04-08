.PHONY: all install build import deploy forward clean

all: install build import deploy forward

install:
	@echo "=== Installation de Packer et Ansible ==="
	@echo "Nettoyage des repositories problématiques..."
	sudo rm -f /etc/apt/sources.list.d/yarn.list || true
	@echo "Ajout du repository HashiCorp..."
	curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
	echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $$(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
	@echo "Mise à jour des packages..."
	sudo apt-get update || (echo "Erreur lors de l'update, tentative de nettoyage..." && sudo apt-get clean && sudo apt-get update)
	@echo "Installation de Packer et Ansible..."
	sudo apt-get install -y packer ansible
	@echo "Installation des collections Ansible..."
	ansible-galaxy collection install kubernetes.core
	@echo "Installation du module Python Kubernetes..."
	pip install kubernetes --break-system-packages

build:
	@echo "=== Build de l'image avec Packer ==="
	cd packer && packer init nginx-custom.pkr.hcl && packer build nginx-custom.pkr.hcl

import:
	@echo "=== Import de l'image dans K3d ==="
	k3d image import nginx-custom:latest -c lab

deploy:
	@echo "=== Déploiement via Ansible ==="
	ansible-playbook ansible/deploy.yml

forward:
	@echo "=== Port-forward sur 8081 ==="
	kubectl port-forward svc/nginx-custom-svc 8081:80 -n nginx-app >/tmp/nginx.log 2>&1 &
	@echo "Application accessible sur le port 8081"
	@echo "!! Penser à bien mettre le port en Visibilité Public si nécessaire pour éviter la non-visiblité du port (erreur 404)"

clean:
	@echo "=== Nettoyage ==="
	kubectl delete namespace nginx-app --ignore-not-found
	docker rmi nginx-custom:latest || true