#!/bin/bash
mysqlpass="1234"

export DEBIAN_FRONTEND=noninteractive

# Change working dir to /vagrant on login
echo "cd /vagrant" >> /home/vagrant/.profile

# Prepare root password for MySQL
debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password $mysqlpass"
debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password $mysqlpass"

# Update OS software
apt update
apt upgrade -y
apt dist-upgrade -y
apt autoremove -y

# Install software
apt install nginx mysql-server redis-server unzip unrar htop build-essential \
    php7.4-fpm php7.4-mysql php7.4-curl php7.4-cli php7.4-intl php7.4-gd php7.4-zip \
    php7.4-bcmath php7.4-mbstring php7.4-bz2 php7.4-xml php-xdebug php7.4-soap -y

# Configure NGINX
sed -i "s/# server_names_hash_bucket_size 64/server_names_hash_bucket_size 64/g" /etc/nginx/nginx.conf

cp /vagrant/vagrant/etc/nginx/app.local /etc/nginx/sites-available
cp /vagrant/vagrant/etc/nginx/mailcatcher.local /etc/nginx/sites-available

ln -s /etc/nginx/sites-available/app.local /etc/nginx/sites-enabled/
ln -s /etc/nginx/sites-available/mailcatcher.local /etc/nginx/sites-enabled/

systemctl restart nginx

# Configure PHP
cp /vagrant/vagrant/etc/php/php.ini /etc/php/7.4/fpm/conf.d
cp /vagrant/vagrant/etc/php/php.ini /etc/php/7.4/cli/conf.d
cp /vagrant/vagrant/etc/php/xdebug.ini /etc/php/7.4/mods-available

systemctl restart php7.4-fpm

# Configure MySQL
mysql -uroot -p -e "CREATE DATABASE app CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
mysql -uroot -p -e "CREATE DATABASE app_tests CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
mysql -uroot -p -e "CREATE USER 'vagrant'@'%' IDENTIFIED BY '$mysqlpass'"
mysql -uroot -p -e "GRANT ALL PRIVILEGES ON *.* TO 'vagrant'@'%' WITH GRANT OPTION"
mysql -uroot -p -e "FLUSH PRIVILEGES"

sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

systemctl restart mysql

# Install MailCatcher
apt install ruby ruby-dev libsqlite3-dev -y
gem install mailcatcher

# Install Composer
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

cat << EOF >> /home/vagrant/.profile
export PATH="$PATH:/home/vagrant/.config/composer/vendor/bin"
EOF
