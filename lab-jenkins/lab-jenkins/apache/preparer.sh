#!/bin/sh
# Génère apache/httpd.conf à partir de la configuration par défaut de l'image httpd (TP 2).
cd "$(dirname "$0")"
docker run --rm httpd:2.4 cat /usr/local/apache2/conf/httpd.conf > httpd.conf
sed -i -e 's/^#\(LoadModule proxy_module\)/\1/' \
       -e 's/^#\(LoadModule proxy_http_module\)/\1/' \
       -e 's/^#\(LoadModule headers_module\)/\1/' httpd.conf
echo 'Include conf/extra/jenkins.conf' >> httpd.conf
echo "apache/httpd.conf prêt."
