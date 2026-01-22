# VPN WireGuard Personnel sur AWS

VPN personnel déployé sur AWS avec WireGuard et Terraform. Infrastructure as Code pour un VPN rapide, sécurisé et économique.

## Caractéristiques

- **WireGuard** : Protocole VPN moderne et performant
- **Terraform** : Infrastructure as Code reproductible
- **AWS EC2** : Instance t3.micro (Free Tier eligible)
- **Coût** : ~0.20 euro/mois avec usage start/stop (gratuit pendant 12 mois avec Free Tier)
- **Sécurité** : Chiffrement ChaCha20, authentification Poly1305

## Prérequis

- AWS CLI installé et configuré (`aws configure`)
- Terraform >= 1.0 installé
- WireGuard installé sur le client
- macOS (pour les scripts d'automatisation)

## Installation

### 1. Cloner le repository

```bash
git clone git@github.com:VOTRE_USERNAME/vpn-wireguard-aws.git
cd vpn-wireguard-aws
```

### 2. Configurer les variables

```bash
# Copier le template de configuration
cp vpn-config.sh.example vpn-config.sh

# Editer avec vos valeurs (apres le deploiement Terraform)
nano vpn-config.sh
```

### 3. Deployer l'infrastructure

```bash
# Initialiser Terraform
terraform init

# Verifier le plan
terraform plan

# Deployer
terraform apply
```

### 4. Recuperer les informations

```bash
# IP publique du serveur
terraform output vpn_server_public_ip

# Instance ID
terraform output vpn_server_instance_id

# Cle SSH privee
terraform output -raw ssh_private_key > vpn-key.pem
chmod 600 vpn-key.pem
```


## Utilisation

### Demarrer le VPN

```bash
# Demarrer l'instance
./vpn-manager.sh start

# Ou demarrage automatique avec connexion WireGuard
./vpn-manager.sh auto
```

### Arreter le VPN

```bash
./vpn-manager.sh stop
```

### Verifier l'etat

```bash
./vpn-manager.sh status
```

## Automatisation

- Script de demarrage/arret/automatique


## Structure du projet

```
vpn-wireguard-aws/
|- main.tf                           # Infrastructure AWS
|- variables.tf                      # Variables Terraform
|- outputs.tf                        # Outputs Terraform
|- wireguard-setup.sh                # Script d'installation WireGuard
|- vpn-manager.sh                    # Script de gestion (start/stop)
|- vpn-config.sh.example             # Template de configuration
|- .gitignore                        # Fichiers a ne pas pusher
|- README.md                         # Ce fichier

```

## Securite

### Fichiers sensibles (JAMAIS dans Git)

Les fichiers suivants sont dans `.gitignore` et ne doivent JAMAIS etre pushes :

- `*.pem` : Cles SSH privees
- `*.key` : Cles WireGuard privees
- `terraform.tfstate` : Etat Terraform (contient tous les secrets)
- `*.conf` : Configurations WireGuard
- `vpn-config.sh` : Configuration avec vos valeurs

### Avant de pusher

Lancer le script de verification :

```bash
./check-secrets.sh
```

### Bonnes pratiques

- Garder le repository PRIVE
- Utiliser des variables d'environnement pour les secrets
- Regenerer les cles si elles sont exposees
- Faire un backup de `terraform.tfstate` localement

## Cout

### Pendant Free Tier (12 premiers mois)

- Instance EC2 t3.micro : 0 euro (750h/mois gratuit)
- Stockage EBS 8GB : 0 euro (30GB gratuit)
- Transfert OUT : 0 euro (100GB/mois gratuit)
- **Total : 0 euro/mois**

### Apres Free Tier

Avec usage start/stop (60h/mois) :
- Instance EC2 : ~0.68 euro/mois
- Elastic IP (quand instance stoppee) : ~0 euro (on peut detacher)
- **Total : ~0.20-0.60 euro/mois**

## Troubleshooting

### Le tunnel s'etablit mais pas d'Internet

Verifier les regles iptables sur le serveur :

```bash
ssh -i vpn-key.pem ubuntu@VOTRE_IP

sudo iptables -t nat -L POSTROUTING -v -n
sudo iptables -L FORWARD -v -n
```

Les compteurs doivent augmenter pendant l'utilisation.

### Instance ne demarre pas

Verifier l'etat :

```bash
aws ec2 describe-instances --instance-ids VOTRE_INSTANCE_ID --region eu-central-1
```

Voir les logs cloud-init :

```bash
ssh -i vpn-key.pem ubuntu@VOTRE_IP
tail -f /var/log/cloud-init-output.log
```



## Credits

Projet realise dans le cadre de la formation en cybersecurite chez Jedha Academy.

## License

Usage personnel uniquement
