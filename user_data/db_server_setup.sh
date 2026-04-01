#!/bin/bash
exec > /var/log/user-data.log 2>&1
set -e

echo "=== TechCorp DB Server Setup v6 - Amazon Linux 2 Extras Fix ==="

# === SSH Password Auth (already working on web servers) ===
rm -f /etc/ssh/sshd_config.d/50-cloud-init.conf
sed -i 's/^ssh_pwauth:.*/ssh_pwauth: true/' /etc/cloud/cloud.cfg || echo "ssh_pwauth: true" >> /etc/cloud/cloud.cfg
echo "ec2-user:TechCorpPass2026!" | chpasswd
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
systemctl restart sshd

# === Install PostgreSQL 14 using Amazon Linux Extras (works on AL2) ===
amazon-linux-extras enable postgresql14

yum update -y
yum install -y postgresql-server postgresql-contrib

# Initialize database
postgresql-setup --initdb

systemctl start postgresql
systemctl enable postgresql

# Create database and set password
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'TechCorp2026!';"
sudo -u postgres createdb techcorp_db

# Allow connections from Web servers
sed -i "s/ident/md5/g" /var/lib/pgsql/data/pg_hba.conf
echo "host    all             all             10.0.0.0/16            md5" >> /var/lib/pgsql/data/pg_hba.conf
systemctl restart postgresql

echo "=== DB Setup COMPLETE at $(date) ==="
echo "Username : ec2-user"
echo "Password : TechCorpPass2026!"
echo "Postgres password : TechCorp2026!"
echo "Database : techcorp_db is ready"