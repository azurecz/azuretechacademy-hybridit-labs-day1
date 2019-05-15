# Azure Technical Academy - Hybrid IT track 01
In first day of Azure Acedemy in Hybrid IT track we will focus on compute, storage, networking, backup, DR and monitoring. Each section comes with lot of content and time limit for each section. Try to finish as much as you can. What is left, take as homework.

As some labs take long time to deploy, we will start deployment now and watch results later.

Deploy Azure Disk storage test. There are 12 tests to be run so select reasonable test time to finish. Also note VM extension has script running time limited to 90 minutes so if you need to run tests with long times (such as 60 minutes per test) choose 1 seconds and rerun script manualy (sudo /var/lib/waagent/custom-script/download/0/test.sh 600). For our lab select 120 seconds.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fazurecz%2Fazuretechacademy-hybridit-labs-day1%2Fmaster%2Fdisk-storage%2Fdeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

Deploy networking lab environment

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fgithub.com%2Ftkubica12%2Fazure-networking-lab%2Fraw%2Fmaster%2FArmEnv%2Fmain.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

## Compute (60 minutes limit)
![Schema](compute/schema.png)

Use attached [scripts](compute/scripts.ps1).

### Azure Backup
Note: It takes some time for Backup to be ready. Follow steps 1-3 and then we will continue with next section. After about 1 hour we will come back to continue from step 4.

1. Create Windows VM
2. Enable backup and create Backup Vault
3. Initiate backup by clicking Backup Now (it will create app-consistent snapshot by orchestrating with VSS in about 20 minutes and then we have to wait about 1 hour until backup is transfered from snapshot to vault)
4. Go to existing backup and click on restore file, map backup as iSCSI disk to your notebook following instructions
5. Unmount backup
6. Restore whole VM. You can either create new VM or replace existing (when replacing existing VM needs to be stopped first)

## Storage (90 minutes limit)
### Disk storage performance decisions
Connect to storagetest VM you have deployed previously and check results of storage test. Types of disks are:
* Standard HDD S20 /disk/standardhdd (sdc)
* Standard SSD E20 /disk/standardssd (sdd)
* Premium SSD P20 /disk/premiumssd (sde)
* 4x Standard SSD E10 in LVM pool /disk/vg/lv (sdf, sdg, sdh, sdi)
* Local SSD /mnt (sdb)
* 2x small Standard HDD with different cache settings /disk/uncached and /disk/cached
* (UltraSSD) - this is in private preview and requires being enrolled to it. Therefore there is separate template and test script for those who have been whitelisted to preview

Three tests are run:
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
* Check latency on sync tests, especialy clat percentiles (focus on 50th and 99th)

What to expect:
* For sync legacy-type access latency is most important factor for IOPS. Multiple disk does not help
* Latency is fluctulating on Standard HDD, much less on Standard SSD and is very stable on Premium SSD and Local SSD
* LVM IOPS with Standard SSDs is close to same size Premium SSD, but there is operational overhead to setup LVM and latency is more consistent with Premium SSD
* You can easily hit disk IOPS limit and achieve little more then specified
* With Local SSD you are reaching limit of your VM size, not storage limit (if you need extreme local non-redundant performance check L-series VMs)
* Always be aware of VM size limits, it makes no sense to buy P70 disk when connected to D2s_v3 VM type [https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes)
* UltraSSD performance is very high - check latency on 50th and 99th percentile, provisioned IOPS set to 14k to demonstrate you are limited by 12800 IOPS of D8s VM (actually it gets slightly higher). You can change provisioned IOPS for UltraSSD without turning VM off!

### Blob Storage
1. Create storage account v2 GRS-RA
2. Create container and upload some files
3. Use Storage Explorer to generate SAS token to access file
4. Make sure file is also readable on secondary endpoint (secondary region)
5. Move one file to Cool tier
6. Move one file to Archive tier
7. Create policy to automatically manage lifecycle of files:
   1. Move file to Cool after 1 day of inactivity
   2. Move file to Archive after 2 days of inactivity
   3. Delete file after 3 days of inactivity
8. Setup immutable policy so files in particular container cannot be removed for 2 days
9. Enable soft delete and observe behavior
10. Large-scale file copy with AzCopy v10
   1.  Install AzCopy v10 on it [https://docs.microsoft.com/cs-cz/azure/storage/common/storage-use-azcopy-v10](https://docs.microsoft.com/cs-cz/azure/storage/common/storage-use-azcopy-v10)
   2.  Use AzCopy to copy file from local to blob storage
11. Large-scale automated file copy with Data Box Gateway
    1.  Download Azure Data Box Gateway and install it in your hypervisor (use your PC or nested virtualization in Azure using Dv3 or Ev3 machine instance)
    2.  Connect Data Box to Azure and associate with storage account
    3.  Setup copy policies and rate limit
    4.  Via Azure portal create SMB share on your Data Box
    5.  Copy files locally to Data Box and observe files being synchronized to storage account in Azure

### Azure Files
1. Open storage account v2 create in previous step
2. Create file share
3. Map share to your local PC (Windows 10) via SMB3 or to VM in Azure (Windows or Linux)
4. Create text file and copy it to share
5. In Azure create snapshot of your share
6. Modify text file locally and make sure change propages to Azure
7. In your local Explorer right click on file and go to previous versions so you are able to restore previous version of your file
8. Setup Azure Backup to orchestrate snapshotting and backup of your Azure Files

## Networking (90 minutes limit)
### Enterprise network scenario
Follow network diagram and instructions in following repo to test comple of networking scenarios:
[https://github.com/tkubica12/azure-networking-lab](https://github.com/tkubica12/azure-networking-lab)

### Network performance testing
Deploy following template (eg. to netperf resource group) that will create 2x VM in zone 1 + 1x VM in zone 2 + 1x VM in different region and install throughput testing tool iperf and latency testing tool qperf.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fazurecz%2Fazuretechacademy-hybridit-labs-day1%2Fmaster%2Fnetwork-performance%2Fdeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

Connect to z1-vm1
```bash
export z1vm1=$(az network public-ip show -n z1-vm1-ip -g netperf --query ipAddress -o tsv)
ssh net@$z1vm1
```

Test bandwidth to vm2 in the same zone, vm3 in different zone and VM in different region.
```bash
sudo iperf -c z1-vm2 -i 1 -t 30
sudo iperf -c z2-vm3 -i 1 -t 30
sudo iperf -c 10.1.0.4 -i 1 -t 30  # secondary region via VNET peering
sudo iperf -c 10.1.0.4 -P16 -t 30  # multiple parallel sessions
```

Test latency to vm2 in the same zone and vm3 in different zone.
```bash
qperf -t 20 -v z1-vm2 tcp_lat
qperf -t 20 -v z2-vm3 tcp_lat
qperf -t 20 -v 10.1.0.4 tcp_lat
```

What we expect to happen and what to do?
* Network througput will be close to performance specified in documentation (8 Gbps for Standard_D16s_v3)
* Network throughput is pretty much the same within and across zone, but across zones might fluctulate a bit
* Throughput between regions is WAN link so expected to be slower. Typical behavior is that with single connection speed is very good, but slower than inside region, but using multiple sessions leads performance close to inside regions (but might fluctulate a bit more)
* Thanks to accelerated networking available on some machines including Standard_D16_v3 latency is very good
* Latency inside zone is usually better than latency across zones, but still very good (suitable for sync operations)
* Latency between regions is good for WAN link, but obviously suited more for async operations 
* **Do not use ping to test latency** - it has very low priority in Azure network as well as OS TCP/IP stack
* **Do not use file copy to test network throughput** as storage can be most limiting factor

## Disaster recovery with Azure Site Recovery (90 minutes)
We will work on scenario when IP address will retain during failover, check this [link](https://docs.microsoft.com/en-us/azure/site-recovery/site-recovery-retain-ip-azure-vm-failover#subnet-failover).

### Prepare this design
![Schema](asr/schema.png)

Use attached [scripts](asr/scripts.ps1).

Steps
- create vnets with peerings
- create primary Windows AD server with DNS zone
- setup DNS on vnets and join web server in Active Directory
- create app web server and configure IIS

### Configure ASR replication
Follow this steps https://docs.microsoft.com/en-us/azure/site-recovery/azure-to-azure-tutorial-enable-replication

### Test failover 
Try to access website after failover.

### Homework
Complete this scenario
![Schema](asr/schema-extended.png)

Challenges
- DNS routing
- complete scripts for deployment with infrastructure automation - dsc etc.
- complete scripts for failover - loadbalancer etc.

## VM monitoring (90 minutes limit)
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

# Agenda and next steps 

## Track1
Prerequisites: Azure Subscription with 100 cores quota

Training:
- Compute
- Storage
- Networking

Dates: Prague 15.5.19, Bratislava 4.6.

## Track2
Prerequisites: Compute lab completed

Notebook with:
- Azure CLI
- Visual Studio Code
- Azure Storage Explorer

Training:
- Backup
- ASR
- Monitoring
- VM operations

Dates: Prague 28.6.19

## Homework 1
Today we had a lot to cover and you might not have finished everything. As your homework redo the lab and finish all items there. You will have couple of week to do so. Follow documentation and chat with your peers in your Teams.

## Homework 2 - bridge to next training
After couple of weeks you will be assigned with additional homework - check Teams for details as they become available. You will have 1-2 months to finish this and provide required outputs privately to instructors. Check for notifications in Teams.

## Homework 3 - preparation for next training
2 weeks before next training you will receive full agenda and few instructions to check you are familiar with basics and study/practice should you need to get better prepared for next training.

## Contacts

### Tomas Kubica - Azure TSP at Microsoft
- https://www.linkedin.com/in/tkubica
- https://github.com/tkubica12
- https://twitter.com/tkubica

### Jaroslav Jindrich - Cloud Solutions Architect
- https://www.linkedin.com/in/jjindrich
- https://github.com/jjindrich
- https://twitter.com/jjindrich_cz
