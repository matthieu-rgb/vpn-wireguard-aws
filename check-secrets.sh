#!/bin/bash

echo "Verification des secrets dans Git..."
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0

# 1. Verifier les fichiers sensibles
echo "1. Verification des fichiers sensibles..."

DANGEROUS_FILES=(
  "*.pem"
  "*.key"
  "terraform.tfstate"
  "terraform.tfstate.backup"
  "*.conf"
  "*.tfvars"
  "vpn-config.sh"
)

for pattern in "${DANGEROUS_FILES[@]}"; do
  files=$(git ls-files | grep "$pattern" 2>/dev/null)
  if [ -n "$files" ]; then
    echo -e "${RED}[DANGER]${NC} Fichier sensible trouve : $files"
    ERRORS=$((ERRORS + 1))
  fi
done

# 2. Verifier les credentials hardcodes dans les fichiers
echo ""
echo "2. Verification des credentials hardcodes..."

# Instance IDs AWS
git grep -n -E 'i-[0-9a-f]{8,17}' -- '*.sh' '*.tf' 2>/dev/null | while read -r line; do
  if ! echo "$line" | grep -q -E "example|template|XXXXX|INSTANCE_ID="; then
    echo -e "${YELLOW}[ATTENTION]${NC} Possible Instance ID : $line"
  fi
done

# IPs publiques
git grep -n -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' -- '*.sh' '*.tf' 2>/dev/null | while read -r line; do
  if ! echo "$line" | grep -q -E "example|template|X.X.X.X|0.0.0.0|10.8.0|VPN_IP="; then
    echo -e "${YELLOW}[ATTENTION]${NC} Possible IP publique : $line"
  fi
done

# 3. Verifier que .gitignore existe
echo ""
echo "3. Verification du .gitignore..."

if [ ! -f ".gitignore" ]; then
  echo -e "${RED}[DANGER]${NC} Fichier .gitignore manquant !"
  ERRORS=$((ERRORS + 1))
else
  echo -e "${GREEN}[OK]${NC} .gitignore present"
  
  # Verifier que .gitignore contient les patterns importants
  critical_patterns=("*.pem" "*.key" "terraform.tfstate")
  for pattern in "${critical_patterns[@]}"; do
    if ! grep -q "$pattern" .gitignore; then
      echo -e "${YELLOW}[ATTENTION]${NC} .gitignore ne contient pas : $pattern"
    fi
  done
fi

# 4. Verifier les cles AWS
echo ""
echo "4. Verification des cles AWS..."

# AWS Access Key
if git grep -n -E 'AKIA[0-9A-Z]{16}' -- . 2>/dev/null; then
  echo -e "${RED}[DANGER]${NC} Cle AWS Access Key detectee !"
  ERRORS=$((ERRORS + 1))
fi

# AWS Secret Key (pattern approximatif)
if git grep -n -E 'aws_secret_access_key.*[0-9a-zA-Z/+=]{40}' -- . 2>/dev/null; then
  echo -e "${RED}[DANGER]${NC} Possible AWS Secret Key detectee !"
  ERRORS=$((ERRORS + 1))
fi

# 5. Verifier terraform.tfstate
echo ""
echo "5. Verification terraform.tfstate..."

if git ls-files | grep -q "terraform.tfstate"; then
  echo -e "${RED}[DANGER]${NC} terraform.tfstate est tracke par Git !"
  echo "Executer : git rm --cached terraform.tfstate"
  ERRORS=$((ERRORS + 1))
else
  echo -e "${GREEN}[OK]${NC} terraform.tfstate n'est pas tracke"
fi

# Resultat final
echo ""
echo "========================================"
if [ $ERRORS -eq 0 ]; then
  echo -e "${GREEN}Aucun probleme critique detecte !${NC}"
  echo "Vous pouvez pusher."
  echo ""
  echo "Note: Verifiez quand meme manuellement les avertissements jaunes ci-dessus."
  exit 0
else
  echo -e "${RED}$ERRORS probleme(s) critique(s) detecte(s) !${NC}"
  echo ""
  echo "NE PAS PUSHER avant de corriger :"
  echo "1. Ajouter les fichiers sensibles dans .gitignore"
  echo "2. Executer : git rm --cached <fichier>"
  echo "3. Relancer ce script"
  exit 1
fi
