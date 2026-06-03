az keyvault secret set --vault-name akvdataeng-ctlus-prod --name gen2key --value ""
az keyvault secret set --vault-name akvdataeng-ctlus-prod --name connectionString --value ""
az storage container create --name bronze --account-name stgdataengacctlusprod --auth-mode login
az storage container create --name silver --account-name stgdataengacctlusprod --auth-mode login
az storage container create --name gold   --account-name stgdataengacctlusprod --auth-mode login
