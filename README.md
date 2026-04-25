# kiwa-devops

Solução DevOps end-to-end para a aplicação UNO Digital, com infraestrutura como código, pipelines CI/CD, dois ambientes separados (dev e prod) e monitorização básica.

## Arquitetura

GitHub (repositório)
├── branch: dev   → deploy automático para ambiente dev
└── branch: main  → deploy automático para ambiente prod
Azure (por ambiente)
├── App Service (B1) → API Node.js
├── Static Web App   → Client HTML estático
└── PostgreSQL Flexible Server → Base de dados

## Ambientes

| Recurso | Dev | Prod |
|---|---|---|
| API | https://kiwa-dev-api.azurewebsites.net | https://kiwa-prod-api.azurewebsites.net |
| Client | https://jolly-pond-0bad4cc0f.7.azurestaticapps.net | https://white-glacier-0e8d0eb0f.7.azurestaticapps.net |
| DB Host | kiwa-dev-db.postgres.database.azure.com | kiwa-prod-db.postgres.database.azure.com |
| Resource Group | rg-kiwa-dev | rg-kiwa-prod |

## Pré-requisitos

- Azure CLI instalado e autenticado (`az login`)
- Conta Azure com subscrição ativa
- Node.js 20+
- Git

## Como executar a infraestrutura

Criar os resource groups:
```bash
az group create --name rg-kiwa-dev --location brazilsouth
az group create --name rg-kiwa-prod --location brazilsouth
```

Fazer deploy da infraestrutura (substituir `<password>` por uma password segura):
```bash
az deployment group create \
  --resource-group rg-kiwa-dev \
  --template-file infra/main.bicep \
  --parameters environment=dev dbPassword=<password>

az deployment group create \
  --resource-group rg-kiwa-prod \
  --template-file infra/main.bicep \
  --parameters environment=prod dbPassword=<password>
```

Criar a base de dados em cada ambiente:
```bash
az postgres flexible-server db create \
  --resource-group rg-kiwa-dev \
  --server-name kiwa-dev-db \
  --database-name exampledb

az postgres flexible-server db create \
  --resource-group rg-kiwa-prod \
  --server-name kiwa-prod-db \
  --database-name exampledb
```

## Fluxo de deploy

**Deploy para dev:**

feature/branch → PR para dev → testes passam → merge → deploy automático para dev

**Deploy para prod:**

dev → PR para main → testes passam → merge → deploy automático para prod

## Como correr testes localmente

```bash
cd server
cp .env.example .env
# Edita o .env com as variáveis necessárias
docker compose up -d  # sobe o PostgreSQL local
npm install
npm test
```

## Como correr testes no CI

Os testes correm automaticamente em qualquer Pull Request para `dev` ou `main`. O merge é bloqueado se os testes falharem.

## Como ver logs

Ver logs em tempo real:
```bash
az webapp log tail \
  --name kiwa-dev-api \
  --resource-group rg-kiwa-dev
```

Ou pelo portal Azure: App Service → **Log stream**

## Como validar uptime

O healthcheck está configurado no App Service apontando para `/api/health`.

Validar manualmente:
```bash
curl https://kiwa-dev-api.azurewebsites.net/api/health
curl https://kiwa-prod-api.azurewebsites.net/api/health
```

Pelo portal Azure: App Service → **Health check** → Runtime status: **Healthy**

## Variáveis e configurações necessárias

| Variável | Descrição |
|---|---|
| `PORT` | Porta onde a API corre (3000) |
| `DATABASE_URL` | Connection string do PostgreSQL |
| `NODE_ENV` | Ambiente (dev ou prod) |
| `WEBSITES_PORT` | Porta exposta pelo App Service (3000) |

### GitHub Secrets necessários

| Secret | Descrição |
|---|---|
| `AZURE_WEBAPP_PUBLISH_PROFILE_DEV` | Publish profile do App Service de dev |
| `AZURE_WEBAPP_PUBLISH_PROFILE_PROD` | Publish profile do App Service de prod |
| `AZURE_STATIC_WEB_APPS_API_TOKEN_DEV` | Token do Static Web App de dev |
| `AZURE_STATIC_WEB_APPS_API_TOKEN_PROD` | Token do Static Web App de prod |