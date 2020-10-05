#!/bin/bash
#

echo "=== Setup Graylog ==="

GRAYLOG_TIMEZONE="Europe/Budapest"
GRAYLOG_SHA2="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" # Gr@yl0g_Rul3z
DEBIAN_FRONTEND=noninteractive

echo "[*] Upgrade base"
apt-get install -y software-properties-common
add-apt-repository universe
apt-get update && apt-get upgrade
apt-get install -y apt-transport-https openjdk-8-jre-headless uuid-runtime pwgen gnupg libterm-readline-gnu-perl curl jq

echo "[*] Installing MongoDB"
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4
echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.0.list
apt-get update
apt-get install -y mongodb-org

echo "[*] Enabling mongodb"
systemctl daemon-reload
systemctl enable mongod.service
systemctl restart mongod.service
systemctl --type=service --state=active | grep mongod

echo "[*] Installing Elasticsearch"
wget -q https://artifacts.elastic.co/GPG-KEY-elasticsearch -O myKey
apt-key add myKey
rm myKey
echo "deb https://artifacts.elastic.co/packages/oss-6.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-6.x.list
apt-get update && apt-get install -y elasticsearch-oss

echo "[*] Configuring Elasticsearch"
sed -i /etc/elasticsearch/elasticsearch.yml \
  -e '/cluster\.name:/c\cluster.name: graylog' \
  -e '$ a action.auto_create_index: false'

echo "[*] Enabling Elasticsearch"
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl restart elasticsearch.service
systemctl --type=service --state=active | grep elasticsearch

echo "[*] Installing Graylog"
wget https://packages.graylog2.org/repo/packages/graylog-3.3-repository_latest.deb
dpkg -i graylog-3.3-repository_latest.deb
rm graylog-3.3-repository_latest.deb
apt-get update && apt-get install -y graylog-server graylog-enterprise-plugins graylog-integrations-plugins graylog-enterprise-integrations-plugins

echo "[*] Installing Slack plugin"
wget https://github.com/graylog-labs/graylog-plugin-slack/releases/download/3.1.0/graylog-plugin-slack-3.1.0.deb
dpkg -i graylog-plugin-slack-3.1.0.deb
rm graylog-plugin-slack-3.1.0.deb

echo "[*] Configuring Graylog"
SECRET=`pwgen -N 1 -s 96`
sed -i /etc/graylog/server/server.conf \
  -e "/^password_secret/c\\password_secret = ${SECRET}" \
  -e "/^root_password_sha2/c\\root_password_sha2 = ${GRAYLOG_SHA2}" \
  -e "/root_timezone/c\\root_timezone = ${GRAYLOG_TIMEZONE}"

echo "[*] Enabling Graylog"
systemctl daemon-reload
systemctl enable graylog-server.service
systemctl start graylog-server.service
systemctl --type=service --state=active | grep graylog

echo "[*] Copying GeoLite2-City.mmdb to /etc/graylog/server/"
cp ~ubuntu/GeoLite2-City.mmdb /etc/graylog/server/

echo "=== Setup Graylog Done ==="
