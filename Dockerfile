FROM google/cloud-sdk:latest

# use python 3 by default
RUN mv /usr/bin/python /usr/bin/python2 && ln -s /usr/bin/python3 /usr/bin/python && ln -s /usr/bin/pip3 /usr/bin/pip

# Copy certbot code
WORKDIR /opt/certbot
COPY certbot-repo/CHANGELOG.md certbot-repo/README.rst src/
# We keep the relative path to the requirements file the same because, as of
# writing this, tools/pip_install.py is used in the Dockerfile for Certbot
# plugins and this script expects to find the requirements file there.
COPY certbot-repo/letsencrypt-auto-source/pieces/dependency-requirements.txt letsencrypt-auto-source/pieces/
COPY certbot-repo/tools tools
COPY certbot-repo/acme src/acme
COPY certbot-repo/certbot src/certbot

COPY certbot-repo/certbot-dns-cloudflare src/certbot-dns-cloudflare
COPY certbot-repo/certbot-dns-digitalocean src/certbot-dns-digitalocean
COPY certbot-repo/certbot-dns-dnsimple src/certbot-dns-dnsimple
COPY certbot-repo/certbot-dns-google src/certbot-dns-google
COPY certbot-repo/certbot-dns-linode src/certbot-dns-linode
COPY certbot-repo/certbot-dns-ovh src/certbot-dns-ovh
COPY certbot-repo/certbot-dns-rfc2136 src/certbot-dns-rfc2136
COPY certbot-repo/certbot-dns-route53 src/certbot-dns-route53
COPY certbot-repo/certbot-dns-cloudxns src/certbot-dns-cloudxns
COPY certbot-repo/certbot-dns-dnsmadeeasy src/certbot-dns-dnsmadeeasy
COPY certbot-repo/certbot-dns-luadns src/certbot-dns-luadns
COPY certbot-repo/certbot-dns-nsone src/certbot-dns-nsone

RUN python tools/pip_install.py --no-cache-dir \
      --editable src/acme \
      --editable src/certbot \
      --editable /opt/certbot/src/certbot-dns-cloudflare \
      --editable /opt/certbot/src/certbot-dns-digitalocean \
      --editable /opt/certbot/src/certbot-dns-dnsimple \
      --editable /opt/certbot/src/certbot-dns-google \
      --editable /opt/certbot/src/certbot-dns-linode \
      --editable /opt/certbot/src/certbot-dns-ovh \
      --editable /opt/certbot/src/certbot-dns-rfc2136 \
      --editable /opt/certbot/src/certbot-dns-route53 \
      --editable /opt/certbot/src/certbot-dns-cloudxns \
      --editable /opt/certbot/src/certbot-dns-dnsmadeeasy \
      --editable /opt/certbot/src/certbot-dns-luadns \
      --editable /opt/certbot/src/certbot-dns-nsone

# Overide google api version to fix Metadata collection on Cloud Run
RUN pip uninstall crcmod && pip install --no-cache-dir -U crcmod google-api-python-client==1.11.0

WORKDIR /

COPY --from=msoap/shell2http /app/shell2http /shell2http

CMD [ \
  "/shell2http", \
  "-export-all-vars", "-show-errors", "-include-stderr", \
  "/renew", "/renew-certificates.sh" \
]

RUN mkdir /etc/letsencrypt && echo "max-log-backups = 0" > /etc/letsencrypt/cli.ini

COPY renew-certificates.sh /
