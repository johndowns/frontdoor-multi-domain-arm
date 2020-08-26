# Multi-domain ARM template for Front Door

This repository contains an ARM template for Azure Front Door that configures a variable set of frontends.

In SaaS vendor scenarios, there may be a requirement to allow customers to provision their own custom hostnames and for these to be configured against Front Door. This example illustrates how a parameter file can contain a list of customers, each of which has two hostnames provisioned (for two different example applications). Each customer’s hostname is configured as a frontend in Front Door, and routes to a shared backend pool for each application.

This template illustrates the use of [ARM template functions for variable iteration](https://docs.microsoft.com/azure/azure-resource-manager/templates/copy-variables) in order to assemble the frontend and routing rules properties. It also illustrates how to use [user-defined template functions](https://docs.microsoft.com/azure/azure-resource-manager/templates/template-user-defined-functions).
