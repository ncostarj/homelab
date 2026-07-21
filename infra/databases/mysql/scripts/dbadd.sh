#!/usr/bin/env bash

set -Eeuo pipefail

#######################################
# Configuração
#######################################

MYSQL_CONTAINER="mysql"

ROOT_USER="root"
ROOT_PASSWORD="root"

#######################################

APP_NAME="$1"

if [ -z "${APP_NAME:-}" ]; then
    echo "Uso:"
    echo "./dbadd.sh crm"
    exit 1
fi

DATABASE="$APP_NAME"
USER="$APP_NAME"
#PASSWORD="$(openssl rand -base64 18)"
PASSWORD="${APP_NAME}123"
echo $PASSWORD

# BACKUP="../backups/${DATABASE}.sql.gz"
BACKUP="../backups/${DATABASE}.sql"

echo
echo "Aplicação : $APP_NAME"
echo "Banco     : $DATABASE"
echo "Usuário   : $USER"
echo "Senha     : $PASSWORD"
echo

echo "Criando banco..."

mysql_exec() {
    local sql="$1"

    docker exec \
        -e MYSQL_PWD="$ROOT_PASSWORD" \
        "$MYSQL_CONTAINER" \
        mysql \
        -u"$ROOT_USER" \
        -e "$sql"
}

mysql_exec "
CREATE DATABASE IF NOT EXISTS \`$DATABASE\`
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '$USER'@'%'
IDENTIFIED BY '$PASSWORD';

GRANT ALL PRIVILEGES
ON \`$DATABASE\`.*
TO '$USER'@'%';

FLUSH PRIVILEGES;
"

echo "Banco criado."

# if [ -f "$BACKUP" ]; then

#     echo
#     echo "Importando backup..."

#     gunzip -c "$BACKUP" | docker exec -i "$MYSQL_CONTAINER" \
#         mysql \
#         -u"$ROOT_USER" \
#         -p"$ROOT_PASSWORD" \
#         "$DATABASE"

#     echo "Backup restaurado."

# else

#     echo
#     echo "Nenhum backup encontrado."

# fi

if [ -f "$BACKUP" ]; then

    echo
    echo "Importando backup..."

    docker exec -i \
        -e MYSQL_PWD="$ROOT_PASSWORD" \
        "$MYSQL_CONTAINER" mysql -u"$ROOT_USER" "$DATABASE" < "$BACKUP"
        # -p"$ROOT_PASSWORD" \

    echo "Backup restaurado."

else

    echo
    echo "Nenhum backup encontrado em:"
    echo "$BACKUP"

fi

echo
echo "========================"
echo "Concluído!"
echo
echo "Database : $DATABASE"
echo "User     : $USER"
echo "Password : $PASSWORD"
echo