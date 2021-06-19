#!/bin/bash

clear;
echo -e "Instalação do repositório da Wise Database Solutions"
echo -e "••••••••••••••••••••••••••••••••••••••••••••••••••••\n"
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

# Criação dos usuários da WiseDb
#useradd rodrigo_wise -g wisedb -G wheel,oinstall,dba
#usermod --password $(openssl passwd -1 nomanager) rodrigo_wise
#useradd fernando_wise -g wisedb -G wheel,oinstall,dba
#usermod --password $(openssl passwd -1 nomanager) fernando_wise
#useradd caio_wise -g wisedb -G oinstall,dba
#usermod --password $(openssl passwd -1 nomanager) caio_wise

sudo -H -u $WISE_ADMIN_USER bash -c 'ssh-keygen -b 2048 -f ~/.ssh/id_rsa -t rsa -q -N ""'
sudo -H -u $WISE_ADMIN_USER bash -c 'echo -e "\n\nEntre no repositório da Wise: \e[91mhttps://github.com/WiseDB/Customer_Master/settings/keys\e[0m"'
sudo -H -u $WISE_ADMIN_USER bash -c 'echo -e "E adicione a chave abaixo:\n"'
sudo -H -u $WISE_ADMIN_USER bash -c 'cat ~/.ssh/id_rsa.pub'
echo ""
read -n 1 -s -r -p "Após adicionar a chave SSH, tecle algo para continuar..."

# Criação e permissão do diretório
mkdir -p $WISE_BASE_DIR
chown -R $WISE_ADMIN_USER.wisedb $WISE_BASE_DIR
chmod g+w $WISE_BASE_DIR

echo ""
ls -lhd $WISE_BASE_DIR
echo "ADMIN_USER: "
read -n 1 -s -r -p "Press any key to continue..."
exit


sudo -H -u $WISE_ADMIN_USER bash -c 'git clone git@github.com:WiseDb/Customer_Master.git $WISE_BASE_DIR'

# Configurações finais do git
sudo -H -u $WISE_ADMIN_USER bash -c 'git config --global push.default simple'
sudo -H -u $WISE_ADMIN_USER bash -c 'git config --global user.email "wisedbadm@gmail.com"'
sudo -H -u $WISE_ADMIN_USER bash -c 'git config --global user.name  "Admin WiseDb"'

