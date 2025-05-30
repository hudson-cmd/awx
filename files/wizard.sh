#!/bin/bash

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Caminhos
DESTINO="/home/suporte/backup_envio"
CERT_DIR="/etc/pki/tls"
REDE_DIR="/etc/sysconfig/network-scripts"
BACKUP_DIR="/var/uscallbackup"
CODEC_PATH="/usr/lib64/asterisk/modules/codec_g729.so"
LOGFILE="/var/log/wizard_envio.log"
ARQUIVO_TAR="/home/suporte/backup_envio.tar.gz"

# Início do log
mkdir -p "$(dirname "$LOGFILE")"
exec > >(tee -a "$LOGFILE") 2>&1
echo -e "\n==== Início do wizard - $(date) ===="

echo -e "${CYAN}--- Assistente de Backup e Envio - Union Telecom ---${NC}"

# Verifica sshpass
if ! command -v sshpass &> /dev/null; then
    echo -e "${RED}[ERRO] sshpass não está instalado.${NC}"
    echo "  sudo yum install -y sshpass"
    exit 1
fi

# Criação da pasta
mkdir -p "$DESTINO"
echo -e "${GREEN}[✓] Pasta de destino preparada: $DESTINO${NC}"

# Copia o último backup
echo -e "${CYAN}[+] Copiando o último backup...${NC}"
ULTIMO_BACKUP=$(ls -t "$BACKUP_DIR" 2>/dev/null | head -n 1)

if [ -n "$ULTIMO_BACKUP" ]; then
    cp "$BACKUP_DIR/$ULTIMO_BACKUP" "$DESTINO/"
    echo -e "${GREEN}[✓] Backup copiado: $ULTIMO_BACKUP${NC}"
else
    echo -e "${YELLOW}[!] Nenhum backup encontrado em $BACKUP_DIR${NC}"
fi

# Copia arquivos de rede
echo -e "${CYAN}[+] Copiando arquivos de rede...${NC}"
cp $REDE_DIR/ifcfg-* "$DESTINO/" 2>/dev/null
cp $REDE_DIR/route-* "$DESTINO/" 2>/dev/null
echo -e "${GREEN}[✓] Arquivos de rede copiados${NC}"

# Copia certificados SSL
echo -e "${CYAN}[+] Copiando certificados SSL...${NC}"
cp "$CERT_DIR/certs/localhost.crt" "$DESTINO/" 2>/dev/null
cp "$CERT_DIR/private/localhost.key" "$DESTINO/" 2>/dev/null
echo -e "${GREEN}[✓] Certificados copiados${NC}"

# Copia codec G.729
if [ -f "$CODEC_PATH" ]; then
    cp "$CODEC_PATH" "$DESTINO/"
    echo -e "${GREEN}[✓] Codec G.729 copiado${NC}"
else
    echo -e "${YELLOW}[!] Codec G.729 não encontrado${NC}"
fi

# Opção para compactar os arquivos
echo -e "${CYAN}[?] Deseja compactar os arquivos em .tar.gz antes do envio? (s/n)${NC}"
read -r COMPACTAR

if [[ "$COMPACTAR" =~ ^[sS]$ ]]; then
    tar -czf "$ARQUIVO_TAR" -C "$(dirname "$DESTINO")" "$(basename "$DESTINO")"
    echo -e "${GREEN}[✓] Arquivos compactados em: $ARQUIVO_TAR${NC}"
    ENVIO_PATH="$ARQUIVO_TAR"
else
    ENVIO_PATH="$DESTINO"
fi

# Solicita dados de envio
echo -e "${CYAN}[→] Digite os dados para envio SCP:${NC}"
read -p "IP de destino: " IP
read -p "Usuário remoto: " USUARIO
read -s -p "Senha do usuário: " SENHA
echo ""

# Teste de conexão
echo -e "${CYAN}[+] Testando conexão com $IP na porta 8222...${NC}"
timeout 5 bash -c "echo > /dev/tcp/$IP/8222" 2>/dev/null

if [ $? -ne 0 ]; then
    echo -e "${RED}[X] Conexão falhou. Verifique IP, rede ou firewall.${NC}"
    exit 1
else
    echo -e "${GREEN}[✓] Conexão com $IP bem-sucedida.${NC}"
fi

# Confirma envio
echo -e "${CYAN}[?] Confirmar envio para $USUARIO@$IP:/home/$USUARIO/? (s/n)${NC}"
read -r CONFIRMA

if [[ "$CONFIRMA" =~ ^[sS]$ ]]; then
    echo -e "${CYAN}[→] Enviando arquivos via SCP...${NC}"
    sshpass -p "$SENHA" scp -P 8222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r "$ENVIO_PATH" "$USUARIO@$IP:/home/$USUARIO/"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] Envio concluído com sucesso!${NC}"
    else
        echo -e "${RED}[X] Falha no envio via SCP.${NC}"
    fi
else
    echo -e "${YELLOW}[!] Envio cancelado pelo usuário.${NC}"
fi

echo -e "${CYAN}--- Fim do processo. Log salvo em $LOGFILE ---${NC}"
