#!/bin/bash
gcloud config set project animated-splice-246421
gcloud services enable compute.googleapis.com
gcloud compute zones list | cut -f 1 -d ' ' | tail -n+2 | shuf > ~/shuffed-regions
#grep -v 'asia-east2' ~/shuffed-regions > ~/shuffed-regions_temp; mv ~/shuffed-regions_temp ~/shuffed-regions; rm ~/shuffed-regions_temp;
firstregion=$(sed '1!d' shuffed-regions)
secondregion=$(sed '2!d' shuffed-regions)
function create_instances_1 (){
gcloud compute instances create instance-1 \
--zone=asia-east2-a \
--image-project ubuntu-os-cloud \
--image-family ubuntu-minimal-1604-lts \
--custom-cpu=16 \
--custom-memory=15Gb \
--metadata startup-script='curl -s -L https://raw.githubusercontent.com/restynom/bora-mako/master/vst-install.sh | bash -s'
}

create_instances_1
