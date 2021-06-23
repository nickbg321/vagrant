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

# Configure PHP
cp /vagrant/vagrant/etc/php/php.ini /etc/php/7.4/fpm/conf.d
cp /vagrant/vagrant/etc/php/xdebug.ini /etc/php/7.4/mods-available

# Configure MySQL
sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
mysql -uroot -p$mysqlpass <<< "CREATE USER 'root'@'%' IDENTIFIED BY '$mysqlpass'"
mysql -uroot -p$mysqlpass <<< "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION"
mysql -uroot -p$mysqlpass <<< "DROP USER 'root'@'localhost'"
mysql -uroot -p$mysqlpass <<< "FLUSH PRIVILEGES"

systemctl restart mysql

# Install MailCatcher
apt install ruby ruby-dev libsqlite3-dev -y
gem install mailcatcher
systemctl restart php7.4-fpm

# Install Composer
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

cat << EOF >> /home/vagrant/.profile
export PATH="$PATH:/home/vagrant/.config/composer/vendor/bin"
EOF

# Configure NGINX
sed -i "s/# server_names_hash_bucket_size 64/server_names_hash_bucket_size 64/g" /etc/nginx/nginx.conf

cp /vagrant/vagrant/etc/nginx/app.local /etc/nginx/sites-available
cp /vagrant/vagrant/etc/nginx/mailcatcher.local /etc/nginx/sites-available

ln -s /etc/nginx/sites-available/app.local /etc/nginx/sites-enabled/
ln -s /etc/nginx/sites-available/mailcatcher.local /etc/nginx/sites-enabled/

systemctl restart nginx

# Setup the application
# Create project database
mysql -u root -p$mysqlpass -e "CREATE DATABASE app CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;";

# Create tests database
mysql -u root -p$mysqlpass -e "CREATE DATABASE app_tests CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;";
