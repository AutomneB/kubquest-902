#!/bin/sh

#Playbook nodes
ansible-playbook -i inventory.ini ../ansible/templates/playbook-kubernetes-basic.yml --ssh-extra-args='-o StrictHostKeyChecking=no'


#playbook Master
ansible-playbook -i inventory.ini ../ansible/templates/playbook-master-node.yml --ssh-extra-args='-o StrictHostKeyChecking=no'


#playbook Worker
ansible-playbook -i inventory.ini ../ansible/templates/playbook-worker-node.yml --ssh-extra-args='-o StrictHostKeyChecking=no' 



#Deploy SC
ansible-playbook -i inventory.ini ../../ansible/templates/playbook-CSI-deploy.yml --ssh-extra-args='-o StrictHostKeyChecking=no'

#Deploy application
ansible-playbook -i inventory.ini ../../ansible/templates/playbook-argocd-deploy.yml --ssh-extra-args='-o StrictHostKeyChecking=no'