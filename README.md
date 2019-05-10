# Azure Technical Academy - Hybrid IT track 01


As some labs take long time to deploy, we will start deployment now and watch results later.

Deploy Azure Disk storage test. There are 10 tests to be run so select reasonable test time to finish, select 300 seconds.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fazurecz%2Fazuretechacademy-hybridit-labs-day1%2Fmaster%2Fdisk-storage%2Fdeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

Deploy networking lab environment

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fgithub.com%2Ftkubica12%2Fazure-networking-lab%2Fraw%2Fmaster%2FArmEnv%2Fmain.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

## Compute

### Azure Backup
1. Create Windows VM
2. Enable backup and create Backup Vault
3. Initiate backup by clicking Backup Now (it will create app-consistent snapshot by orchestrating with VSS in about 20 minutes and then we have to wait about 1 hour untill backup is transfered from snapshot to vault)
4. Go to existing backup and click on restore file, map backup as iSCSI disk to your notebook following instructions
5. Unmount backup
6. Restore whole VM. You can either create new VM or replace existing (when replacing existing VM needs to be stopped first)
7. Configure storage account and create file share
8. Go to backup vault and enable file share backup

## Storage
### Disk storage performance decisions
Connect to storagetest VM you have deployed previously and check results of storage test. Types of disks are:
* Standard HDD S20 /disk/standardhdd (sdc)
* Standard SSD E20 /disk/standardssd (sdd)
* Premium SSD P20 /disk/premiumssd (sde)
* 4x Standard SSD E10 in LVM pool /disk/vg/lv (sdf, sdg, sdh, sdi)
* Local SSD /mnt (sdb)
* 2x small Standard HDD with different cache settings /disk/uncached and /disk/cached

Three tests are run on each volume:
* sync test random write (waiting for ACK after each transaction simulating legacy workload)
* async test random write (256 bulk operations with 4 threads simulating database workload)
* async test random read test comparing cached and non-cached performance

Connect to VM and check results:
```bash
export ip=$(az network public-ip show -n storagetest-ip -g storagetest-rg --query ipAddress -o tsv)
ssh storage@$ip
    sudo -i
    ls
```

How to read results:
* In /root you will find couple of *.results files with output from FIO tool
* Check IOPS (with multiple writers sum IOPS of each writer) - line write: IOPS=
* Check latency on sync tests, especialy clat percentiles (focus 50th and 99th)

What to expect:
* For sync legacy-type access latency is most important factor for IOPS. Multiple disk does not help
* Latency is fluctulating on Standard HDD, much less on Standard SSD and is very stable on Premium SSD and Local SSD
* LVM IOPS with Standard SSDs is close to same size Premium SSD, but there is operational overhead to setup LVM and latency is more consistent with Premium SSD
* You can easily hit disk IOPS limit and achieve little more then specified
* With Local SSD you are reaching limit of your VM size, not storage limit (if you need extreme local non-redundant performance check L-series VMs)
* Always be aware of VM size limits, it makes no sense to buy P70 disk when connected to D2s_v3 VM type

## Networking
Follow network diagram and instructions in following repo to test comple of networking scenarios:
[https://github.com/tkubica12/azure-networking-lab](https://github.com/tkubica12/azure-networking-lab)

## Disaster recovery with Azure Site Recovery
TBD

## VM monitoring
### VM Health and service map
Onboard VM to Azure monitor and check VM health page, performance metrics and service map

### Aggregating and searching logs
Open Logs and search for logs, use filtering and basic capabilities of Kusto language

### Metrics and adding guest-based metrics
Open Metrics page and create your own views and pin them to dashboard. Install guest-level agent to gather other metrics such as file-system or memory usage.

### Create alert
Create alert based on metrics. We will use dynamic threashold (ML-based alert) and CPU usage and setup Action Group to send push notification to Azure mobile application. Generate CPU load on machine and wait for alert to popup in Azure mobile application.

### Creating workbook
Follow instructor to create your own workbook adding some metrics and some log views.

### Update management
Create Automation Account and onboard VM to it. Check missing updates and learn how to plan patching deployments.

### Inventory and change tracking
Investigate invetory tracking for list of installed components and applications as well as change tracking to see history.

### Integrated configuration management with PowerShell DSC
Import PowerShell DSC to install IIS, onboard VM to Azure Automation Configuration Management and check IIS is getting installed.

## You homework
TBD