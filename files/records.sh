#!/bin/bash

# Perguntar informações ao usuário
read -p "Informe o IP do servidor de destino: " DEST_IP
read -p "Informe o usuário SSH: " DEST_USER
read -p "Informe a porta SSH (ex: 8222): " DEST_PORT

# Caminho de origem e destino
SRC="/var/spool/asterisk/"
DEST="${DEST_USER}@${DEST_IP}:/var/spool/asterisk/"

echo "Sincronizando arquivos..."
rsync -raptv -e "ssh -p${DEST_PORT}" "$SRC" "$DEST"

# Resultado
if [ $? -eq 0 ]; then
    echo "Transferência concluída com sucesso!"
else
    echo "Ocorreu um erro durante a transferência."
fi
