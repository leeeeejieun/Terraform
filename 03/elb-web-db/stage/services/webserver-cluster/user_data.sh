#!/bin/bash

dnf -y install httpd
cat << EOF > /var/www/html/index.html
<h1>DB IP: ${dbaddress}</h1>
<h1>DB Name: ${dbname}</h1>
<h1>DB Name: ${dbport}</h1>
EOF
systemctl enable --now httpd
