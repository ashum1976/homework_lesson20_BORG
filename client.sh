#!/usr/bin/env bash
echo ""
#echo "Test 'client' complete !!!!"
echo -e "\e[31m Start client backups create !!!!! \e[0m"


#Автоответ, если вариант подключения к репозиторию изменился был - (borg@192.168.10.11:backup) переключили на  (ssh://borg@192.168.10.11:44235/var/backup/client/backup), появится предупреждение “Warning: The repository at location … was previously located at …”
export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
#Автответ на потенциально опасные действия
#export BORG_CHECK_I_KNOW_WHAT_I_AM_DOING=yes
#Инициализируем репозиторий (bakup) — хранилище резервных копий. "export BORG_PASSPHRASE='vagrant'" <---- зададим пароль для шифрования и доступа к нашему репозиторию.
export BORG_PASSPHRASE='vagrant'
yum install -y --nogpgcheck  policycoreutils-python-utils
#Создадим папку и файл для логгирования работы borg
mkdir /var/log/borg/ && touch /var/log/borg/borgbackup.log
#Копируем файл для systemd, для настройки таймера запуска скрипта архивирования. И сам скрипт архивирования по расписанию borg_backup.sh
cp /vagrant/borg_backup.{service,timer} /etc/systemd/system
cp /vagrant/borg_backup.sh /root/ && chmod 700 /root/borg_backup.sh
echo "#Vars with reponame" >>/etc/sysconfig/borg
echo "BORG_REPO=borg@192.168.10.11:backup" >>/etc/sysconfig/borg
systemctl daemon-reload && systemctl enable --now borg_backup.timer > /dev/null 2>&1

#Генерируем пару ключей  для копирования, открытого ключа,  на сервер бэкапов (srvbackup). Сможем с клиента управлять созданием, очисткой, и т.д на сервере.
ssh-keygen -f ~/.ssh/id_rsa -q -N ""
#Создаём файл authorized_keys, содержащий ключ клиента, и программа с путём, только которые можно запустить/использовать, если клиент будет входить по этому ключу.
var_sshkey='command="cd /var/backup/client; borg serve --restrict-to-path /var/backup/client"'
echo "$var_sshkey $(cat /root/.ssh/id_rsa.pub)" > ~/authorized_keys
# sshpass - нужен для передачи пароля, чтоб скопировать первоначально ключ на сервер. Можно использовать ключ '-f', тогда нужно указать путь к файлу с паролем. -f "/path/to/passwordfile"
sshpass -p "qwerty" scp -o StrictHostKeyChecking=no /root/authorized_keys borg@192.168.10.11:~/.ssh/
borg init --encryption=repokey-blake2 borg@192.168.10.11:backup >> /var/log/borg/borgbackup.log 2>&1
#Небольшой резерв свободного места в репозитории
sshpass -p "qwerty" ssh -o StrictHostKeyChecking=no -o PubkeyAuthentication=no  borg@192.168.10.11 'borg config /var/backup/client/backup/  additional_free_space 100M'
#Команда экспорта ключа для зашифрованного репозитория, сохранить в отдельном месте, для восстановления доступа. Пароль тоже нужен :)
#borg key export borg@192.168.10.11:backup ~/borg-srvbackup.key
#SELinux !!!!!
semanage fcontext -a -t init_exec_t /root/borg_backup.sh
/sbin/restorecon -v /root/borg_backup.sh
echo ""
#borg create   --list --stats --show-rc --compression zlib,5 --exclude-caches borg@192.168.10.11:backup::'{hostname}_etc-daily-{now}' /etc
echo -e "\e[31m Create client backups complete !!!!! \e[0m"
