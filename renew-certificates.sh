#!/bin/bash
set -eo pipefail

echo "Setup letsencrypt context..."

gsutil -m rsync -r "${LETSENCRYPT_BUCKET}" /etc/letsencrypt

echo "Renewing certificate..."

dns_provider_options="--dns-${DNS_PROVIDER}"
if [ "${DNS_PROVIDER}" != "route53" ] && [ "${DNS_PROVIDER}" != "google" ]; then
  echo -e "${DNS_PROVIDER_CREDENTIALS}" > /dns_api_key.ini
  dns_provider_options="${dns_provider_options} --dns-${DNS_PROVIDER}-credentials /dns_api_key.ini"
fi

service_domain_names=$(gcloud app services list --format "get(id)" | sed "s/\(.*\)/-d *.\1.${CUSTOM_DOMAIN}/" | paste -d " " -s)

echo certbot command: certbot certonly -n \
  -m "${LETSENCRYPT_CONTACT_EMAIL}" --agree-tos \
  --preferred-challenges dns ${dns_provider_options} \
  -d "*.${CUSTOM_DOMAIN}" -d "${CUSTOM_DOMAIN}" ${service_domain_names}

certbot certonly -n \
  -m "${LETSENCRYPT_CONTACT_EMAIL}" --agree-tos \
  --preferred-challenges dns ${dns_provider_options} \
  -d "*.${CUSTOM_DOMAIN}" -d "${CUSTOM_DOMAIN}" ${service_domain_names}

echo "Convert private key into RSA format"
openssl rsa \
  -in "/etc/letsencrypt/live/${CUSTOM_DOMAIN}/privkey.pem" \
  -out "/etc/letsencrypt/live/${CUSTOM_DOMAIN}/privkey-rsa.pem" \


echo "Backup of letsencrypt context"
gsutil -m rsync -r /etc/letsencrypt "${LETSENCRYPT_BUCKET}"

echo "Install certificate on App Engine"
certificate_id=$(gcloud app ssl-certificates list --format "get(id,display_name)" | grep -F "${CUSTOM_DOMAIN}" | head -n 1 | cut -f 1 || true)
echo "Found existing certificate : ${certificate_id}"

if [ "${certificate_id}" = "" ]; then
  echo "Creating new certificate"
  certificate_id=$(gcloud app ssl-certificates create \
    --display-name "${CERTIFICATE_NAME}" \
    --certificate "/etc/letsencrypt/live/${CUSTOM_DOMAIN}/fullchain.pem" \
    --private-key "/etc/letsencrypt/live/${CUSTOM_DOMAIN}/privkey-rsa.pem" \
    --format "get(id)")
else
  echo "Updating existing certificate"
  gcloud app ssl-certificates update "${certificate_id}" \
    --certificate "/etc/letsencrypt/live/${CUSTOM_DOMAIN}/fullchain.pem" \
    --private-key "/etc/letsencrypt/live/${CUSTOM_DOMAIN}/privkey-rsa.pem"
fi

echo "Enable certificate on *.${CUSTOM_DOMAIN} domain mapping"
gcloud app domain-mappings update "*.${CUSTOM_DOMAIN}" --certificate-management manual --certificate-id "${certificate_id}"
