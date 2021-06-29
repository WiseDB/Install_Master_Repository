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
echo -e -n "Digite o nome da EMPRESA que sera utilizado no repositorio GitHub do cliente. Sem espacos! (ex: \e[34mMaxCompany\e[0m): "
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

# Criacao ou configuracao dos usuarios administradores
cat tech_team.txt |while read DBA_USER
do 
	# Cria o usuario (exceto se o usuario for "oracle")
	if [ "$DBA_USER" != "oracle" ]; then
		echo -e "Usuario $DBA_USER criado com sucesso."
		useradd $DBA_USER -g $WISE_ADMIN_GROUP -G wheel && usermod -aG oinstall $DBA_USER
	else
		# O usuario "oracle" sera adicionado ao grupo da WiseDb
		echo -e "Usuario $DBA_USER adicionado ao grupo $WISE_ADMIN_GROUP"
		usermod -aG $WISE_ADMIN_GROUP $DBA_USER
	fi

	# Configura o .bash_profile para o usuairo
	BASH_PROFILE=/home/$DBA_USER/.bash_profile
	echo -e "\n\n#Parametros para carga dos scripts da Wise" >> $BASH_PROFILE
	echo -e "export WISE_BASE_DIR=$WISE_BASE_DIR" >> $BASH_PROFILE
	echo -e "source $WISE_BASE_DIR/bin/wisedb_library.sh" >> $BASH_PROFILE
	
	# Verifica se o usuario ja possui o par de chaves SSH e cria se for necessario
	if [ -f /home/$DBA_USER/.ssh/id_rsa.pub ]; then
	        echo -e "As chaves do usuario $DBA_USER ja existem."
	else
	        echo -e "Criando novas chaves para o usuario $DBA_USER."
	        sudo -H -u $DBA_USER bash -c 'ssh-keygen -b 2048 -f ~/.ssh/id_rsa -t rsa -q -N ""'
	fi
	
	# Adiciona a chave publica do respectivo DBA_USER
	DBA_USER_PUBLIC_KEY=./.public_keys/$DBA_USER.pub
	DBA_USER_AUTHORIZED_KEYS=/home/$DBA_USER/.ssh/authorized_keys
	if [ -f $DBA_USER_PUBLIC_KEY ]; then
		cat $DBA_USER_PUBLIC_KEY >> $DBA_USER_AUTHORIZED_KEYS
		chmod 600 $DBA_USER_AUTHORIZED_KEYS
		chown ${DBA_USER}.${WISE_ADMIN_GROUP} $DBA_USER_AUTHORIZED_KEYS
	else
		echo -e "Chaves SSH nao encontradas para o usuario $DBA_USER."
	fi
done



# Criação e permissão do diretório
mkdir -p $WISE_BASE_DIR
chown -R $WISE_ADMIN_USER.$WISE_ADMIN_GROUP $WISE_BASE_DIR
chmod g+w $WISE_BASE_DIR

# Configuração das chaves SSH no repositório Customer_Master
sudo -H -u $WISE_ADMIN_USER bash -c 'echo -e "\n\nEntre no repositório da Wise: \e[91mhttps://github.com/WiseDB/Customer_Master/settings/keys\e[0m"'
sudo -H -u $WISE_ADMIN_USER bash -c 'echo -e "E adicione a chave abaixo:\n"'
sudo -H -u $WISE_ADMIN_USER bash -c 'cat ~/.ssh/id_rsa.pub'
echo ""
read -n 1 -s -r -p "Após adicionar a chave SSH, tecle algo para continuar..."
echo ""

INSTALL_SCRIPT=/home/$WISE_ADMIN_USER/download_master.sh
# Clona o repositorio Master
GIT_COMMAND="git clone git@github.com:WiseDB/Customer_Master.git $WISE_BASE_DIR && echo -e \"\nDigite \e[91m'exit'\e[0m para seguir com os próximos passos.\" "  
echo -e "$GIT_COMMAND"    >  $INSTALL_SCRIPT

chown $WISE_ADMIN_USER.$WISE_ADMIN_GROUP $INSTALL_SCRIPT
chmod 755 $INSTALL_SCRIPT
echo -e "\n\nExecute o script \"download_master.sh\" para baixar o repositório.\n"
#echo -e "\e[91m"
echo -e "digite:\e[91m ~/download_master.sh\e[0m\n" 
#echo -e "\e[0m"
su $WISE_ADMIN_USER

####################################################################
# Atualizacao do crontab para o usuario administrador da Wise e oracle
####################################################################
# Header explicativo do crontab 
if [ $(crontab -l -u $WISE_ADMIN_USER |wc -l) -eq 0 ]; then
	cat $WISE_BASE_DIR/bin/crontab_header.txt | crontab -u $WISE_ADMIN_USER -
fi
# Comando para sincronismo do repositorio master
echo -e "WISE_ADMIN_USER: $WISE_ADMIN_USER"
echo -e "WISE_BASE_DIR..: $WISE_BASE_DIR"
sudo -i -u $WISE_ADMIN_USER $WISE_BASE_DIR/bin/add_to_crontab.sh "*/31 *    *    *    *   " "export WISE_BASE_DIR=$WISE_BASE_DIR && $WISE_BASE_DIR/bin/auto_update_master.sh"
sudo -i -u oracle           $WISE_BASE_DIR/bin/add_to_crontab.sh "*/32 *    *    *    *   " "export WISE_BASE_DIR=$WISE_BASE_DIR && $WISE_BASE_DIR/bin/auto_update_customer.sh"

####################################################################
# Criação da área do cliente
####################################################################
mkdir -p $WISE_BASE_DIR/customer && chown oracle.oinstall $WISE_BASE_DIR/customer
clear
echo -e "Você esta logado com o usuario \"oracle\""
echo -e "Siga os passos abaixo para criar a area de configuracao do cliente:\n"
echo -e "  1) Acesse o link do template\e[34m https://github.com/WiseDB/Customer_Template\e[0m.\n"
echo -e "  2) Clique no botao\e[34m [Use this template]\e[0m para criar o repositorio do cliente.\n"
echo -e "  3) Informe o nome do repositorio com o seguinte formato:\e[34m Customer_$WISE_REPOSITORY\e[0m\n"
echo -e "  4) Adicione a chave SSH do usuário \"oracle\" ao novo repositório."
echo -e "     Atenção: Use a opcao de permitir gravacao"
echo -e "     Digite o caminho para pagina das chaves SSH:"
echo -e "     \e[34mhttps://github.com/WiseDB/Customer_$WISE_REPOSITORY/settings/keys\e[0m"
echo -e "     $(cat /home/oracle/.ssh/id_rsa.pub)\n"
echo -e "  5) Crie um clone atraves do comando abaixo:"
echo -e "     git clone git@github.com:WiseDB/\e[34mCustomer_$WISE_REPOSITORY\e[0m.git $WISE_BASE_DIR/customer\n"
echo -e "  6) Entre no diretorio de configuracao: "
echo -e "     cd $WISE_BASE_DIR/customer/config\n"
echo -e "  7) Copie o template \e[34m.customer_info.cfg.template\e[0m para um arquivo de nome \e[34mcustomer.cfg\e[0m"
echo -e "     e faca as configuracoes necessarias.\n"
echo -e "  8) Copie o template \e[34m.SID.db.cfg.template\e[0m para um arquivo no formato \e[34mSID.db.cfg\e[0m"
echo -e "     e faca as configuracoes necessarias."
echo -e "     OBS: Troque a string \"SID\" pelo nome apropriado da instancia.\n"
echo -e "\nApos a execucao dos passos acima, digite \e[91m'exit'\e[0m para finalizar o processo de instalacao.\n"

su oracle

echo -e "Voce esta novamente logado com o ROOT."


