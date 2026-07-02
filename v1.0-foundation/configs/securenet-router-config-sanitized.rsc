# 2026-07-02 06:26:21 by RouterOS 7.21.4
# system id = <REDACTED>
#
/interface ethernet
set [ find default-name=ether1 ] disable-running-check=no
set [ find default-name=ether2 ] disable-running-check=no
set [ find default-name=ether3 ] disable-running-check=no
set [ find default-name=ether4 ] disable-running-check=no
/ip hotspot profile
add dns-name=hotspot.securenet.local hotspot-address=192.168.10.1 name=hsprof1
add dns-name=login.securenet.id hotspot-address=192.168.20.1 name=hsprof2
/ip pool
add name=POOL_IT ranges=192.168.10.2-192.168.10.254
add name=POOL_GUEST ranges=192.168.20.2-192.168.20.254
/ip hotspot
add address-pool=POOL_GUEST disabled=no interface=ether4 name=HOTSPOT_GUEST \
    profile=hsprof2
/queue simple
add max-limit=5M/5M name=Limit-Guest target=192.168.20.0/24
add max-limit=20M/20M name=Limit-IT target=192.168.10.0/24
/ip address
add address=192.168.100.1/24 interface=ether2 network=192.168.100.0
add address=192.168.10.1/24 interface=ether3 network=192.168.10.0
add address=192.168.20.1/24 interface=ether4 network=192.168.20.0
/ip dhcp-client
add interface=ether1
/ip dhcp-server
add address-pool=POOL_IT interface=ether3 name=DHCP_IT
add address-pool=POOL_GUEST interface=ether4 name=DHCP_GUEST
/ip dhcp-server network
add address=192.168.10.0/24 dns-server=8.8.8.8 gateway=192.168.10.1
add address=192.168.20.0/24 comment="hotspot network" gateway=192.168.20.1
/ip dns
set allow-remote-requests=yes cache-size=5120KiB servers=8.8.8.8,8.8.4.4
/ip firewall address-list
add address=192.168.10.0/24 list=IT_list
add address=192.168.20.0/24 list=Guest_list
/ip firewall filter
add action=drop chain=forward comment="Blokir Guest ke IT" dst-address-list=\
    IT_list src-address-list=Guest_list
add action=drop chain=input comment="Blokir Akses Guest ke Gateway IT" \
    dst-address=192.168.10.1 src-address=192.168.20.0/24
add action=drop chain=forward comment="Blokir akses Guest ke IT" dst-address=\
    192.168.10.0/24 src-address=192.168.20.0/24
add action=passthrough chain=unused-hs-chain comment=\
    "place hotspot rules here" disabled=yes
add action=log chain=forward dst-address=192.168.10.0/24 log-prefix=\
    "SECURITY ALERT: " src-address=192.168.20.0/24
add action=drop chain=forward in-interface=ether4 out-interface=ether3
/ip firewall nat
add action=passthrough chain=unused-hs-chain comment=\
    "place hotspot rules here" disabled=yes
add action=masquerade chain=srcnat out-interface=ether1
add action=masquerade chain=srcnat comment="masquerade hotspot network" \
    src-address=192.168.10.0/24
add action=masquerade chain=srcnat out-interface=ether1
add action=masquerade chain=srcnat comment="masquerade hotspot network" \
    src-address=192.168.20.0/24
/ip hotspot user
add name=admin
add name=guest
/system scheduler
add interval=1d name=Jadwal-Backup on-event=auto-backup policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=2026-06-30 start-time=23:00:00
/system script
add dont-require-permissions=no name=auto-backup owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=\
    "/export file=backup-mikrotik-"
/tool sniffer
set filter-interface=ether2 streaming-server=192.168.10.10
