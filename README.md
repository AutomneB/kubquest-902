# T-CLO-902-TLS_7
Créer le storage Class

az account list --output table


az ad sp create-for-rbac --name "k8s-csi-sp" --role="Contributor" --scopes="/subscriptions/<subscriptions>"

Ensuite il faut remplir le fichier ./ansible/templates/vars/azure-vars.yml avec les valeurs obtenu à la création du cluster

A la fin ne pas oublier de supprimer le Storagage Class 
az ad sp list --display-name "k8s-csi-sp"


az ad sp delete --id <appId>


