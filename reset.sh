#!/bin/bash
for i in filter nat
do
# Réinitialiser le compteur de paquets pour toutes les règles dans chaque table
iptables -Z $i
done
