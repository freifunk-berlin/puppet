#!/bin/bash

COMMON_NAME=$1

if [ "${COMMON_NAME}x" = "x" ]; then
  echo "Usage: ./genkey.sh <dns>"
  exit 1
fi

if [ -f "/etc/ssl/private/${COMMON_NAME}.key" ]; then
    echo "Cert already exists, skipping generating it"
  else

SUB="
C=DE
ST=Berlin
O=Freifunk Berlin
localityName=Berlin
commonName=${COMMON_NAME}
organizationalUnitName=Freifunk Berlin
emailAddress=noc@berlin.freifunk.net
"

openssl req -new \
  -newkey rsa:4096 -keyout "/etc/ssl/private/${COMMON_NAME}.key" \
  -sha256 \
  -nodes \
  -out "/tmp/${COMMON_NAME}.csr"  \
  -batch -subj "$(echo -n "$SUB" | tr "\n" "/")"

openssl x509 -req -days 365 -in "/tmp/${COMMON_NAME}.csr" \
   -signkey "/etc/ssl/private/${COMMON_NAME}.key" \
   -out "/etc/ssl/certs/${COMMON_NAME}.cert"

fi

if [ -f "/etc/ssl/private/${COMMON_NAME}.dh" ]; then
    echo "DH Param already exists, skipping generating it"
  else
    # Only 1024 Bit to make the Box Provisioning faster
    openssl dhparam -out "/etc/ssl/private/${COMMON_NAME}.dh" 1024
fi
