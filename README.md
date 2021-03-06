# Azure Technical Academy - Hybrid IT Day 1: compute, storage, networking, backup/DR, monitoring
In first day of Azure Acedemy in Hybrid IT track we will focus on compute, storage, networking, backup, DR and monitoring. Each section comes with lot of content and time limit for each section. Try to finish as much as you can. What is left, take as homework.

As some labs take long time to deploy, we will start deployment now and watch results later.

Deploy Azure Disk storage test. There are 12 tests to be run so select reasonable test time to finish. Also note VM extension has script running time limited to 90 minutes so if you need to run tests with long times (such as 60 minutes per test) choose 1 seconds and rerun script manualy (sudo /var/lib/waagent/custom-script/download/0/test.sh 600). For our lab select 120 seconds.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fazurecz%2Fazuretechacademy-hybridit-labs-day1%2Fmaster%2Fdisk-storage%2Fdeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

Deploy networking lab environment (keep prefix on default or use your own, but only with lowercase letters)

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fgithub.com%2Ftkubica12%2Fazure-networking-lab%2Fraw%2Fmaster%2FArmEnv%2Fmain.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

## Structure
* [Compute](https://github.com/azurecz/azuretechacademy-hybridit-labs-day1#compute)
* [Backup](https://github.com/azurecz/azuretechacademy-hybridit-labs-day1#azure-backup)
* [Storage](https://github.com/azurecz/azuretechacademy-hybridit-labs-day1#storage)
* [Networking](https://github.com/azurecz/azuretechacademy-hybridit-labs-day1#networking)
* [Disaster recovery](https://github.com/azurecz/azuretechacademy-hybridit-labs-day1#disaster-recovery-with-azure-site-recovery)
* [Monitoring](https://github.com/azurecz/azuretechacademy-hybridit-labs-day1#vm-monitoring)
* [Agenda and next steps](https://github.com/azurecz/azuretechacademy-hybridit-labs-day1#agenda-and-next-steps)
* [Contacts](https://github.com/azurecz/azuretechacademy-hybridit-labs-day1#contacts)

## Compute
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

## Storage
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

Try to run some of tests yourself:
```
sudo -i
cd /root
fio --runtime 60 s-hdd-sync.ini
fio --runtime 60 p-ssd-sync.ini
fio --runtime 60 s-hdd-async.ini
fio --runtime 60 p-ssd-async.ini
```

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

## Networking
### Enterprise network scenario
![diagram](https://github.com/tkubica12/azure-networking-lab/raw/master/img/diagramNative.png)

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

## Disaster recovery with Azure Site Recovery
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

## VM monitoring
### VM Health and service map
Onboard VM to Azure monitor and check VM health page, performance metrics and service map

### Working with analytics queries
Open Logs and search for logs, use filtering and basic capabilities of Kusto language. Follow instructor to search and filter Event logs.

Follow instructor for step by step creation of queries. You will learn about key tables such as Event, Syslog, Perf or Updates, learn how to filter, summarize and use joins.

One of resulting query will combine information from Event, Updates and Perf tables:

```
Event
| where EventLevelName in ("Warning", "Error")
| summarize EventCount = count() by Computer, EventLevelName
| join kind= leftouter (
   Update
    | where Classification == "Critical Updates"  
    | where UpdateState == "Needed" 
    | summarize UpdatesMissing = count() by Computer  
) on Computer 
| project-away Computer1
| join kind= leftouter (
   Perf
    | where CounterName == "% Processor Time"
    | where ObjectName == "Processor Information" 
    | where InstanceName == "_Total" 
    | summarize CpuLoad99Percentile = strcat(round(percentile(CounterValue, 99), 1), ' %') by Computer 
) on Computer
| project-away Computer1
```

You will also use bin aggregation by time to generate time chart:

```
Perf
| where TimeGenerated >= ago(1h)
| where ObjectName == "Processor" 
| where CounterName == "% Processor Time" 
| where InstanceName == "_Total" 
| summarize CpuLoad = round(percentile(CounterValue, 95), 1) by bin(TimeGenerated, 5m), Computer
| render timechart 
```

### Creating workbook
Let's search for underutilized servers so we can potentially downsize and save costs.

Try this query. We will calculate CPU load on percentile (average is not good metric, you typically want to see 90th, 95th or 99th percentile or 100rh percentile which is maximum). Because we want to easily change percentile make it variable (let command).

```
let Percentile=90;
Perf
| where CounterName == "% Processor Time" 
| where ObjectName == "Processor" 
| where InstanceName == "_Total" 
| summarize cpuLoad=percentile(CounterValue, Percentile) by Computer
| sort by cpuLoad asc
```

Let's another example - we will print load of individual processes on computer.
```
let Percentile=90;
Perf
| where CounterName == "% Processor Time" 
| where ObjectName == "Process" 
| summarize processCpuLoad=percentile(CounterValue, Percentile) by _ResourceId, InstanceName
| sort by processCpuLoad desc
```

We will now create Workbook. Create new Workbook in Azure Monitor -> Workbooks -> Empty. First add text with something like Underutilization report. Use first query for Add Query and select grid as output and use Logs as data source, Log analytics workspace and select yours.

Next we will want to make this view look better. First replace Computer with _ResourceId so Azure VM is clickable.

```
let Percentile=90;
Perf
| where CounterName == "% Processor Time" 
| where ObjectName == "Processor" 
| where InstanceName == "_Total" 
| summarize cpuLoad=percentile(CounterValue, Percentile) by _ResourceId
| sort by cpuLoad asc
```

We will now graphically signal resources that are underutilized and overutilized. Click Column Settings and use Threashold renderer using Icons for cpuLoad column. Add following icons:
* <= 15 to blue information icon and text {0}{1} (Underutilized)
* <= 90 to green available icon and text {0}{1} (OK)
* Default to red error icon and text {0}{1} (overutilized)

Also select Cusom number formatting and set Units to Percentage, Style Decimal and Maximum fractional digits to 2.

Click Apply and Save and Close.

We will want user to be able to select percentile. Add Parameters, name selectedPercentile, display name Percentile, Drop Down, click required and use following JSON to define options:

```json
[
    { "value": 50, "label": "50th"},
    { "value": 75, "label": "75th"},
    { "value": 90, "label": "90th"},
    { "value": 95, "label": "95th"},
    { "value": 99, "label": "99th"},
    { "value": 100, "label": "100th"}
]
```

Modify query to react on selected percentile:
```
let Percentile={selectedPercentile};
Perf
| where CounterName == "% Processor Time" 
| where ObjectName == "Processor" 
| where InstanceName == "_Total" 
| summarize cpuLoad = percentile(CounterValue, Percentile) by _ResourceId
| sort by cpuLoad asc
```

We will now make workbook interactive. When clicking on particular row we want to display per-process details for this computer in another grid bellow. Click Advanced Settings -> When an item is selected, export a parameter and export parameter _ResourceId as selectedResourceId with default value of NA. Also configure chart title and enable client-side search.

Add new query bellow.

```
let Percentile={selectedPercentile};
Perf
| where _ResourceId == "{selectedResourceId}"
| where CounterName == "% Processor Time" 
| where ObjectName == "Process" 
| summarize processCpuLoad=percentile(CounterValue, Percentile) by _ResourceId, InstanceName
| project processName=InstanceName, processCpuLoad
| sort by processCpuLoad desc
```

To make it look better use Column Settings and make processCpuLoad Bar with blue color and use Custom number formatting to limit friction decimals.

Click Advanced Settings and configure the following:
* Make this half screen by setting Make this item a custom width to 50
* Modify title to Server processes
* Enable client-side search with Show filter field above grid or tiles
* Hide this chart if no server is selected by clicking Make this item conditionally visible when selectedResourceId is not equal to NA

We now have interactive Workbook. Let's configure space on right side to include two time charts. One with time graph showing CPU load over time and one with CPU load over time for selected process.

Add query with Logs as data source for your Log Analytics workspace that will look like this:
```
let Percentile={selectedPercentile};
Perf
| where _ResourceId == "{selectedResourceId}"
| where CounterName == "% Processor Time" 
| where ObjectName == "Processor" 
| where InstanceName == "_Total" 
| summarize cpuLoad = percentile(CounterValue, Percentile) by _ResourceId, bin(TimeGenerated, 15m)
```

Set visualization to Time chart and Legend to Maximum value. Go to Advanced Settings and configure:
* Set Make this item a custom width to 50
* Hide this chart if no server is selected by clicking Make this item conditionally visible when selectedResourceId is not equal to NA
* Modify chart title to CPU load

**Unguided task**

You now have all information to solve the following task. Add time chart to show CPU load over time for selected process. Use full wide screen but tiny size (lenght).

Resulting workbook should look like this:
![](images/workbookImage1.png)
![](images/workbookImage2.png)

Note that in todays lab our servers might run just for few hours. For practical use of this report gather more date and modify all queries to have Time range of Last 30 days.

#### Homework 1
Instead of fixed time (such as Last 30 days) make this parameter on top (choose from last 7, 30 and 90 days) and make it part of your query.

#### Homework 2
Create workbook to show Critical logs from all computers. When computer is selected show all logs.

### Metrics and adding guest-based metrics
Open Metrics page and create your own views and pin them to dashboard. Install guest-level agent to gather other metrics such as file-system or memory usage.

### Create alert
Create alert based on metrics. We will use dynamic threashold (ML-based alert) and CPU usage and setup Action Group to send push notification to Azure mobile application. Generate CPU load on machine and wait for alert to popup in Azure mobile application.

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
Prerequisites: 
- Compute lab completed
- Complete Azure Backup section steps 1-3 (Backup section on VM in portal)
- Turn on compute lab few days before training to collect data
- If you want to have more data collected onboard monitoring solutions few days before training in following sections of VM configuration in Portal and use one Log Analytics workspace and Automation Account you will create in wizard:
  - Update Management
  - Inventory
  - Change Tracking
  - Insights
  - Enable guest-level monitoring in Diagnostic settings

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

Follow this [instructions](homework/readme.md).

# Contacts

## Tomas Kubica - Azure TSP at Microsoft
- https://www.linkedin.com/in/tkubica
- https://github.com/tkubica12
- https://twitter.com/tkubica

## Jaroslav Jindrich - Cloud Solutions Architect
- https://www.linkedin.com/in/jjindrich
- https://github.com/jjindrich
- https://twitter.com/jjindrich_cz
