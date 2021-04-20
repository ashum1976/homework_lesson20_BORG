#!/usr/bin/env bash
# the repo and it's passphrase
# Переменная окружения, с именем репозитория, можно сократить команды создания, просмотра, информации.
export BORG_REPO=borg@192.168.10.11:backup
#Пароль репозитория Borg можно указать в переменной окружения (BORG_PASSPHRASE), чтобы не вводить его при каждом запуске
export BORG_PASSPHRASE='vagrant'
#если используется нестандартный SSH-ключ, по умолчанию id_rsa,то его надо явно указать:
# export BORG_RSH="ssh -i /home/userXY/.ssh/id_ed

# #Перенаправить вывод выполнения скрипта в логгер, и вывод выполнения скрипта в логгер в случае ошибки
# exec > >(logger  -p user.notice -t `basename "$0"`)
# exec 2> >(logger  -p user.error -t `basename "$0"`)


exec > >(logger  -p local0.notice -t `basename "$0"`)
exec 2> >(logger  -p local0.error -t `basename "$0"`)


# backup the directories
borg create --verbose --list --filter AME --stats --show-rc --compression zlib,5 \
 --exclude-caches borg@192.168.10.11:backup::'{hostname}_etc-{now}' /etc

backup_exit=$?

# prune the repo
borg prune -vv \
    --list \
    --stats\
    --show-rc \
    --prefix '{hostname}_etc-' \
    --keep-daily 93 \
    --keep-monthly 12 \
    --keep-minutely 5 \
    --keep-last 2
