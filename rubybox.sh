#!/usr/bin/env bash

APPNAME='dave'

apt-get update
apt-get install -y git build-essential postgresql postgresql-contrib bison openssl zlib1g zlib1g-dev libssl-dev libyaml-dev libxml2-dev libxslt1-dev autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev

if [ ! -d "/home/vagrant/.rbenv" ]; then
  sudo -u vagrant git clone https://github.com/sstephenson/rbenv.git /home/vagrant/.rbenv || true
  sudo -u vagrant git clone https://github.com/sstephenson/ruby-build.git /home/vagrant/.rbenv/plugins/ruby-build || true
fi

rm /home/vagrant/.bash_profile
sudo -u vagrant -i echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> /home/vagrant/.bash_profile
sudo -u vagrant -i echo 'eval "$(rbenv init -)"' >> /home/vagrant/.bash_profile

# no rdoc for installed gems
sudo -u vagrant -i echo 'gem: --no-ri --no-rdoc' >> /home/vagrant/.gemrc
# install required ruby versions
curl -fsSL https://gist.github.com/mislav/a18b9d7f0dc5b9efc162.txt | sudo -u vagrant -i rbenv install --patch 2.1.1
sudo -u vagrant -i ruby -v
sudo -u vagrant -i gem install bundler --no-ri --no-rdoc
sudo -u vagrant -i rbenv rehash

chown -R vagrant:vagrant /home/vagrant/.rbenv

if [ ! -d "/home/vagrant/.dotfiles" ]; then
  sudo -u vagrant -i git clone https://github.com/ptrr/dotfiles.git /home/vagrant/.dotfiles
  sudo -u vagrant -i /home/vagrant/.dotfiles/script/install
fi

# Edit the following to change the name of the database user that will be created:
APP_DB_USER='postgres'
APP_DB_PASS=''
# Edit the following to change the name of the database that is created (defaults to the user name)
APP_DB_NAME=$APPNAME
# Edit the following to change the version of PostgreSQL that is installed
PG_VERSION=9.3
###########################################################
# Changes below this line are probably not necessary
###########################################################
print_db_usage () {
echo "Your PostgreSQL database has been setup and can be accessed on your local machine on the forwarded port (default: 15432)"
echo " Host: localhost"
echo " Port: 15432"
echo " Database: $APP_DB_NAME"
echo " Username: $APP_DB_USER"
echo " Password: $APP_DB_PASS"
echo ""
echo "Admin access to postgres user via VM:"
echo " vagrant ssh"
echo " sudo su - postgres"
echo ""
echo "psql access to app database user via VM:"
echo " vagrant ssh"
echo " sudo su - postgres"
echo " PGUSER=$APP_DB_USER PGPASSWORD=$APP_DB_PASS psql -h localhost $APP_DB_NAME"
echo ""
echo "Env variable for application development:"
echo " DATABASE_URL=postgresql://$APP_DB_USER:$APP_DB_PASS@localhost:15432/$APP_DB_NAME"
echo ""
echo "Local command to access the database via psql:"
echo " PGUSER=$APP_DB_USER PGPASSWORD=$APP_DB_PASS psql -h localhost -p 15432 $APP_DB_NAME"
}
export DEBIAN_FRONTEND=noninteractive
PROVISIONED_ON=/etc/vm_provision_on_timestamp
if [ -f "$PROVISIONED_ON" ]
then
echo "VM was already provisioned at: $(cat $PROVISIONED_ON)"
echo "To run system updates manually login via 'vagrant ssh' and run 'apt-get update && apt-get upgrade'"
echo ""
print_db_usage
exit
fi
PG_REPO_APT_SOURCE=/etc/apt/sources.list.d/pgdg.list
if [ ! -f "$PG_REPO_APT_SOURCE" ]
then
# Add PG apt repo:
echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > "$PG_REPO_APT_SOURCE"
# Add PGDG repo key:
wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add -
fi
# Update package list and upgrade all packages
apt-get update
apt-get -y upgrade
apt-get -y install "postgresql-$PG_VERSION" "postgresql-contrib-$PG_VERSION"
PG_CONF="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
PG_HBA="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"
PG_DIR="/var/lib/postgresql/$PG_VERSION/main"
# Edit postgresql.conf to change listen address to '*':
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"
# Append to pg_hba.conf to add password auth:
echo "host all all all md5" >> "$PG_HBA"
# Restart so that all new config is loaded:
service postgresql restart
cat << EOF | su - postgres -c psql
-- Create the database user:
CREATE USER $APP_DB_USER WITH PASSWORD '$APP_DB_PASS';
-- Create the database:
CREATE DATABASE $APP_DB_NAME WITH OWNER $APP_DB_USER;
EOF
# Tag the provision time:
date > "$PROVISIONED_ON"
echo "Successfully created PostgreSQL dev virtual machine."
echo ""
print_db_usage

## DAVE SPECIFIC ##



## END DAVE SPECIFIC ##
