# ОЧЕНЬ ВАЖНО!!! Самое важное как только задеплоен сервер подключиться по ssh и поменять пароль администратора, так как по умолчанию CHR будет admin без пароля.

/user add name=ADMINISTRATOR password=PASSWORD group=full
/user remove admin

# Далее манипуляции уже выполняем уже от созданного нами администратора.

# Нам нужен только первый порт.

/interface ethernet
set [ find default-name=ether1 ] comment=WAN
set [ find default-name=ether2 ] disabled=yes

# Создадим интерфейс листы.

/interface list
add name=WAN
add name=LAN
add name=VPN
add name=PUBLIC
add name=MANAGEMENT

# Добавим eth1 в листы.

/interface list member
add interface=ether1 list=WAN

# Так как мы подключены извне то и все отсальные тоже могут подключиться так же.
# Нужно срочно создать firewall. Это примерный пак того что может нам понадобиться.
# Все службы подписаны, останется включить только нужные нам.

/ip firewall filter
add action=accept chain=input comment="Accept Established/Related" connection-state=established,related in-interface=ether1
add action=drop chain=input comment="Drop Invalid" connection-state=invalid in-interface=ether1
add action=accept chain=input comment="Accept ICMP" protocol=icmp
add action=accept chain=input comment="Accept DNS" dst-port=53 protocol=udp
add action=accept chain=input comment="Accept DNS" dst-port=53 protocol=tcp
add action=accept chain=input comment="Accept NTP" dst-port=123 protocol=udp
add action=accept chain=input comment="Accept NTP" dst-port=123 protocol=tcp
add action=accept chain=input comment="Accept SNMP" disabled=yes dst-port=161-162 in-interface=!ether1 protocol=udp
add action=accept chain=input comment="Accept SNMP" disabled=yes dst-port=161-162 in-interface=!ether1 protocol=tcp
add action=accept chain=input comment="Accept WinBox" dst-port=8291 protocol=tcp
add action=accept chain=input comment="Accept SSH" dst-port=22 protocol=tcp
add action=accept chain=input comment="Accept GRE" disabled=yes in-interface=ether1 protocol=gre
add action=accept chain=input comment="Accept PPTP" disabled=yes dst-port=1723 in-interface=ether1 protocol=tcp
add action=accept chain=input comment="Accept L2TP" disabled=yes dst-port=1701 in-interface=ether1 protocol=udp
add action=accept chain=input comment="Accept L2TP" disabled=yes dst-port=1701 in-interface=ether1 protocol=tcp
add action=accept chain=input comment="Accept IKE" disabled=yes dst-port=500 in-interface=ether1 protocol=udp
add action=accept chain=input comment="Accept IKE" disabled=yes dst-port=4500 in-interface=ether1 protocol=udp
add action=accept chain=forward comment="Accept IPSec-ESP" disabled=yes in-interface=ether1 protocol=ipsec-esp
add action=accept chain=forward comment="Accept IPSec-AH" disabled=yes in-interface=ether1 protocol=ipsec-ah
add action=accept chain=input comment="Accept to local loopback (for CAPsMAN)" disabled=yes dst-address=127.0.0.1
add action=drop chain=input comment="Drop All" in-interface=ether1
add action=accept chain=forward comment="Accept in ipsec policy" disabled=yes ipsec-policy=in,ipsec
add action=accept chain=forward comment="Accept out ipsec policy" disabled=yes ipsec-policy=out,ipsec
add action=accept chain=forward comment="Accept Established/Related" connection-state=established,related in-interface=ether1
add action=accept chain=forward comment="Accept Output" out-interface=ether1
add action=drop chain=forward comment="Drop Invalid" connection-state=invalid in-interface=ether1
add action=drop chain=forward comment="Drop all from WAN not DSTNATed" connection-nat-state=!dstnat connection-state=new in-interface=ether1

# Сразу же выключим не нужные нам службы, оставим только SSH и WinBox.

/ip service
set telnet disabled=yes
set ftp disabled=yes
set www disabled=yes
set api disabled=yes
set api-ssl disabled=yes

# Можно создать пачку адресных листов по примеру

/ip firewall address-list
add address=google.com disabled=yes list="G Suite"
add address=gmail.com disabled=yes list="G Suite"
add address=login.microsoftonline.com disabled=yes list="Microsoft Office 365"
add address=login.microsoft.com disabled=yes list="Microsoft Office 365"
add address=login.windows.net disabled=yes list="Microsoft Office 365"
add address=224.0.0.0/4 list=MulticastAll
add list=none
add address=0.0.0.0/0 list=all
add address=224.0.0.1 list=MulticastAllHosts
add address=224.0.0.2 list=MulticastAllRouters
add address=224.0.0.5-224.0.0.6 list=MulticastOSPF
add address=224.0.0.10 list=MulticastEIGRP
add address=224.0.0.251 list=MulticastBonjour

# Запустим Src NAT для нашего DHCP Client.

/ip firewall nat
add action=masquerade chain=srcnat comment=WAN-out out-interface=ether1

# Можно включить функционал, вдруг будет необходимо.

/ip firewall service-port
set irc disabled=no
set rtsp disabled=no

# Слегка отредактируем то как сервер получает интернет.
# Мы хотим задать свои DNS и NTP

/ip dhcp-client
add interface=ether1 use-peer-dns=no use-peer-ntp=no

# Добавим глобальные DNS, например Cisco DNS.

/ip dns
set allow-remote-requests=yes cache-size=10240KiB servers=208.67.222.222,208.67.220.220

# IPv6 нам так же не нужен, отключаем.

/ipv6 settings
set disable-ipv6=yes

# Укажем часовой пояс, например если наш сервер в Германии.
# Сконфигурируем службу времени.

/system clock
set time-zone-name=Europe/Berlin

/system ntp client
set enabled=yes

/system ntp server
set broadcast=yes enabled=yes manycast=yes multicast=yes

/system ntp client servers
add address=0.de.pool.ntp.org
add address=1.de.pool.ntp.org
add address=2.de.pool.ntp.org
add address=3.de.pool.ntp.org

# Samba на сервере нам не нужна

/ip smb users
set [ find default=yes ] disabled=yes

# Можем включитьпростой протокол менеджмента сети.

/snmp
set contact=youremail enabled=yes location="Germany" trap-generators=interfaces trap-version=2

# Зададим hostname.

/system identity
set name=do-srv

# Допустим мы хотим светить сервером только в тунели

/tool mac-server
set allowed-interface-list=VPN
/tool mac-server mac-winbox
set allowed-interface-list=VPN
/ip neighbor discovery-settings
set discover-interface-list=VPN

# Можем включить RoMON для менеджмента железками через сервер.
# Порт у нас единственный, это ether1

/tool romon
set enabled=yes id= [:put [/interface ethernet get ether1 mac-address]]

# Зададим диапазон для наших vpn клиентов.

/ip pool
add name=l2tp-ipsec-vpn-pool ranges=10.0.0.2-10.0.0.254

# Настройки профилей для L2TP+IPSec будут выглядеть примерно так. Для клиента и для сервера соответственно.

/ppp profile
add address-list="VPN Clients List" change-tcp-mss=yes dns-server=10.0.0.1 interface-list=VPN local-address=10.0.0.1 name=Server-L2TP+IPSec only-one=yes remote-address=l2tp-ipsec-vpn-pool use-encryption=required use-ipv6=no use-mpls=no
add address-list="VPN Servers List" change-tcp-mss=yes interface-list=VPN name=Client-L2TP+IPSec only-one=yes use-encryption=required use-ipv6=no use-mpls=no

# Настроем биндинг интерфейсов для пользователей.
# По опыту предварительно созданные интерфейсы работают стабильнее чем динамические.

/interface l2tp-server
add name=l2tp-in-user1 user=user1
add name=l2tp-in-user2 user=user2
add name=l2tp-in-user3 user=user3
add name=l2tp-in-user4 user=user4

# Создадим самих пользователей и сразу же добавим им адреса из нашего пула.

/ppp secret
add local-address=10.0.0.1 name=user1 profile=Server-L2TP+IPSec remote-address=10.0.0.2
add local-address=10.0.0.1 name=user2 profile=Server-L2TP+IPSec remote-address=10.0.0.3
add local-address=10.0.0.1 name=user3 profile=Server-L2TP+IPSec remote-address=10.0.0.4
add local-address=10.0.0.1 name=user4 profile=Server-L2TP+IPSec remote-address=10.0.0.5

# Настроим и запустим наш L2TP+IPSec vpn сервер.

/interface l2tp-server server
set authentication=mschap2 default-profile=Server-L2TP+IPSec enabled=yes max-mru=1400 max-mtu=1400 use-ipsec=yes

# Можно включить встроеный монитор интернета

/interface detect-internet
set detect-interface-list=WAN internet-interface-list=WAN lan-interface-list=VPN wan-interface-list=WAN

# Скрипт на перезагрузку каждый день в 4 утра, для примера.

/system scheduler
add interval=1d name=autoreboot on-event="/system reboot" policy=reboot start-date=2020-01-01 start-time=04:00:00
