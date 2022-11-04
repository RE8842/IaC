#!/bin/bash

yum upgrade --refresh -y

export NAME=RONNY
export CLOUD=AWS
export HOSTNAME=STSVM

yum install httpd -y
systemctl enable httpd
systemctl start httpd

echo "hello world, my name is " $NAME ", my favorite Cloud Provider is " $CLOUD " and my computer's name is" $HOSTNAME > index.html
mv index.html /var/www/html
chmod 755 /var/www/html/index.html

yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum -y install dnf-utils http://rpms.remirepo.net/enterprise/remi-release-8.rpm
yum -y module list php
yum -y module enable php:remi-8.1
yum -y install php
echo "<?php phpinfo(); ?>" > test.php
mv test.php /var/www/html
chmod 755 /var/www/html/test.php
systemctl restart httpd.service

wget https://ftp.drupal.org/files/projects/drupal-9.4.8.tar.gz
tar -xvf drupal-9.4.8.tar.gz
mv drupal-9.4.8 /var/www/html/drupal
chown -R apache:apache /var/www/html/drupal
cp /var/www/html/drupal/sites/default/default.settings.php /var/www/html/drupal/sites/default/settings.php
chmod 777 /var/www/html/drupal/sites/default/settings.php
yum install gd gd-devel php-gd
systemctl restart httpd

yum -y install mysql-server mysql
systemctl enable mysqld.service
systemctl start mysqld.service
systemctl restart httpd.service

exit 0