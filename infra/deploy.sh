#!/bin/bash
# Uso: ./infra/deploy.sh dev <password>
#      ./infra/deploy.sh prod <password>

ENVIRONMENT=$1
DB_PASSWORD=$2
RESOURCE_GROUP="rg-kiwa-${ENVIRONMENT}"

az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file infra/main.bicep \
  --parameters environment=$ENVIRONMENT dbPassword=$DB_PASSWORD