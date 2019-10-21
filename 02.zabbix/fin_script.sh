#!/bin/bash
#variables
zabpass=zabbix


if [[ $HOSTNAME == "pdv-zabserv" ]] ; then

rpm -ivh https://repo.zabbix.com/zabbix/3.5/rhel/7/x86_64/zabbix-release-3.5-1.el7.noarch.rpm
yum-config-manager --enable rhel-7-server-optional-rpms
yum install zabbix-server-mysql zabbix-web-mysql -y

yum install -y mariadb mariadb-server
ln -s /usr/bin/resolveip /usr/libexec/resolveip
/usr/bin/mysql_install_db --user=mysql

systemctl start mariadb.service



mysql <<EOF
create database zabbix character set utf8 collate utf8_bin;
grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';
EOF


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

sed -i "s/Hostname=Zabbix server/Hostname=pdv-zabclnt/" /etc/zabbix/zabbix_agentd.conf
sed -i "s/Server=127.0.0.1/Server=pdv-zabserv/" /etc/zabbix/zabbix_agentd.conf
sed -i "s/ServerActive=127.0.0.1/ServerActive=pdv-zabserv/" /etc/zabbix/zabbix_agentd.conf

if [[ $(grep -E ^ListenIP= /etc/zabbix/zabbix_agentd.conf) == "" ]] ; then
cat << EOF >> /etc/zabbix/zabbix_agentd.conf
ListenIP=0.0.0.0
ListenPort=10050
StartAgents=3
EOF
fi
systemctl start zabbix-agent
systemctl enable zabbix-agent
fi
