#!/bin/bash

# ============================================
# Script d'installation de l'agent Zabbix 2
# ============================================

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Variables de configuration
ZABBIX_SERVER="10.0.0.108"
ZABBIX_CONF="/etc/zabbix/zabbix_agent2.conf"

# Vérification root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Ce script doit être exécuté en root${NC}"
    exit 1
fi

# Détection de la distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    echo -e "${RED}Distribution non supportée${NC}"
    exit 1
fi

echo -e "${YELLOW}Installation de l'agent Zabbix 2...${NC}"

# Installation selon la distribution
case $OS in
    ubuntu|debian)
        wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4+ubuntu${VERSION}_all.deb
        dpkg -i zabbix-release_6.0-4+ubuntu${VERSION}_all.deb
        apt update -y
        apt install -y zabbix-agent2
        ;;
    centos|rhel|rocky|almalinux)
        rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/${VERSION}/x86_64/zabbix-release-6.0-4.el${VERSION}.noarch.rpm
        dnf install -y zabbix-agent2
        ;;
    *)
        echo -e "${RED}Distribution non supportée : $OS${NC}"
        exit 1
        ;;
esac

echo -e "${YELLOW}Configuration de l'agent...${NC}"

# Configuration de l'agent
sed -i "s/^Server=.*/Server=${ZABBIX_SERVER}/" $ZABBIX_CONF
sed -i "s/^ServerActive=.*/ServerActive=${ZABBIX_SERVER}/" $ZABBIX_CONF

# Suppression de la ligne Hostname pour utiliser le hostname de la machine
sed -i "s/^Hostname=.*/#Hostname=/" $ZABBIX_CONF

# Activation et démarrage du service
echo -e "${YELLOW}Démarrage du service...${NC}"
systemctl enable zabbix-agent2
systemctl restart zabbix-agent2

# Vérification du service
if systemctl is-active --quiet zabbix-agent2; then
    echo -e "${GREEN}✅ L'agent Zabbix 2 est installé et démarré avec succès${NC}"
    echo -e "${GREEN}✅ Serveur configuré : ${ZABBIX_SERVER}${NC}"
    echo -e "${GREEN}✅ Hostname utilisé : $(hostname)${NC}"
else
    echo -e "${RED}❌ Erreur lors du démarrage de l'agent${NC}"
    systemctl status zabbix-agent2
    exit 1
fi
