# Azure Technical Academy - Hybrid IT track 01


As some labs take long time to deploy, we will start deployment now and watch results later.

Deploy Azure Disk storage test. There are 10 tests to be run so select reasonable test time to finish, select 300 seconds.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fgithub.com%2Ftkubica12%2Fazure-networking-lab%2Fraw%2Fmaster%2FArmEnv%2Fmain.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

Deploy networking lab environment

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fgithub.com%2Ftkubica12%2Fazure-networking-lab%2Fraw%2Fmaster%2FArmEnv%2Fmain.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

## Compute

## Storage
### Performance decisions
Connect to storagetest VM you have deployed previously and check results of storage test. Types of disks are:
* Standard HDD S20 /disk/standardhdd (sdc)
* Standard SSD E20 /disk/standardssd (sdd)
* Premium SSD P20 /disk/premiumssd (sde)
* 4x Standard SSD E10 in LVM pool /disk/vg/lv (sdf, sdg, sdh, sdi)
* Local SSD /mnt (sdb)

Two tests are run on each volume:
* sync test random write (waiting for ACK after each transaction simulating legacy workload)
* async test random write (256 bulk operations with 4 threads simulating database workload)

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