#!/bin/bash

# Caminho base onde estão os arquivos recebidos
ORIGEM="/home/suporte/backup_envio"

# Verificações de permissões
if [ "$EUID" -ne 0 ]; then
  echo "[ERRO] Rode como root para mover arquivos do sistema."
  exit 1
fi

# Verificar se a pasta existe
if [ ! -d "$ORIGEM" ]; then
  echo "[ERRO] A pasta $ORIGEM não existe. Certifique-se de que os arquivos foram recebidos."
  exit 1
fi

echo "[+] Restaurando arquivos de rede para /etc/sysconfig/network-scripts/"
cp -f "$ORIGEM"/ifcfg-* "$ORIGEM"/route-* /etc/sysconfig/network-scripts/ 2>/dev/null


echo "[+] Movendo arquivos de backup para /var/uscallbackup/"
mkdir -p /var/uscallbackup/
cp -f "$ORIGEM"/*.tar.gz /var/uscallbackup/ 2>/dev/null
cp -f "$ORIGEM"/*.bak /var/uscallbackup/ 2>/dev/null

echo "[✓] Arquivos copiados e substituídos com sucesso."

