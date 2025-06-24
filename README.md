# Demo Application

Order of deployment:

- vnetgway.ps1
- webappsrgcreate.ps1
- serviceprincple.ps1
- vnetsubnet.tf
- appservice-webapp.t
- appgway.tf

The first two scripts will create two seperate resource groups 'rg-uks-webapps' and 'rg-uks-connections'. The serviceprincple.ps1 will check the groups exist and then create a service principle and add itself a contributor to allow creation.

Within the 'rg-uks-connections' there will be a vnet with an attached subnet. Address space: 192.0.10.0/24 subnet: 192.0.10/26. A total of 256 addresses and which 64 address assigned for my application gateway.

Within the 'rg-uks-webapps' there is app service plan (free tier) along with a webapp for my application.

Eventually I'll do the DNS configuration via Terraform for Cloudflare.



