#!/bin/bash
#variable to change
zabpass=password

if [[ $HOSTNAME == "pdv-zabserv" ]] ; then

rpm -ivh https://repo.zabbix.com/zabbix/3.5/rhel/7/x86_64/zabbix-release-3.5-1.el7.noarch.rpm
yum install -y mariadb mariadb-server
ln -s /usr/bin/resolveip /usr/libexec/resolveip
/usr/bin/mysql_install_db --user=mysql
mysql -u root <<EOF
create database zabbix character set utf8 collate utf8_bin;
grant all privileges on zabbix.* to zabbix@localhost identified by $zabpass;
quit;
EOF

yum install -y zabbix-server-mysql zabbix-web-mysql
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p$zabpass zabbix

if [[ $(grep -E ^DBHost=* /etc/zabbix/zabbix_server.conf) == "" ]] ; then
echo DBHost=localhost >> /etc/zabbix/zabbix_server.conf
fi
if [[ $(grep -E ^DBPass=* /etc/zabbix/zabbix_server.conf) == "" ]] ; then
echo DBPassword=$zabpass >> /etc/zabbix/zabbix_server.conf
fi
if [[ $(grep -E ^DBPort=* /etc/zabbix/zabbix_server.conf) == "" ]] ; then
echo DBPort=3306 >> /etc/zabbix/zabbix_server.conf
fi

sed -i 's/# php_value date.timezone Europe\/Riga/php_value date.timezone Europe\/Minsk/' /etc/httpd/conf.d/zabbix.conf

cat << EOF > /etc/httpd/conf.d/new.conf
<VirtualHost *>
    DocumentRoot /usr/share/zabbix
</VirtualHost>
EOF
sudo cp -f /vagrant/zabbix.conf.php /etc/zabbix/web/
sed -i "s/password/$zabpass/" /etc/zabbix/web/zabbix.conf.php


systemctl start mariadb
systemctl enable mariadb
systemctl start httpd
systemctl enable httpd
systemctl enable zabbix-server
systemctl start zabbix-server
yum install zabbix-agent -y
systemctl start zabbix-agent

fi 

if [[ $HOSTNAME == "pdv-zabclnt" ]] ; then

rpm -ivh https://repo.zabbix.com/zabbix/3.5/rhel/7/x86_64/zabbix-release-3.5-1.el7.noarch.rpm
yum install zabbix-agent -y


if [[ ! $(grep -E ^Server= /etc/zabbix/zabbix_agentd.conf) == "" ]] ; then
cat << EOF >> /etc/zabbix/zabbix_agentd.conf
Server=pdv-zabserv
ListenIP=0.0.0.0
ListenPort=10050
StartAgents=3
Hostname=pdv-zabclnt
EOF
fi
systemctl start zabbix-agent
systemctl enable zabbix-agent
fi

