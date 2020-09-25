FROM google/cloud-sdk:latest

RUN apt-get update

RUN apt-get install -y certbot \
  python3-certbot-dns-cloudflare \
  python3-certbot-dns-digitalocean \
  python3-certbot-dns-dnsimple \
  python3-certbot-dns-google \
  python3-certbot-dns-linode \
  python3-certbot-dns-ovh \
  python3-certbot-dns-rfc2136 \
  python3-certbot-dns-route53
  # FIXME: Add this packages when released on Debian repositories
  # python3-certbot-dns-cloudxns \
  # python3-certbot-dns-dnsmadeeasy \
  # python3-certbot-dns-luadns \
  # python3-certbot-dns-nsone \

COPY --from=msoap/shell2http /app/shell2http /shell2http

RUN pip3 uninstall crcmod && pip3 install --no-cache-dir -U crcmod

ENTRYPOINT ["/shell2http","-export-all-vars", "-show-errors", "-include-stderr"]
CMD ["/renew", "/renew-certificates.sh", "/debug", "/debug.sh"]

COPY renew-certificates.sh /
