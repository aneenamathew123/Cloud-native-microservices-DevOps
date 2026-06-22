resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.3.6" 
  namespace = "argocd"
  create_namespace = true


  wait = true
  timeout = 300


}


resource "kubectl_manifest" "root_app" {
  depends_on = [helm_release.argocd]
  yaml_body = <<-YAML
  apiVersion: argoproj.io/v1alpha1
  kind: Application
  metadata: 
    name: root-app
    namespace: argocd
    finalizers:
        - resources-finalizer.argocd.argoproj.io
  spec:
    project: default
    source:
      repoURL: https://github.com/aneenamathew123/Cloud-native-microservices-DevOps.git
      targetRevision: main
      path: apps/
    destination:
      server: https://kubernetes.default.svc
      namespace: argocd
    syncPolicy:
      automated:
        prune: true
        selfHeal: true
  YAML

}


