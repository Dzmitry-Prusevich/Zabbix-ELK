#!/bin/bash

if [[ $HOSTNAME == "pdv-serv" ]] ; then

rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

cat <<EOF > /etc/yum.repos.d/elasticsearch.repo
[elasticsearch-7.x]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

yum install elasticsearch -y

cp -f /vagrant/elasticsearch.yml  /etc/elasticsearch/elasticsearch.yml
chown elasticsearch /etc/elasticsearch/elasticsearch.yml

cat <<EOF > /etc/yum.repos.d/kibana.repo
[kibana-7.x]
name=Kibana repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

sudo yum install kibana -y

cp -f /vagrant/kibana.yml  /etc/kibana/kibana.yml

systemctl start kibana.service
systemctl enable kibana.service
systemctl start elasticsearch.service
systemctl enable elasticsearch.service

fi 

if [[ $HOSTNAME == "pdv-clnt" ]] ; then

 yum install tomcat -y
 yum install tomcat-webapps tomcat-admin-webapps -y
 systemctl start tomcat
 systemctl enable tomcat
cp -f /vagrant/TestApp.war /var/lib/tomcat/webapps/

tomconf="/etc/tomcat/server.xml"

rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch


cat <<EOF > /etc/yum.repos.d/logstash.repo
[logstash-7.x]
name=Elastic repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

yum install logstash -y

cp -f /vagrant/tomcat.conf /etc/logstash/conf.d/tomcat.conf
chmod 744 /var/log/tomcat

systemctl start logstash.service
systemctl enable logstash.service

fi
