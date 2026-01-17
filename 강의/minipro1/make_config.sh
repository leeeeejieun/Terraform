#!/bin/bash
cat << EOF >> ~/.ssh/config

Host ${hostname}
  HostName ${hostname}
  IdentityFile ${identifyfile}
  User ${user}
  ForwardAgent yes
~/.ssh/mykeypair

EOF

chmod 600 ~/.ssh/config