#!/usr/bin/env bash

printf "\n\n Try to apply userpatches/customize-images.sh\n\n"

apt-get update --allow-releaseinfo-change

apt-get install --yes --assume-yes sudo apt-utils wget net-tools unzip

apt-get upgrade --yes --assume-yes
