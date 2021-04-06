# Multi-domain Bicep ARM template for Front Door

This repository contains a Bicep ARM template for Azure Front Door that configures a variable set of frontends.

In SaaS vendor scenarios, there may be a requirement to allow customers to provision their own custom hostnames and for these to be configured against Front Door. This example illustrates how a parameter file can contain a list of customers, each of which has two hostnames provisioned (for two different example applications). Each customer’s hostname is configured as a frontend in Front Door, and routes to a shared backend pool for each application.

This template illustrates the use of Bicep variables in order to assemble the frontend and routing rules properties.
