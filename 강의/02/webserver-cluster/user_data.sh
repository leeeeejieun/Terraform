#!/bin/bash
dnf -y install httpd
echo "My ALB Web Page" > /var/www/html/index.html
systemctl restart httpd && systemctl enable --now httpd
