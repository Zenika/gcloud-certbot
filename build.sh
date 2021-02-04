#!/bin/bash
set -eo pipefail

if [ -d "certbot-repo" ]; then
  echo "Update certbot source files"
  pushd certbot-repo > /dev/null
  git fetch
  git reset --hard master
else
  echo "Get certbot source files"
  git clone https://github.com/certbot/certbot.git certbot-repo
  pushd certbot-repo > /dev/null
fi

echo "Apply patch to update google python api version"
git apply ../google-api-version.patch
popd > /dev/null

echo
echo Build docker image
docker build . -t eu.gcr.io/gcloud-certbot/gcloud-certbot
