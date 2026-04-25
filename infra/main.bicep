@description('Ambiente: dev ou prod')
param environment string

@description('Localização dos recursos')
param location string = 'brazilsouth'

@description('Password do PostgreSQL')
@secure()
param dbPassword string

var prefix = 'kiwa-${environment}'

// App Service Plan (B1)
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: '${prefix}-plan'
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
  properties: {
    reserved: true
  }
}

// App Service - API Node.js
resource apiApp 'Microsoft.Web/sites@2023-01-01' = {
  name: '${prefix}-api'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      healthCheckPath: '/api/health'
      appSettings: [
        {
          name: 'PORT'
          value: '3000'
        }
        {
          name: 'DATABASE_URL'
          value: 'postgres://kiwaadmin:${dbPassword}@${postgresServer.properties.fullyQualifiedDomainName}/exampledb?sslmode=require'
        }
        {
          name: 'NODE_ENV'
          value: environment
        }
        {
          name: 'WEBSITES_PORT'
          value: '3000'
        }
      ]
    }
  }
}

// Static Web App - Client
resource staticWebApp 'Microsoft.Web/staticSites@2023-01-01' = {
  name: '${prefix}-client'
  location: 'eastus2'
  sku: {
    name: 'Free'
    tier: 'Free'
  }
  properties: {}
}

// PostgreSQL Flexible Server
resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-06-01-preview' = {
  name: '${prefix}-db'
  location: location
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: 'kiwaadmin'
    administratorLoginPassword: dbPassword
    version: '16'
    storage: {
      storageSizeGB: 32
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
  }
}

// Firewall rule - permite ligações do App Service
resource postgresFirewall 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-06-01-preview' = {
  parent: postgresServer
  name: 'allow-azure-services'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Base de dados
resource postgresDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-06-01-preview' = {
  parent: postgresServer
  name: 'exampledb'
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

output apiUrl string = 'https://${apiApp.properties.defaultHostName}'
output clientUrl string = 'https://${staticWebApp.properties.defaultHostname}'
output dbHost string = postgresServer.properties.fullyQualifiedDomainName
