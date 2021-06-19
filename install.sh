#!/bin/bash

echo -e -n "Nome do diretório BASE da Wise (ex: /opt/WiseDb): "
read WDIR
echo -e -n "Nome do usuário ADMIN da Wise (ex: admin_wise): "
read WUSER

export WISE_BASE_DIR=$WDIR
export WISE_ADMIN_USER=$WUSER

# as ROOT: create Groups and Users
groupadd wisedb
useradd $WISE_ADMIN_USER -g wisedb -G wheel
usermod --password $(openssl passwd -1 nomanager) $WISE_ADMIN_USER

su - $WISE_ADMIN_USER
ssh-keygen -b 2048 -f ~/.ssh/id_rsa -t rsa -q -N ""
echo -e "\n\nEntre no repositório da Wise: https://github.com/WiseDB/Customer_Master/settings/keys"
echo -e "e adicione a chave abaixo:\n"
cat ~/.ssh/id_rsa.pub
read -n 1 -s -r -p "\nTecle algo para continuar a instalação ou CTRL+C para cancelar."
exit
