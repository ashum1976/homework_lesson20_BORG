#!/usr/bin/env bash

# echo ""
# echo "Test complete !!!!"
echo ""
echo -e "\e[31m Start server backups run !!!!! \e[0m"

#Создание раздела, на дополнительном диске, для подключения как /var/backup отдельной точкой монтирования. Дополнительный диск создадим в вагранте при развёртывании виртуальной машины, которая будет выступать как сервер.
var_dev=$(lsblk -l -o NAME -p | grep -v "^/dev/sda\|^NAME")
if [[ $(cat $var_dev | wc -l) -gt 1 ]]
    then
        echo -e "\e[31m Имеется больше 1 дополнительного диска !!!! \e[0m"
        exit 1
    else
        parted -s $var_dev mklabel msdos
        parted -s /dev/sdb mkpart primary ext4 1 2G
        mkfs.ext4 /dev/sdb1 > /dev/null 2>&1
        echo -e "\e[31m Create add partition complete \e[0m"
fi
mkdir /var/backup
var_uuid=$(blkid  | grep ^/dev/sdb | cut -f 2 -d " ")
echo "$var_uuid  /var/backup  ext4  default 0 0" >> /etc/fstab
mount $var_uuid /var/backup
echo -e "\e[31m Отдельный раздел для каталога var/backup создан и подключен \e[0m"
#
#Добавим на сервере бэкапов пользователя borg с паролем "qwerty"
useradd -m borg
echo "borg:qwerty" | chpasswd
mkdir /home/borg/.ssh && chown borg:borg /home/borg/.ssh
echo -e "\e[31m Пользователь borg создан \e[0m"
#
#Создадим папку и файл для логгирования работы borg
mkdir /var/log/borg/ && touch /var/log/borg/borgbackup.log
chown -R borg:borg /var/log/borg/
chmod 750 /var/log/borg/ && chmod 640 /var/log/borg/borgbackup.log
#
#Разрешим парольный логин на сервер
sed -i.bak 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd
#
#Создадим в папке /var/backup отдельную папку по имени хоста (client)  (в примере только один клиент, но в реальности их конечно больше :) Лучше разделить сразу )
mkdir -p /var/backup/client
chown -R borg:borg /var/backup
echo ""
echo -e "\e[31m Create server backups complete !!!!! \e[0m"
