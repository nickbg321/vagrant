#!/bin/bash
mysqlpass="1234"

export DEBIAN_FRONTEND=noninteractive

# Change working dir to /vagrant on login
echo "cd /vagrant" >> /home/vagrant/.profile

# Install software
apt-get update && apt-get install nginx mysql-server \
    redis-server ruby ruby-dev libsqlite3-dev htop build-essential \
    php7.4-fpm php7.4-mysql php7.4-curl php7.4-cli php7.4-intl php7.4-gd php7.4-zip \
    php7.4-bcmath php7.4-mbstring php7.4-bz2 php7.4-xml php-xdebug php7.4-soap -y

# Install MailCatcher
gem install mailcatcher

# Install & configure Composer
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

echo "export PATH=\"\$PATH:/home/vagrant/.config/composer/vendor/bin\"" >> /home/vagrant/.profile

# Configure NGINX
sed -i "s/# server_names_hash_bucket_size 64/server_names_hash_bucket_size 64/g" /etc/nginx/nginx.conf

nginx_config_dir="/vagrant/vagrant/etc/nginx/*"

for file in $nginx_config_dir
do
    cp "$file" /etc/nginx/sites-available
    ln -s /etc/nginx/sites-available/"$(basename "$file")" /etc/nginx/sites-enabled/
done

systemctl restart nginx

# Configure PHP
cp /vagrant/vagrant/etc/php/php.ini /etc/php/7.4/fpm/conf.d
cp /vagrant/vagrant/etc/php/php.ini /etc/php/7.4/cli/conf.d
cp /vagrant/vagrant/etc/php/xdebug.ini /etc/php/7.4/mods-available

sed -i "s/user = www-data/user = vagrant/g" /etc/php/7.4/fpm/pool.d/www.conf
sed -i "s/group = www-data/group = vagrant/g" /etc/php/7.4/fpm/pool.d/www.conf

systemctl restart php7.4-fpm

# Configure MySQL
mysql -uroot -e "CREATE DATABASE app CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
mysql -uroot -e "CREATE DATABASE app_tests CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
mysql -uroot -e "CREATE USER 'vagrant'@'%' IDENTIFIED BY '$mysqlpass'"
mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO 'vagrant'@'%' WITH GRANT OPTION"
mysql -uroot -e "FLUSH PRIVILEGES"

sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

systemctl restart mysql
