#!/bin/bash
#variables
zabpass=zabbix
zabbase=zabbix
#for API
userzab=Admin
passwordzab=zabbix
zabhostgr=CloudHosts


if [[ $HOSTNAME == "pdv-zabserv" ]] ; then

rpm -ivh https://repo.zabbix.com/zabbix/3.5/rhel/7/x86_64/zabbix-release-3.5-1.el7.noarch.rpm
 
yum-config-manager --enable rhel-7-server-optional-rpms
yum install zabbix-server-mysql zabbix-web-mysql -y
yum install zabbix-server-mysql zabbix-web-mysql -y
yum install zabbix-server-mysql zabbix-web-mysql -y
yum install zabbix-server-mysql zabbix-web-mysql -y
yum install zabbix-server-mysql zabbix-web-mysql -y

yum install -y mariadb mariadb-server
yum install -y mariadb mariadb-server
yum install -y mariadb mariadb-server
yum install -y mariadb mariadb-server
yum install -y mariadb mariadb-server
yum install -y mariadb mariadb-server

ln -s /usr/bin/resolveip /usr/libexec/resolveip
/usr/bin/mysql_install_db --user=mysql
sleep 10
systemctl start mariadb.service
sleep 10
mysql  -e "create database $zabbase character set utf8 collate utf8_bin"
mysql  -e "grant all privileges on zabbix.* to zabbix@localhost identified by '$zabpass'"


zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p$zabpass $zabbase

zabserconf="/etc/zabbix/zabbix_server.conf"
if [[ $(grep -E ^DBHost=* $zabserconf) == "" ]] ; then
echo DBHost=localhost >> $zabserconf
fi
if [[ $(grep -E ^DBPass=* $zabserconf) == "" ]] ; then
echo DBPassword=$zabpass >> $zabserconf
fi
if [[ $(grep -E ^DBPort=* $zabserconf) == "" ]] ; then
echo DBPort=3306 >> $zabserconf
fi

sed -i 's/# php_value date.timezone Europe\/Riga/php_value date.timezone Europe\/Minsk/' /etc/httpd/conf.d/zabbix.conf

cat << EOF > /etc/httpd/conf.d/new.conf
<VirtualHost *>
    DocumentRoot /usr/share/zabbix
</VirtualHost>
EOF
sudo cp -f /vagrant/zabbix.conf.php /etc/zabbix/web/
sed -i "s/password/$zabpass/" /etc/zabbix/web/zabbix.conf.php

#task 1.2
yum install -y zabbix-get


#task 2.1
if [[ $(grep -E ^JavaGateway=* $zabserconf) == "" ]] ; then
echo JavaGateway=$1 >> $zabserconf
echo JavaGatewayPort=10052 >> $zabserconf
echo StartJavaPollers=5 >> $zabserconf
fi



yum install zabbix-java-gateway -y

systemctl start mariadb
systemctl enable mariadb
systemctl start httpd
systemctl enable httpd
systemctl enable zabbix-server
systemctl start zabbix-server
yum install zabbix-agent -y
systemctl start zabbix-agent
systemctl enable zabbix-java-gateway
 systemctl start zabbix-java-gateway
fi 

if [[ $HOSTNAME == "pdv-zabclnt" ]] ; then

rpm -ivh https://repo.zabbix.com/zabbix/3.5/rhel/7/x86_64/zabbix-release-3.5-1.el7.noarch.rpm
yum install zabbix-agent -y

zabagconf="/etc/zabbix/zabbix_agentd.conf"
sed -i "s/Hostname=Zabbix server/Hostname=$4/" $zabagconf
sed -i "s/Server=127.0.0.1/Server=$2/" $zabagconf
sed -i "s/ServerActive=127.0.0.1/ServerActive=$2/" $zabagconf

if [[ $(grep -E ^ListenIP= /etc/zabbix/zabbix_agentd.conf) == "" ]] ; then
cat << EOF >> /etc/zabbix/zabbix_agentd.conf
ListenIP=0.0.0.0
ListenPort=10050
StartAgents=3
EOF
fi

#task 1.2
yum install -y zabbix-sender

#task 2.1
 yum install tomcat -y
 yum install tomcat-webapps tomcat-admin-webapps -y
 systemctl start tomcat
 systemctl enable tomcat
cp -f /vagrant/TestApp.war /var/lib/tomcat/webapps/

wget https://archive.apache.org/dist/tomcat/tomcat7/v7.0.76/bin/extras/catalina-jmx-remote.jar
mv catalina-jmx-remote.jar /usr/share/tomcat/lib/

tomconf="/etc/tomcat/server.xml"

if [[ $(grep "JmxRemoteLifecycleListener" $tomconf) == "" ]] ; then
sed -i "/ThreadLocalLeakPreventionListener/a <Listener className=\"org.apache.catalina.mbeans.JmxRemoteLifecycleListener\" rmiRegistryPortPlatform=\"8097\" rmiServerPortPlatform=\"8098\" \/\>\" " $tomconf
fi

sed -i "s/\"NAME=\"/\' JAVA_OPTS=-Dcom.sun.management.jmxremote=true \
-Dcom.sun.management.jmxremote.port=12345 \
-Dcom.sun.management.jmxremote.rmi.port=12346 \
-Dcom.sun.management.jmxremote.ssl=false \
-Dcom.sun.management.jmxremote.authenticate=false \
-Djava.rmi.server.hostname=$3\'/"  /usr/lib/systemd/system/tomcat.service

systemctl start zabbix-agent
systemctl enable zabbix-agent

#task 2.4
zabapiadr="http://$1/zabbix/api_jsonrpc.php"

#autentificate to get token for connection
# token=$(curl -i -X POST -H 'Content-type:application/json' -d '{"jsonrpc":"2.0","method":"user.login","params": { "user":"Admin","password":"zabbix"},"auth":null,"id":0}' http://192.168.56.201/zabbix/api_jsonrpc.php | grep result | awk -F ":" '{print $3}' | awk -F '"' '{print $2}')

token=$(curl -i -X POST -H 'Content-type:application/json' -d '{"jsonrpc":"2.0","method":"user.login","params": { "user": "'${userzab}'" , "password" : "'$passwordzab'" } ,"auth":null,"id":0}' $zabapiadr | grep result | awk -F ":" '{print $3}' | awk -F '"' '{print $2}')

#create zabbix host group
 curl -i -X POST -H 'Content-Type:application/json' -d '{"jsonrpc":"2.0","method":"hostgroup.create","params":{"name": "'${zabhostgr}'"},"auth":"'${token}'","id":0}' $zabapiadr
 
#get host group id

curl -i -X POST -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","method":"hostgroup.get","params":{"output": "extend","filter":{"name":["'${zabhostgr}'"]}},"auth":"'${token}'","id":0}' $zabapiadr 
zabgrid=$(curl -i -X POST -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","method":"hostgroup.get","params":{"output": "extend","filter":{"name":["'${zabhostgr}'"]}},"auth":"'${token}'","id":0}' $zabapiadr | grep result | awk -F ":" '{print $4}' | awk -F '"' '{print $2}')

#create host

curl -i -X POST -H 'Content-Type: application/json' -d '{"jsonrpc": "2.0", "method": "host.create", "params": { "host": "'$4'", "templates": [{ "templateid": "10001" }], "interfaces": [{ "type": 1, "main": 1, "useip": 1, "ip": "'$3'", "dns": "", "port": "10050" }], "groups": [ {"groupid": "'${zabgrid}'"} ] }, "auth":"'${token}'","id":0}' $zabapiadr



fi
