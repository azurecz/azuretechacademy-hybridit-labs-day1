# Create networking
## create central network
$rgc = "akademie-central-rg"
az group create -n $rgc -l westeurope

az network vnet create -g $rgc -n cp-central-we-vnet -l westeurope --address-prefixes 10.1.0.0/16 --subnet-name sub1 --subnet-prefix 10.1.1.0/24

## create app network
$rgapp = "akademie-app-rg"
az group create -n $rgapp -l westeurope

az network vnet create -g $rgapp -n cp-app1-we-vnet -l westeurope --address-prefixes 10.10.0.0/16 --subnet-name sub1 --subnet-prefix 10.10.1.0/24

## peer networks
# TODO: peer central with app

## create storage account for diagnostics (use by --boot-diagnostics-storage)
$st="https://<YOUR NAME>.blob.core.windows.net/"
#az storage account create -g $rgvmjump -n cpvmjump --sku Standard_LRS

# Create servers
## create primary Windows AD server
$rgvmad = "akademie-vmad-rg"
az group create -n $rgvmad -l westeurope
# create windows server in central network with RDP - name: cp-vmad
$advnetsub1=$(az network vnet subnet show -g $rgc --vnet-name cp-central-we-vnet -n sub1 --query id -o json)
az vm create -g $rgvmad -n cp-vmad --image Win2016Datacenter --size Standard_B2ms --subnet $advnetsub1 --boot-diagnostics-storage $st --admin-username cpadmin
# connect RDP and install Windows Active Directory with DNS zone
Install-WindowsFeature AD-Domain-Services
Import-Module ADDSDeployment
Install-ADDSForest `
-CreateDnsDelegation:$false `
-DatabasePath "C:\Windows\NTDS" `
-DomainMode "Win2012R2" `
-DomainName "corp.cp.com" `
-DomainNetbiosName "CORP" `
-ForestMode "Win2012R2" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$false `
-SysvolPath "C:\Windows\SYSVOL" `
-Force:$true
# setup DNS forwarder to 168.63.129.16
Set-DnsServerForwarder -IPAddress "168.63.129.16" -PassThru

## create Jump server
$rgvmjump = "akademie-vmjump-rg"
az group create -n $rgvmjump -l westeurope
# create ubuntu server in central network with SSH - name: cp-vmjump
$advnetsub1=$(az network vnet subnet show -g $rgc --vnet-name cp-central-we-vnet -n sub1 --query id -o json)
az vm create -g $rgvmjump -n cp-vmjump --image UbuntuLTS --size Standard_B2s --subnet $advnetsub1 --authentication-type password --boot-diagnostics-storage $st --admin-username cpadmin

## create APP server
$rgvmweb = "akademie-vmweb-rg"
az group create -n $rgvmweb -l westeurope
# TODO create windows server in app network with RDP and HTTP - name:cp-vmweb
# HINT: Now you can setup ASR to speedup process of replication

# Setup DNS and join server to Windows AD domain
az network vnet update -g $rgc -n cp-central-we-vnet --dns-servers 10.1.1.4
az network vnet update -g $rgapp -n cp-app1-we-vnet --dns-servers 10.1.1.4

## Configure APP WEB server
# connect RDP and join to AD domain
Add-Computer -DomainName corp.cp.com -Restart
# Install IIS
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer
Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures