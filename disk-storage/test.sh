echo "Mounting disks..."

# Standard HDD
(echo n; echo p; echo 1; echo; echo; echo w) | fdisk /dev/sdc > /dev/null 
mkfs -t ext4 /dev/sdc1 > /dev/null 
mkdir -p /disk/standardhdd 
mount /dev/sdc1 /disk/standardhdd
echo "UUID=$(blkid | grep -oP '/dev/sdc1: UUID="*"\K[^"]*')   /disk/standardhdd   ext4   defaults   1   2" >> /etc/fstab
chmod go+w /disk/standardhdd

# Standard SSD
(echo n; echo p; echo 1; echo; echo; echo w) | fdisk /dev/sdd > /dev/null 
mkfs -t ext4 /dev/sdd1 > /dev/null 
mkdir -p /disk/standardssd 
mount /dev/sdd1 /disk/standardssd
echo "UUID=$(blkid | grep -oP '/dev/sdd1: UUID="*"\K[^"]*')   /disk/standardssd   ext4   defaults   1   2" >> /etc/fstab
chmod go+w /disk/standardssd

# Premium SSD
(echo n; echo p; echo 1; echo; echo; echo w) | fdisk /dev/sde > /dev/null 
mkfs -t ext4 /dev/sde1 > /dev/null 
mkdir -p /disk/premiumssd 
mount /dev/sde1 /disk/premiumssd
echo "UUID=$(blkid | grep -oP '/dev/sde1: UUID="*"\K[^"]*')   /disk/premiumssd   ext4   defaults   1   2" >> /etc/fstab
chmod go+w /disk/premiumssd

# LVM
apt-get update > /dev/null 
apt-get install -y lvm2 > /dev/null
pvcreate /dev/sd[fghi]
vgcreate vg /dev/sd[fghi]
lvcreate --extents 100%FREE --stripes 4 --name lv vg
mkfs -t ext4 /dev/vg/lv  > /dev/null 
mkdir -p /disk/lvm 
mount /dev/vg/lv /disk/lvm
echo "UUID=$(blkid | grep -oP '/dev/vg/lv: UUID="*"\K[^"]*')   /disk/lvm   ext4   defaults   1   2" >> /etc/fstab
chmod go+w /disk/lvm

# Ultra SSD
# (echo n; echo p; echo 1; echo; echo; echo w) | fdisk /dev/sdj > /dev/null 
# mkfs -t ext4 /dev/sdj1 > /dev/null 
# mkdir -p /disk/ultrassd 
# mount /dev/sdj1 /disk/ultrassd
# echo "UUID=$(blkid | grep -oP '/dev/sdj1: UUID="*"\K[^"]*')   /disk/ultrassd   ext4   defaults   1   2" >> /etc/fstab
# chmod go+w /disk/ultrassd

echo "Installing FIO..."

# Install FIO
apt-get update > /dev/null 
apt-get -y install fio > /dev/null

# Create test files
cat <<EOF >/root/s-hdd-sync.ini
[global]
size=30g
direct=1
iodepth=1
ioengine=libaio
bs=8k

[writer1]
rw=randwrite
directory=/disk/standardhdd
EOF

cat <<EOF >/root/s-ssd-sync.ini
[global]
size=30g
direct=1
iodepth=1
ioengine=libaio
bs=8k

[writer1]
rw=randwrite
directory=/disk/standardssd
EOF

cat <<EOF >/root/lvm-sync.ini
[global]
size=30g
direct=1
iodepth=1
ioengine=libaio
bs=8k

[writer1]
rw=randwrite
directory=/disk/lvm
EOF

cat <<EOF >/root/p-ssd-sync.ini
[global]
size=30g
direct=1
iodepth=1
ioengine=libaio
bs=8k

[writer1]
rw=randwrite
directory=/disk/premiumssd
EOF

cat <<EOF >/root/u-ssd-sync.ini
[global]
size=30g
direct=1
iodepth=1
ioengine=libaio
bs=8k

[writer1]
rw=randwrite
directory=/disk/ultrassd
EOF

cat <<EOF >/root/l-ssd-sync.ini
[global]
size=12g
direct=1
iodepth=1
ioengine=libaio
bs=8k

[writer1]
rw=randwrite
directory=/mnt
EOF

cat <<EOF >/root/s-hdd-async.ini
[global]
size=30g
direct=1
iodepth=256
ioengine=libaio
bs=8k

[writer1]
rw=randwrite
directory=/disk/standardhdd
[writer2]
rw=randwrite
directory=/disk/standardhdd
[writer3]
rw=randwrite
directory=/disk/standardhdd
[writer4]
rw=randwrite
directory=/disk/standardhdd
EOF

cat <<EOF >/root/s-ssd-async.ini
[global]
size=30g
direct=1
iodepth=256
ioengine=libaio
bs=8k

[writer1]
rw=randwrite
directory=/disk/standardssd
[writer2]
rw=randwrite
directory=/disk/standardssd
[writer3]
rw=randwrite
directory=/disk/standardssd
[writer4]
rw=randwrite
directory=/disk/standardssd
EOF

cat <<EOF >/root/lvm-async.ini
[global]
size=30g
direct=1
iodepth=256
ioengine=libaio
bs=8k

[writer1]
rw=randwrite
directory=/disk/lvm
[writer2]
rw=randwrite
directory=/disk/lvm
[writer3]
rw=randwrite
directory=/disk/lvm
[writer4]
rw=randwrite
directory=/disk/lvm
EOF

cat <<EOF >/root/p-ssd-async.ini
[global]
size=30g
direct=1
iodepth=256
ioengine=libaio
bs=8k

[writer1]
rw=randwrite
directory=/disk/premiumssd
[writer2]
rw=randwrite
directory=/disk/premiumssd
[writer3]
rw=randwrite
directory=/disk/premiumssd
[writer4]
rw=randwrite
directory=/disk/premiumssd
EOF

cat <<EOF >/root/u-ssd-async.ini
[global]
size=30g
direct=1
iodepth=256
ioengine=libaio
bs=8k

[writer1]
rw=randwrite
directory=/disk/ultrassd
[writer2]
rw=randwrite
directory=/disk/ultrassd
[writer3]
rw=randwrite
directory=/disk/ultrassd
[writer4]
rw=randwrite
directory=/disk/ultrassd
EOF

cat <<EOF >/root/l-ssd-async.ini
[global]
size=4g
direct=1
iodepth=256
ioengine=libaio
bs=8k

[writer1]
rw=randwrite
directory=/mnt
[writer2]
rw=randwrite
directory=/mnt
[writer3]
rw=randwrite
directory=/mnt
[writer4]
rw=randwrite
directory=/mnt
EOF

# Test
cd /root
echo "Running sync tests"
sudo fio --runtime $1 s-hdd-sync.ini | tee s-hdd-sync.results
sudo fio --runtime $1 s-ssd-sync.ini | tee s-ssd-sync.results
sudo fio --runtime $1 lvm-sync.ini | tee lvm-sync.results
sudo fio --runtime $1 p-ssd-sync.ini | tee p-ssd-sync.results
# sudo fio --runtime $1 u-ssd-sync.ini | tee u-ssd-sync.results
sudo fio --runtime $1 l-ssd-sync.ini | tee l-ssd-sync.results

echo "Running async tests"
sudo fio --runtime $1 s-hdd-async.ini | tee s-hdd-async.results
sudo fio --runtime $1 s-ssd-async.ini | tee s-ssd-async.results
sudo fio --runtime $1 lvm-async.ini | tee lvm-async.results
sudo fio --runtime $1 p-ssd-async.ini | tee p-ssd-async.results
# sudo fio --runtime $1 u-ssd-async.ini | tee u-ssd-async.results
sudo fio --runtime $1 l-ssd-async.ini | tee l-ssd-async.results