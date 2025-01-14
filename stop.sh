#!/bin/bash
for i in filter nat
do
# La politique par défaut est de tout accetper
iptables -P $i ACCEPT
# Effacer toutes les règles dans chaque table
iptables -F $i
done
