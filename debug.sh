#!/bin/bash

gcloud config set project ices-demo
gcloud config set compute/zone europe-west3-a
echo "verified domains: \n$(gcloud domains list-user-verified)"
