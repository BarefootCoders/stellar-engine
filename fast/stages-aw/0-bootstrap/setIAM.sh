#!/bin/bash
sed s/{USER}/$1/g setIAM.yaml.sample > setIAM.yaml
gcloud organizations set-iam-policy $2 setIAM.yaml