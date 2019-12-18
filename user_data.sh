#!/bin/bash
yum update
yum install httpd -y
service httpd start
chkconfig httpd on
cd /var/www/html
echo "<html><h1>This is WebServer</h1></html>" > index.html
