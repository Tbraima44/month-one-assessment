#!/bin/bash
exec > /var/log/user-data.log 2>&1
set -e

echo "=== TechCorp Web Server Setup v8 - Dynamic Metadata Page ==="

# === SSH Password Auth ===
rm -f /etc/ssh/sshd_config.d/50-cloud-init.conf
sed -i 's/^ssh_pwauth:.*/ssh_pwauth: true/' /etc/cloud/cloud.cfg || echo "ssh_pwauth: true" >> /etc/cloud/cloud.cfg
echo "ec2-user:TechCorpPass2026!" | chpasswd
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
systemctl restart sshd

# === RETRY YUM (keeps targets healthy) ===
yum_retry() {
  for i in {1..8}; do
    echo "YUM attempt $i: $*"
    yum "$@" && return 0
    sleep 15
  done
  echo "ERROR: yum failed after 8 attempts"
  return 1
}

# Install Apache
yum_retry update -y
yum_retry install -y httpd

# === Fetch metadata (these values will appear on the page) ===
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id || echo "unknown")
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4 || echo "unknown")
INSTANCE_TYPE=$(curl -s http://169.254.169.254/latest/meta-data/instance-type || echo "unknown")
AVAILABILITY_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone || echo "unknown")

# Reliable health check for ALB
echo "OK" > /var/www/html/health

# === Stylish page with REAL values inserted ===
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TechCorp Web Application</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; font-family: 'Segoe UI', sans-serif; }
        .card { border: none; border-radius: 15px; box-shadow: 0 10px 30px rgba(0,0,0,0.3); }
        .header { background: rgba(255,255,255,0.95); padding: 2rem 0; margin-bottom: 2rem; }
        .info-box { font-size: 1.1rem; }
    </style>
</head>
<body>
    <div class="header text-center">
        <div class="container">
            <h1 class="display-4 fw-bold text-primary">🚀 TechCorp Web Application</h1>
            <p class="lead text-muted">High Availability • Multi-AZ • Private Subnets</p>
        </div>
    </div>
    <div class="container">
        <div class="row justify-content-center">
            <div class="col-lg-8">
                <div class="card bg-white">
                    <div class="card-body p-5">
                        <div class="text-center mb-4">
                            <h2 class="text-success">✅ Server is Running Successfully</h2>
                        </div>
                        
                        <div class="row g-4 info-box">
                            <div class="col-md-6">
                                <div class="p-3 border rounded bg-light">
                                    <strong>Instance ID:</strong><br>
                                    <span class="text-primary fw-bold">${INSTANCE_ID}</span>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="p-3 border rounded bg-light">
                                    <strong>Private IP Address:</strong><br>
                                    <span class="text-primary fw-bold">${PRIVATE_IP}</span>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="p-3 border rounded bg-light">
                                    <strong>Instance Type:</strong><br>
                                    <span class="text-primary fw-bold">${INSTANCE_TYPE}</span>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="p-3 border rounded bg-light">
                                    <strong>Availability Zone:</strong><br>
                                    <span class="text-primary fw-bold">${AVAILABILITY_ZONE}</span>
                                </div>
                            </div>
                        </div>

                        <div class="text-center mt-5">
                            <p class="text-muted">Served from private subnet behind Application Load Balancer</p>
                            <span class="badge bg-success fs-5 px-4 py-2">HEALTHY • Connected to ALB</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
EOF

systemctl enable httpd
systemctl start httpd
systemctl restart httpd

echo "=== Web Setup COMPLETE at $(date) ==="
echo "Health check ready at /health"
echo "Page values injected: ID=${INSTANCE_ID}, IP=${PRIVATE_IP}, Type=${INSTANCE_TYPE}, AZ=${AVAILABILITY_ZONE}"