#!/bin/bash

#iptables -L FORWARD -n -v  pour afficher le nombre de paquet par protocole
#ssh -p 61337 user@192.168.129.91


for i in INPUT OUTPUT FORWARD
do
iptables -P $i DROP
iptables -A $i -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
done

#lo INPUT
iptables -A INPUT -i lo -j ACCEPT
#lo OUTPUT
iptables -A OUTPUT -o lo -j ACCEPT

#le pare feu ping vers l'extérieur, mais pas l'inverse
iptables -A OUTPUT -o enp0s3 -m icmp -p icmp --icmp-type echo-request -j ACCEPT
#seul le serv ping le parefeu
iptables -A INPUT -i enp0s9 -m icmp -p icmp --icmp-type echo-request -j ACCEPT
#ping lan client vers server
iptables -A FORWARD -s 192.168.1.0/24 -d 172.16.1.10 -i enp0s8 -o enp0s9 -p icmp --icmp-type echo-request -j ACCEPT
#autoriser l'administration du server à distance par le client
iptables -A FORWARD -s 192.168.1.0/24 -d 172.16.1.10 -i enp0s8 -o enp0s9 -m tcp -p tcp --dport 22 -j ACCEPT
#le client peut acceder au site web en http
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -s 192.168.1.0/24 -d 172.16.1.10 -i enp0s8 -o enp0s9 -m tcp -p tcp --dport 80 -j ACCEPT


#Resolution DNS de google 
iptables -A FORWARD -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -p tcp --dport 53 -j ACCEPT

#le client peut surfer en passant par le firewall
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o enp0s3 -j SNAT --to-source 192.168.129.91 #ip wan
iptables -A FORWARD -i enp0s8 -o enp0s3 -m icmp -p icmp --icmp-type echo-request -j ACCEPT

#Nombre de paquet 443
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s3 -m tcp -p tcp --dport 443 -j LOG --log-prefix "HTTPS_Communication:"
iptables -A FORWARD -i enp0s8 -o enp0s3 -m tcp -p tcp --dport 443 -j ACCEPT

# Un client côté WAN doit pouvoir accéder au serveur web 

iptables -t nat -A PREROUTING -d 192.168.129.91 -m tcp -p tcp --dport 80 -j DNAT --to-destination 172.16.1.10:80
iptables -A FORWARD -i enp0s3 -o enp0s9 -m tcp -p tcp --dport 80 -j ACCEPT

#un client coté wan  doit pouvoir se connecter en SSH au serveur Web en utilisant le port 61337

iptables -t nat -A PREROUTING -d 192.168.129.91 -m tcp -p tcp --dport 61337 -j DNAT --to-destination 172.16.1.10:22
iptables -A FORWARD -i enp0s3 -o enp0s9 -m tcp -p tcp --dport 22 -j ACCEPT