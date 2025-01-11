#!/bin/sh
USER=admin
HOST=dhemasnurjaya.com
DIR=apps/dhemasnurjaya_site/public/
KEY=~/Development/lightsail-defaultkey-ap-southeast-1.pem

# Build using production environment
hugo --environment production

# Upload
rsync \
    -avz -e "ssh -i ${KEY}" \
    --delete public/ ${USER}@${HOST}:~/${DIR}

echo "Deployed to ${HOST}!"
exit 0