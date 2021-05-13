#!/bin/bash
#Backup + Chamado no GLPi via API
#Autor = Servicedesk Brasil | Danilo Santos, Danilo Motta
#Versao = 2.1 - Data atualizacao = 05-MAI-21
#API GLPI Acessos

GLPI_URL_API='https://travessia.glpibrasil.com.br'
GLPI_APP_TOKEN='GZU5W7PEadpt9arPgFXt8LGsYiC7GnSsuOkxNHY5';
GLPI_USER_TOKEN='3AU4DS1s1Dcjy09Y5EkSktc2mm3tqiwSimuJHfPf';
GLPI_ID_ENTIDADE=0;						#ID da entidade de abertura do chamado
GLPI_ID_CATEGORIA=148;						#ID da categoria
GLPI_ID_TIPO=2;							#Tipo de chamado [1=Incidente, 2=Requisição]
GLPI_ID_ORIGEM_REQUISICAO=8;					#Origem da requisição, é de onde veio o chamado(Exemplo '1' é o Helpdesk) 

#Diretorio do Backup SQL, Aplicacao, Files/Anexos e LOG
 
BACKUP_DIR_SQL='/backup/glpi/sql';				#Diretorio de destino Backup SQL
BACKUP_DIR_APP='/backup/glpi/app';				#Diretorio de destino Backup Aplicacao
BACKUP_DIR_FILE='/backup/glpi/app';				#Diretorio de destino Backup Files/Anexos
BACKUP_DIR_LOG='/backup/glpi/app';				#Diretorio de destino Backup Logs

LOGFILE='/var/log/glpi/backup.log';				#Saida do LOG

#Diretorios do GLPi - Aplicacao, Files/Anexos e LOG
 
GLPI_APP_DIR='/usr/share/glpi';					#Diretorio da Aplicação do GLPI
GLPI_FILE_DIR='/var/lib/glpi';					#GLPI-Files
GLPI_LOG_DIR='/var/log/glpi';					#GLPI-Logs

#Buscar dados de acesso do Banco de Dados no arquivo de config_db do GLPI RPM Remi Collet

DBCONFIG='/etc/glpi/config_db.php';
DBUSER=`grep "dbuser" $DBCONFIG | cut -d "'" -f 2`;
DBPASS=`grep "dbpassword" $DBCONFIG | cut -d "'" -f 2`;
DBNAME=`grep "dbdefault" $DBCONFIG | cut -d "'" -f 2`;

#Variaveis de acesso para acesso direto ao SQL

#DBNAME='glpi';
#DBUSER='glpi';
#DBPASS='GLP1@2o21';

#Informações para a Descricao do Chamado

TAMANHO_DIR_GLPI_APP=true
TAMANHO_DIR_GLPI_FILE=true
TAMANHO_DIR_GLPI_LOG=true
TAMANHO_DIR_BACKUP_ANTES=true
TAMANHO_DIR_BACKUP_APOS=true
STATUS_DISCOS=true

#Preferencias

DATE_FORMAT='%Y-%m-%d';						#Formato da data para o BACKUP([Ano,Mes,Dia] - facilita na consulta)
LOG_TIME_FORMAT='%d-%m-%Y %H:%M';				#Formato da data para o arquivo de log
DATE_BASE=$(date +"$DATE_FORMAT");				#Data para nome do arquivo

#Backup do SQL

if [ "$TAMANHO_DIR_BACKUP_ANTES" = true ] ; then
    DIR_BACKUP_ANTES=$(du -sh $BACKUP_DIR_SQL)
fi

echo -e $(echo $(date +"$LOG_TIME_FORMAT"))" \t## Backup iniciado ##" >> $LOGFILE;
echo -e $(echo $(date +"$LOG_TIME_FORMAT"))"  \tCriando SQL $BACKUP_DIR_SQL/glpi-sqldump.$DATE_BASE.sql ..." >> $LOGFILE;

mysqldump --no-tablespaces -u$DBUSER -p$DBPASS $DBNAME > $BACKUP_DIR_SQL/glpi-sqldump.$DATE_BASE.sql;

echo -e $(echo $(date +"$LOG_TIME_FORMAT"))"  \tbackup: "$(du -sh $GLPISIZE)".. em $BACKUP_DIR_SQL/glpi-sqldump.$DATE_BASE.tar.bz2 ..." >> $LOGFILE;

tar -cjPf $BACKUP_DIR_SQL/glpi-sqldump.$DATE_BASE.tar.bz2 $BACKUP_DIR_SQL/glpi-sqldump.$DATE_BASE.sql >> $LOGFILE;
rm -f $BACKUP_DIR_SQL/glpi-sqldump*.sql

#Removendo Backup_Aplicacao anterior
rm -f $BACKUP_DIR_APP/glpi_app.tar.bz2

#Novo Backup_Aplicacao
tar -cjPf $BACKUP_DIR_APP/glpi_app.tar.bz2 $GLPI_APP_DIR >> $LOGFILE;

#Removendo Backup_Files/Anexo anterior
rm -f $BACKUP_DIR_FILE/glpi_lib.tar.bz2

#Novo Backup_Files/Anexo
tar -cjPf $BACKUP_DIR_FILE/glpi_lib.tar.bz2 $GLPI_FILE_DIR >> $LOGFILE;

#Removendo Backup_Files/Anexo anterior
rm -f $BACKUP_DIR_LOG/glpi_log.tar.bz2

#Novo Backup_Files/Anexo
tar -cjPf $BACKUP_DIR_LOG/glpi_log.tar.bz2 $GLPI_LOG_DIR >> $LOGFILE;

#Backup Realizado
echo -e $(echo $(date +"$LOG_TIME_FORMAT"))"  \tConcluido..." >> $LOGFILE;
echo "Backup realizado! - Total "$(du -sh $GLPISIZE);

echo -e $(echo $(date +"$LOG_TIME_FORMAT"))" \t## Backup realizado ##" >> $LOGFILE;

#API criar sessao

echo -e $(echo $(date +"$LOG_TIME_FORMAT"))"  \tAbrir sessão" >> $LOGFILE;
SESSION_TOKEN=$(curl -s -X POST -H 'Content-Type: application/json' -H "app-token: $GLPI_APP_TOKEN" "$GLPI_URL_API/apirest.php/initSession" --data "{\"user_token\":\"$GLPI_USER_TOKEN\"}" | grep -o -P '(?<=:").*(?=")')

#Titulo e Descrição do chamado

GLPI_TITLE='Backup GLPi - '$(echo $(date +"$LOG_TIME_FORMAT"));

GLPI_DESCRICAO='<p><strong>#Backup GLPI</strong></p>';

if [ "$TAMANHO_DIR_BACKUP_ANTES" = true ] ; then
    GLPI_DESCRICAO="${GLPI_DESCRICAO}<p>${DIR_BACKUP_ANTES} - Tamanho antes do BACKUP</p>";
fi
if [ "$TAMANHO_DIR_BACKUP_APOS" = true ] ; then
    GLPI_DESCRICAO="${GLPI_DESCRICAO}<p>"$(du -sh $BACKUP_DIR_SQL)" - Tamanho depois do BACKUP</p>";
fi
if [ "$TAMANHO_DIR_GLPI_APP" = true ] ; then
    GLPI_DESCRICAO="${GLPI_DESCRICAO}<p>"$(du -sh $GLPI_APP_DIR)" - Tamanho do APP</p>";
fi
if [ "$TAMANHO_DIR_GLPI_FILE" = true ] ; then
    GLPI_DESCRICAO="${GLPI_DESCRICAO}<p>"$(du -sh $GLPI_FILE_DIR)" - Tamanho da FILE</p>";
fi
if [ "$TAMANHO_DIR_GLPI_LOG" = true ] ; then
    GLPI_DESCRICAO="${GLPI_DESCRICAO}<p>"$(du -sh $GLPI_LOG_DIR)" - Tamanho da LOG</p>";
fi
if [ "$STATUS_DISCOS" = true ] ; then
    GLPI_DESCRICAO="${GLPI_DESCRICAO}<br/><strong><p>Status do disco:</p></strong><br/><p>"$(df -h '/')"</p>";
fi

echo -e $(echo $(date +"$LOG_TIME_FORMAT"))"  \tCriar chamado" >> $LOGFILE;

echo -e $(curl -s -X POST -H 'Content-Type: application/json' -H "App-Token: $GLPI_APP_TOKEN" -H "Session-Token: $SESSION_TOKEN" --data "{ \"input\": {\"entities_id\": \"$GLPI_ID_ENTIDADE\",\"type\":$GLPI_ID_TIPO,\"itilcategories_id\":$GLPI_ID_CATEGORIA,\"requesttypes_id\":$GLPI_ID_ORIGEM_REQUISICAO,\"name\": \"$GLPI_TITLE\",\"content\": \"$(echo $GLPI_DESCRICAO)\"}}" "$GLPI_URL_API/apirest.php/Ticket") >> $LOGFILE;

#API Encerrar sessão
echo -e $(echo $(date +"$LOG_TIME_FORMAT"))"  \tEncerrar sessão" >> $LOGFILE;
echo -e $(curl -s -X POST -H 'Content-Type: application/json' -H "App-Token: $GLPI_APP_TOKEN" --data "{\"session_token\": \"$SESSION_TOKEN\"}" "$GLPI_URL_API/apirest.php/killSession") >> $LOGFILE;

#Backup e Chamado Concluido
echo -e $(echo $(date +"$LOG_TIME_FORMAT"))"  \tBackup e Chamado Concluido..." >> $LOGFILE;

echo "Chamado criado!";

exit 0;
