#!/bin/bash

# LAMP STACK INSTALLATION

# UPGRADING THE PACKAGES
sudo apt update -y
sudo apt upgrade -y

# INSTALLING APACHE
sudo apt-get apache2 -y

# INSTALL MYSQL AND SECURE INSTALLATION
sudo apt-get install mysql-server -y
sudo mysql_secure_installation <<EOF
n
y
y
y
y
EOF

# INSTALL PHP AND NECESSARY MODULES
sudo add-apt-repository -y ppa:ondrej/php
sudo apt update
sudo apt-get install php libapache2-mod-php php-common php-xml php-mysql php-gd php-mbstring php-tokenizer php-json php-bcmath php-curl php-zip unzip -y

# INSTALLING COMPOSER FOR THR LARAVEL APP
sudo apt-get install curl
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
composer --version

# ENABLE AND START SERVICES ON BOOT
sudo systemctl enable apache2
sudo systemctl enable mysql

echo "LAMP stack installation complete."

# CLONING AND CONFIGURING THE LARAVEL APP

# DEFINING VARIABLES

repo_url="https://github.com/laravel/laravel"
install_composer=true
apache_config_directory="/etc/apache2/sites-available"
destination_dir="/var/www/html/laravel"

# CHECK IF THE DIRECTORY EXISTS AND IF NOT CREATE IT
if [ ! -d "$destination_dir" ]; then
        sudo mkdir -p "$destination_dir"
fi

# CLONE THE LARAVEL APP
sudo git clone $repo_url $destination_dir
cd $destination_dir

# INSTALL COMPOSER DEPENDENCIES
if [ $install_composer = true ]; then
        sudo -u www-data composer install --no-dev
fi

# CONFIGURING APACHE TO HOST OUR LARAVEL APP
sudo touch $apache_config_ddirectory/laravel.conf.conf
sudo cat <<EOL > $apache_config_directory/laravel.conf.conf
<VirtualHost *:80>
        ServerAdmin sinclairolumide15@gmail.com
        ServerName 192.168.56.10
        DocumentRoot $destination_dir/public

        <Directory $destination_dir/public>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
        </Directory>

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

# ENABLE THE APACHE REWRITE MODULE AND ACTIVATE THE LARAVEL VIRTUAL HOST
sudo a2enmod rewrite
sudo a2ensite laravel.conf.conf
sudo systemctl restart apache2

# LARAVEL PERMISSIONS
sudo chown -R www-data:www-data /var/www/html/laravel
sudo chmod -R 755 /var/www/html/laravel
sudo chmod -R 755 /var/www/html/laravel/storage
sudo chmod -R 755 /var/www/html/laravel/bootstrap/cache

# GENERATE ENCRYPTION KEY
if [ "$PWD" = "$destination_dir" ]; then
        cp .env.example .env
        php artisan key:generate
else
        cd "$destination_dir"
        cp .env.example .env
        php artisan key:generate
fi

# DATABASE SETUP
sudo mysql -e "CREATE DATABASE laravelapp;"
sudo mysql -e "CREATE USER 'admin'@'localhost' IDENTIFIED BY 'rialcnis@0';"
sudo mysql -e "GRANT ALL PRIVILEGES ON laravelapp.* TO 'admin'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# ADDING THE DATABASE CREDENTIALS TO THE .ENV FILE
sed -i 's/APP_URL=.*/APP_URL=192.168.56.10/' .env
sed -i 's/DB_CONNECTION=.*/DB_CONNECTION=mysql/' .env
sed -i 's/DB_HOST=.*/DB_HOST=localhost/' .env
sed -i 's/DB_PORT=.*/DB_PORT=3306/' .env
sed -i 's/DB_DATABASE=.*/DB_DATABASE="laravelapp"/' .env
sed -i 's/DB_USERNAME=.*/DB_USERNAME="admin"/' .env
sed -i 's/DB_PASSWORD=.*/DB_PASSWORD="rialcnis@0"/' .env

# CACHING OUR COMMANDS
php artisan config:cache

# MIGRATING OUR DATABASE
php artisan migrate

echo"Laravel application successfully cloned and configured and is accessible at http://192.168.56.10"
