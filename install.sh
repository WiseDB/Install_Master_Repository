#!/bin/bash

# Valida o usuário que está executando o script
if [ "$(whoami)" != "root" ]
then
	echo -e "ERRO: Este script deve ser executado com o usuário ROOT!"
	exit 1
fi

clear;
echo -e "----------------------------------------------------"
echo -e "Instalação do repositório da Wise Database Solutions"
echo -e "----------------------------------------------------\n"
echo -e -n "Nome do diretório BASE da Wise (default: /opt/WiseDb): "
read WDIR
[ -z "$WDIR" ] && WDIR=/opt/WiseDb
echo -e -n "Nome do usuário ADMIN da Wise (default: admin_wise): "
read WUSER
[ -z "$WUSER" ] && WUSER=admin_wise
echo -e -n "Nome do GRUPO principal da Wise (default: wisedb): "
read WGROUP
[ -z "$WGROUP" ] && WGROUP=wisedb
echo -e -n "Nome do REPOSITORIO GitHub do cliente (ex: Customer_\e[34mNomeEmpresa\e[0m): "
read WREPO
[ -z "$WREPO" ] && WREPO=NomeEmpresa


export WISE_BASE_DIR=$WDIR
export WISE_ADMIN_USER=$WUSER
export WISE_ADMIN_GROUP=$WGROUP
export WISE_REPOSITORY=$WREPO

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

# Configura o .bash_profile para o novo usuário.
BASH_PROFILE=/home/$WISE_ADMIN_USER/.bash_profile
echo -e "\n\n#Parametros para carga dos scripts da Wise" >> $BASH_PROFILE
echo -e "export WISE_BASE_DIR=$WISE_BASE_DIR" >> $BASH_PROFILE
echo -e "source $WISE_BASE_DIR/bin/wisedb_library.sh" >> $BASH_PROFILE

# Configura o .bash_profile para o usuário ORACLE.
BASH_PROFILE=/home/oracle/.bash_profile
echo -e "\n\n#Parametros para carga dos scripts da Wise" >> $BASH_PROFILE
echo -e "export WISE_BASE_DIR=$WISE_BASE_DIR" >> $BASH_PROFILE
echo -e "source $WISE_BASE_DIR/bin/wisedb_library.sh" >> $BASH_PROFILE

# Verifica se o usuário "oracle" já possui o par de chaves SSH
if [ -f /home/oracle/.ssh/id_rsa.pub ]; then
        echo -e "As chaves do usuário ORACLE já existem."
else
        echo -e "Criando novas chaves para o usuário ORACLE"
        sudo -H -u oracle bash -c 'ssh-keygen -b 2048 -f ~/.ssh/id_rsa -t rsa -q -N ""'
fi

# Criação e permissão do diretório
mkdir -p $WISE_BASE_DIR
chown -R $WISE_ADMIN_USER.$WISE_ADMIN_GROUP $WISE_BASE_DIR
chmod g+w $WISE_BASE_DIR

# Configuração das chaves SSH no repositório Customer_Master
sudo -H -u $WISE_ADMIN_USER bash -c 'ssh-keygen -b 2048 -f ~/.ssh/id_rsa -t rsa -q -N ""'
sudo -H -u $WISE_ADMIN_USER bash -c 'echo -e "\n\nEntre no repositório da Wise: \e[91mhttps://github.com/WiseDB/Customer_Master/settings/keys\e[0m"'
sudo -H -u $WISE_ADMIN_USER bash -c 'echo -e "E adicione a chave abaixo:\n"'
sudo -H -u $WISE_ADMIN_USER bash -c 'cat ~/.ssh/id_rsa.pub'
echo ""
read -n 1 -s -r -p "Após adicionar a chave SSH, tecle algo para continuar..."
echo ""

GIT_COMMAND="git clone git@github.com:WiseDB/Customer_Master.git $WISE_BASE_DIR && echo -e \"\nDigite \e[91m'exit'\e[0m para seguir com os próximos passos.\" "  
INSTALL_SCRIPT=/home/$WISE_ADMIN_USER/download_master.sh
echo -e "$GIT_COMMAND" > $INSTALL_SCRIPT
chown $WISE_ADMIN_USER.$WISE_ADMIN_GROUP $INSTALL_SCRIPT
chmod 755 $INSTALL_SCRIPT
echo -e "\n\nExecute o script \"download_master.sh\" para baixar o repositório.\n"
#echo -e "\e[91m"
echo -e "digite:\e[91m ~/download_master.sh\e[0m\n" 
#echo -e "\e[0m"
su $WISE_ADMIN_USER

# Criação da área do cliente
mkdir -p $WISE_BASE_DIR/customer && chown oracle.oinstall $WISE_BASE_DIR/customer
clear
echo -e "Você está logado com o usuário \"oracle\""
echo -e "Siga os passos abaixo para criar a área de configuração do cliente:\n"
echo -e "  1) Acesse o link do template\e[34m https://github.com/WiseDB/Customer_Template\e[0m.\n"
echo -e "  2) Clique no botão\e[34m [Use this template]\e[0m para criar o repositório do cliente.\n"
echo -e "  3) Escolha um nome para o repositório (privado), com o formato:\e[34m Customer$WISE_REPOSITORY\e[0m\n"
echo -e "  4) Adicione a chave SSH do usuário \"oracle\" ao novo repositório."
echo -e "     Atenção: Use a opção de permitir gravação"
echo -e "     Digite o caminho para página das chaves SSH:"
echo -e "     \e[34mhttps://github.com/WiseDB/Customer_$WISE_REPOSITORY/settings/keys\e[0m"
echo -e "     $(cat /home/oracle/.ssh/id_rsa.pub)\n"
echo -e "  5) Crie um clone através do comando abaixo:"
echo -e "     git clone git@github.com:WiseDB/\e[34mCustomer_$WISE_REPOSITORY\e[0m.git $WISE_BASE_DIR/customer\n"
echo -e "  6) Entre no diretório de configuração: "
echo -e "     cd $WISE_BASE_DIR/customer/config\n"
echo -e "  7) Copie o template \e[34m.customer_info.cfg.template\e[0m para um arquivo de nome \e[34mcustomer.cfg\e[0m"
echo -e "     e faça as configurações necessárias.\n"
echo -e "  8) Copie o template \e[34m.SID.db.cfg.template\e[0m para um arquivo no formato \e[34mSID.db.cfg\e[0m"
echo -e "     e faça as configurações necessárias."
echo -e "     OBS: Troque a string \"SID\" pelo nome apropriado da instância.\n"
echo -e "\nApós a execução dos passos acima, digite \e[91m'exit'\e[0m para finalizar o processo de instalação.\n"

su oracle

echo -e "Você está novamente logado com o ROOT."


