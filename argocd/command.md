argocd app sync kubequest


remove argocd 

kubectl delete namespace argocd
kubectl delete crd applications.argoproj.io appprojects.argoproj.io   applicationsets.argoproj.io argocdnotifications.argoproj.io   argoapplications.argoproj.io


get argocd password 

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d


voir les svc 

kubectl get svc -n default