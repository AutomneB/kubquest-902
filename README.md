# KubeQuest - Projet T-CLO-902

Bienvenue sur le projet KubeQuest, réalisé dans le cadre du module T-CLO-902. Ce projet vise à déployer une infrastructure Kubernetes complète, automatisée avec Terraform, Ansible et Helm, puis gérée via ArgoCD en mode GitOps.

## 🔧 Objectifs

- Déployer un cluster Kubernetes sur Azure (via Terraform)

- Configurer les noeuds master et workers avec Ansible

- Déployer une stack applicative (PostgreSQL, Redis, Voting App...) via Helm Charts

- Gérer les déploiements avec ArgoCD en mode GitOps

## 🚀 Prérequis

- Un accès à un abonnement Azure DevTest Labs

- Ubuntu/WSL2 (recommandé)

- Les outils suivants installés dans votre WSL2 :

  - Terraform

  - Ansible

  - kubectl

  - Helm

  - Azure CLI

  - Kustomize

## 📁 Arborescence du projet (simplifiée)

```bash

├── ansible/                # Configuration post-provisionnement
├── app-chart/              # Helm charts custom pour chaque app
├── install_kubernetes/     # Script manuel d'installation Kubeadm (optionnel)
├── ssh-key/                # Contient votre clé SSH (non versionnée)
├── terraform/              # Déploiement des VM Azure
└── README.md               # Ce document
```

## ⚙️ Déploiement de l'infrastructure

```bash
cd terraform
terraform init
terraform apply
```

## 🚒 Configuration des VMs avec Ansible

Pour cela il vous suffit de lancer les commandes suivantes afin de lancer un scprit sh automatique

```bash
chmod +x playbook.sh
./playbook.sh
```

## 🤖 Bonnes pratiques

- Ne jamais modifier directement values.yaml des charts officiels (ex : Redis)

- Créer un fichier common-values.yaml pour surcharger sans casser l'original

- Toujours utiliser helm dependency update avant de pousser

- Préférer ArgoCD à helm install à la main

- Travailler sur des branches Git différentes si plusieurs versions doivent cohabiter (via targetRevision dans ArgoCD)

## 📅 Sources principales

Kubernetes - Docs

Terraform Azure provider

Ansible Quickstart

Helm Charts Docs

ArgoCD Documentation
