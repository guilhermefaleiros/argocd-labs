# ArgoCD Labs

Laboratório para estudar GitOps com Argo CD e estratégias de entrega progressiva com Argo Rollouts em um cluster local `kind`.

Os cenários incluídos são:

- `basic`: deployment tradicional sincronizado pelo Argo CD
- `canary`: rollout canário com Argo Rollouts
- `bluegreen`: rollout blue/green com serviço ativo e preview

## Objetivo

Este repositório demonstra, de forma prática, como:

- criar um cluster local para testes
- instalar Argo CD e Argo Rollouts
- bootstrapar aplicações a partir do próprio Git
- comparar deployment comum, canário e blue/green

## Estrutura

```text
.
├── apps/
│   ├── basic/
│   │   └── manifests/
│   │       └── deployment.yaml
│   ├── bluegreen/
│   │   └── manifests/
│   │       └── rollout.yaml
│   └── canary/
│       └── manifests/
│           └── rollout.yaml
├── bootstrap/
│   ├── applications/
│   │   ├── basic.yaml
│   │   ├── bluegreen.yaml
│   │   └── canary.yaml
│   └── root-application.yaml
├── cluster/
│   └── kind.yaml
├── scripts/
│   ├── bootstrap.sh
│   ├── get-argocd-password.sh
│   ├── install-argocd.sh
│   └── install-rollouts.sh
└── README.md
```

## O que mudou na organização

Agora o repositório separa responsabilidades com mais clareza:

- `apps/`: manifests Kubernetes e Rollouts dos cenários
- `bootstrap/`: `Application` resources do Argo CD
- `cluster/`: configuração do cluster local
- `scripts/`: automação de instalação e bootstrap

Também houve padronização para `yaml` e os `Application` passaram a apontar para `targetRevision: main` em vez de `HEAD`.

## Pré-requisitos

Tenha estes binários instalados:

- `docker`
- `kind`
- `kubectl`
- `argocd`

Opcional, mas recomendado para acompanhar os rollouts:

- `kubectl-argo-rollouts`

## Fluxo rápido

### 1. Subir tudo de uma vez

```bash
sh scripts/bootstrap.sh
```

Esse script:

- cria o cluster `kind` com [cluster/kind.yaml](/Users/guilhermefaleirosdesiqueira/studies/argocd-labs/cluster/kind.yaml)
- instala o Argo CD
- instala o Argo Rollouts
- aguarda os deployments principais ficarem disponíveis

### 2. Abrir a UI do Argo CD

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Em outro terminal:

```bash
sh scripts/get-argocd-password.sh
```

Acesso:

- URL: `https://localhost:8080`
- usuário: `admin`

### 3. Registrar os laboratórios no Argo CD

Você pode aplicar tudo de uma vez pelo padrão app-of-apps:

```bash
kubectl apply -f bootstrap/root-application.yaml
```

Ou registrar cenários individualmente:

```bash
kubectl apply -f bootstrap/applications/basic.yaml
kubectl apply -f bootstrap/applications/canary.yaml
kubectl apply -f bootstrap/applications/bluegreen.yaml
```

## Cenários

### `basic`

Aplica os recursos de [apps/basic/manifests/deployment.yaml](/Users/guilhermefaleirosdesiqueira/studies/argocd-labs/apps/basic/manifests/deployment.yaml) no namespace `basic`.

Recursos criados:

- `Deployment`
- `Service`

Verificação:

```bash
kubectl get all -n basic
```

### `canary`

Aplica os recursos de [apps/canary/manifests/rollout.yaml](/Users/guilhermefaleirosdesiqueira/studies/argocd-labs/apps/canary/manifests/rollout.yaml) no namespace `canary`.

Estratégia configurada:

- 25%
- pausa
- 50%
- pausa
- 100%

Verificação:

```bash
kubectl get all -n canary
kubectl argo rollouts get rollout canary -n canary --watch
```

### `bluegreen`

Aplica os recursos de [apps/bluegreen/manifests/rollout.yaml](/Users/guilhermefaleirosdesiqueira/studies/argocd-labs/apps/bluegreen/manifests/rollout.yaml) no namespace `bluegreen`.

Estratégia configurada:

- serviço ativo para produção
- serviço preview para validação
- promoção manual

Verificação:

```bash
kubectl get all -n bluegreen
kubectl argo rollouts get rollout bluegreen -n bluegreen --watch
kubectl argo rollouts promote bluegreen -n bluegreen
```

## App of Apps

O manifesto [bootstrap/root-application.yaml](/Users/guilhermefaleirosdesiqueira/studies/argocd-labs/bootstrap/root-application.yaml) registra de uma vez os três `Application` filhos localizados em [bootstrap/applications/basic.yaml](/Users/guilhermefaleirosdesiqueira/studies/argocd-labs/bootstrap/applications/basic.yaml), [bootstrap/applications/canary.yaml](/Users/guilhermefaleirosdesiqueira/studies/argocd-labs/bootstrap/applications/canary.yaml) e [bootstrap/applications/bluegreen.yaml](/Users/guilhermefaleirosdesiqueira/studies/argocd-labs/bootstrap/applications/bluegreen.yaml).

Esse é o fluxo mais próximo de um bootstrap GitOps real para este laboratório.

## Como testar mudanças

Faça alterações nos manifests em `apps/`, por exemplo:

- mudar a imagem `kubedevio/web-color`
- alterar número de réplicas
- mudar pesos e pausas do canário
- mudar o comportamento de promoção do blue/green

Depois:

1. faça commit e push
2. aguarde o Argo CD reconciliar
3. acompanhe pela UI ou com `kubectl`

## Comandos úteis

Listar aplicações:

```bash
kubectl get applications -n argocd
```

Listar recursos dos cenários:

```bash
kubectl get all -n basic
kubectl get all -n canary
kubectl get all -n bluegreen
```

Listar rollouts:

```bash
kubectl get rollout -n canary
kubectl get rollout -n bluegreen
```

## Sobre versões

Os scripts de instalação aceitam sobrescrita por variável de ambiente:

- `ARGOCD_INSTALL_URL`
- `ROLLOUTS_INSTALL_URL`

Exemplo:

```bash
ARGOCD_INSTALL_URL="https://raw.githubusercontent.com/argoproj/argo-cd/<versao>/manifests/install.yaml" \
sh scripts/install-argocd.sh
```

Isso permite fixar versões sem editar os scripts.

## Limpeza

```bash
kind delete cluster
```
