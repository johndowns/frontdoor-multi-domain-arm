param frontDoorName string
param app1BackendUrl string
param app2BackendUrl string
param customers array

var frontDoorBackendPoolApp1Name = 'backend-pool-app-1'
var frontDoorBackendPoolApp2Name = 'backend-pool-app-2'
var frontDoorHealthProbeApp1Name = 'health-probe-app-1'
var frontDoorHealthProbeApp2Name = 'health-probe-app-2'
var sharedLoadBalancingSettingsName = 'shared-load-balancing-settings'

// Assemble an object representing the default frontend for the Front Door instance.
var frontDoorFrontendDefaultName = 'frontend-default'
var frontDoorFrontendDefault = {
  name: frontDoorFrontendDefaultName
  properties: {
    hostName: '${frontDoorName}.azurefd.net'
    sessionAffinityEnabledState: 'Disabled'
    sessionAffinityTtlSeconds: 0
  }
}

// Assemble an array of frontends for each customer's hostnames.
var frontDoorFrontendNamesApp1 = [for customer in customers: 'frontend-app1-${customer.customerId}']
var frontDoorFrontendsApp1 = [for customer in customers: {
  name: 'frontend-app1-${customer.customerId}'
  properties: {
    hostName: customer.app1HostName
    sessionAffinityEnabledState: 'Disabled'
    sessionAffinityTtlSeconds: 0
  }
}]
var frontDoorFrontendNamesApp2 = [for customer in customers: 'frontend-app2-${customer.customerId}']
var frontDoorFrontendsApp2 = [for customer in customers: {
  name: 'frontend-app2-${customer.customerId}'
  properties: {
    hostName: customer.app2HostName
    sessionAffinityEnabledState: 'Disabled'
    sessionAffinityTtlSeconds: 0
  }
}]

// Assemble an array of frontend IDs to use in the routing rules.
var frontDoorRoutingRulesApp1Frontends = [for customer in customers: {
  id: resourceId('Microsoft.Network/frontDoors/frontendEndpoints', frontDoorName, 'frontend-app1-${customer.customerId}')
}]
var frontDoorRoutingRulesApp2Frontends = [for customer in customers: {
  id: resourceId('Microsoft.Network/frontDoors/frontendEndpoints', frontDoorName, 'frontend-app2-${customer.customerId}')
}]

// Assemble an array of all application frontends, which will be used for the custom HTTPS configuration.
var frontDoorFrontendAppNames = concat(frontDoorFrontendNamesApp1, frontDoorFrontendNamesApp2)

// Assemble an array of all Front Door frontends.
var frontDoorFrontends = concat(array(frontDoorFrontendDefault), frontDoorFrontendsApp1, frontDoorFrontendsApp2)

resource frontDoor 'Microsoft.Network/frontDoors@2019-04-01' = {
  name: frontDoorName
  location: 'global'
  properties: {
    frontendEndpoints: frontDoorFrontends
    healthProbeSettings: [
      {
        name: frontDoorHealthProbeApp1Name
        properties: {
          path: '/'
          protocol: 'Http'
          intervalInSeconds: 120
        }
      }
      {
        name: frontDoorHealthProbeApp2Name
        properties: {
          path: '/'
          protocol: 'Http'
          intervalInSeconds: 120
        }
      }
    ]
    loadBalancingSettings: [
      {
        name: sharedLoadBalancingSettingsName
        properties: {
          sampleSize: 4
          successfulSamplesRequired: 2
        }
      }
    ]
    backendPools: [
      {
        name: frontDoorBackendPoolApp1Name
        properties: {
          backends: [
            {
              address: app1BackendUrl
              httpPort: 80
              httpsPort: 443
              weight: 50
              priority: 1
              enabledState: 'Enabled'
            }
          ]
          loadBalancingSettings: {
            id: resourceId('Microsoft.Network/frontDoors/loadBalancingSettings', frontDoorName, sharedLoadBalancingSettingsName)
          }
          healthProbeSettings: {
            id: resourceId('Microsoft.Network/frontDoors/healthProbeSettings', frontDoorName, frontDoorHealthProbeApp1Name)
          }
        }
      }
      {
        name: frontDoorBackendPoolApp2Name
        properties: {
          backends: [
            {
              address: app2BackendUrl
              httpPort: 80
              httpsPort: 443
              weight: 50
              priority: 1
              enabledState: 'Enabled'
            }
          ]
          loadBalancingSettings: {
            id: resourceId('Microsoft.Network/frontDoors/loadBalancingSettings', frontDoorName, sharedLoadBalancingSettingsName)
          }
          healthProbeSettings: {
            id: resourceId('Microsoft.Network/frontDoors/healthProbeSettings', frontDoorName, frontDoorHealthProbeApp2Name)
          }
        }
      }
    ]
    routingRules: [
      {
        name: 'routingrule-app1'
        properties: {
          frontendEndpoints: frontDoorRoutingRulesApp1Frontends
          acceptedProtocols: [
            'Http'
            'Https'
          ]
          patternsToMatch: [
            '/*'
          ]
          routeConfiguration: {
            '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorForwardingConfiguration'
            forwardingProtocol: 'HttpsOnly'
            backendPool: {
              id: resourceId('Microsoft.Network/frontDoors/backendPools', frontDoorName, frontDoorBackendPoolApp1Name)
            }
          }
          enabledState: 'Enabled'
        }
      }
      {
        name: 'routingrule-app2'
        properties: {
          frontendEndpoints: frontDoorRoutingRulesApp2Frontends
          acceptedProtocols: [
            'Http'
            'Https'
          ]
          patternsToMatch: [
            '/*'
          ]
          routeConfiguration: {
            '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorForwardingConfiguration'
            forwardingProtocol: 'HttpsOnly'
            backendPool: {
              id: resourceId('Microsoft.Network/frontDoors/backendPools', frontDoorName, frontDoorBackendPoolApp2Name)
            }
          }
          enabledState: 'Enabled'
        }
      }
    ]
  }
}

resource customHttpsConfiguration 'Microsoft.Network/frontDoors/frontendEndpoints/customHttpsConfiguration@2020-07-01' = [for frontDoorFrontendAppName in frontDoorFrontendAppNames: {
  name: '${frontDoorName}/${frontDoorFrontendAppName}/default'
  dependsOn: [
    frontDoor
  ]
  properties: {
    protocolType: 'ServerNameIndication'
    certificateSource: 'FrontDoor'
    frontDoorCertificateSourceParameters: {
      certificateType: 'Dedicated'
    }
    minimumTlsVersion: '1.2'
  }
}]
