#!/bin/bash
yum install -y httpd
systemctl start httpd
export NAME=RONNY
export CLOUD=AWS
export HOSTNAME=STSVM
echo "hello world, my name is " $NAME ", my favorite Cloud Provider is " $CLOUD " and my computer's name is" $HOSTNAME > index.html
mv index.html /var/www/html
