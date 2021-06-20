#!/bin/bash

# Valida o usuário que está executando o script
if [ "$(whoami)" != "root" ]
then
	echo -e "ERRO: Este script deve ser executado com o usuário ROOT!"
	exit 1
fi

clear;
echo -e "••••••••••••••••••••••••••••••••••••••••••••••••••••"
echo -e "Instalação do repositório da Wise Database Solutions"
echo -e "••••••••••••••••••••••••••••••••••••••••••••••••••••\n"
echo -e -n "Nome do diretório BASE da Wise (ex: /opt/WiseDb): "
read WDIR
echo -e -n "Nome do usuário ADMIN da Wise (ex: admin_wise): "
read WUSER
echo -e -n "Nome do GRUPO principal da Wise (ex: wisedb): "
read WGROUP

export WISE_BASE_DIR=$WDIR
export WISE_ADMIN_USER=$WUSER
export WISE_ADMIN_GROUP=$WGROUP

echo -e "\nInstalando pacotes necessários\n"
yum -y install screen
yum -y install git
yum -y install mutt

# Create Groups and Users
echo -e "\nCriando estrutura de Usuários, Grupos e Diretórios\n"
groupadd $WISE_ADMIN_GROUP
useradd $WISE_ADMIN_USER -g $WISE_ADMIN_GROUP -G wheel,oinstall && usermod --password $(openssl passwd -1 nomanager) admin_wise 
useradd rodrigo_wise -g $WISE_ADMIN_GROUP -G wheel,oinstall && usermod --password $(openssl passwd -1 nomanager) rodrigo_wise
useradd fernando_wise -g $WISE_ADMIN_GROUP -G wheel,oinstall && usermod --password $(openssl passwd -1 nomanager) fernando_wise
useradd caio_wise -g $WISE_ADMIN_GROUP -G oinstall && usermod --password $(openssl passwd -1 nomanager) caio_wise

# Criação e permissão do diretório
mkdir -p $WISE_BASE_DIR
chown -R $WISE_ADMIN_USER.wisedb $WISE_BASE_DIR
chmod g+w $WISE_BASE_DIR

sudo -H -u $WISE_ADMIN_USER bash -c 'ssh-keygen -b 2048 -f ~/.ssh/id_rsa -t rsa -q -N ""'
sudo -H -u $WISE_ADMIN_USER bash -c 'echo -e "\n\nEntre no repositório da Wise: \e[91mhttps://github.com/WiseDB/Customer_Master/settings/keys\e[0m"'
sudo -H -u $WISE_ADMIN_USER bash -c 'echo -e "E adicione a chave abaixo:\n"'
sudo -H -u $WISE_ADMIN_USER bash -c 'cat ~/.ssh/id_rsa.pub'
echo ""
read -n 1 -s -r -p "Após adicionar a chave SSH, tecle algo para continuar..."
echo ""


GIT_COMMAND="git clone git@github.com:WiseDb/Customer_Master.git $WISE_BASE_DIR && $WISE_BASE_DIR/bin/install.sh $WISE_BASE_DIR"  
INSTALL_SCRIPT=/home/$WISE_ADMIN_USER/install.sh
echo -e "$GIT_COMMAND" > $INSTALL_SCRIPT
chown $WISE_ADMIN_USER.$WISE_ADMIN_GROUP $INSTALL_SCRIPT
chmod 755 $INSTALL_SCRIPT
echo -e "\e[91m"
echo -e "\n\nExecute o script \"install.sh\" para finalizar a instalação.\n"
echo -e "" 
echo -e "\e[0m"
su - $WISE_ADMIN_USER

