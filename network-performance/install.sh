# Install tools
apt update
apt install -y iperf qperf

# Enable iperf server
cat <<EOF >/etc/systemd/system/iperf.service
[Unit]
Description=iperf server
After=syslog.target network.target auditd.service

[Service]
ExecStart=/usr/bin/iperf -s

[Install]
WantedBy=multi-user.target
EOF

systemctl enable iperf
systemctl start iperf

# Enable qperf server
cat <<EOF >/etc/systemd/system/qperf.service
[Unit]
Description=qperf server
After=syslog.target network.target auditd.service

[Service]
ExecStart=/usr/bin/qperf

[Install]
WantedBy=multi-user.target
EOF

systemctl enable qperf
systemctl start qperf
