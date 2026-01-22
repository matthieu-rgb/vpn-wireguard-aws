#!/bin/bash

# Charger la configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/vpn-config.sh" ]; then
  source "$SCRIPT_DIR/vpn-config.sh"
else
  echo "ERREUR: Fichier vpn-config.sh manquant"
  echo "Copiez vpn-config.sh.example en vpn-config.sh et remplissez vos valeurs"
  exit 1
fi

case "$1" in
  start)
    echo "Demarrage de l'instance VPN..."
    aws ec2 start-instances --instance-ids $INSTANCE_ID --region $REGION > /dev/null
    echo "Attente du demarrage (30-60 secondes)..."
    aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION
    sleep 30
    echo "Instance VPN prete !"
    ;;
    
  stop)
    echo "Arret de l'instance VPN..."
    aws ec2 stop-instances --instance-ids $INSTANCE_ID --region $REGION > /dev/null
    echo "Instance VPN arretee."
    ;;
    
  status)
    STATE=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $REGION --query 'Reservations[0].Instances[0].State.Name' --output text)
    echo "Etat de l'instance: $STATE"
    if [ "$STATE" = "running" ]; then
      echo "IP: $VPN_IP"
    fi
    ;;
    
  auto)
    echo "Demarrage automatique..."
    aws ec2 start-instances --instance-ids $INSTANCE_ID --region $REGION > /dev/null
    aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION
    sleep 30
    scutil --nc start "VPN AWS" 2>/dev/null || echo "Activez WireGuard manuellement"
    echo "VPN demarre !"
    ;;
    
  *)
    echo "Usage: $0 {start|stop|status|auto}"
    exit 1
    ;;
esac
