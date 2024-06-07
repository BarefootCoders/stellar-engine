# Project factory

The Project Factory (PF) builds on top of your foundations to create and set up projects (and related resources) to be used for your workloads.
It is organized in folders representing environments (e.g. "dev", "prod"), each implemented by a stand-alone terraform [resource factory](https://medium.com/google-cloud/resource-factories-a-descriptive-approach-to-terraform-581b3ebb59c).

This directory contains a single project factory ([`dev/`](./dev/)) as an example - to implement multiple environments (e.g. "prod" and "dev") you'll need to copy the `dev` folder into one folder per environment, then customize each one following the instructions found in [`dev/README.md`](./dev/README.md).

The project factory will create projects and each project will have a New VPC that is peer-to-peer connection with the Host VPC. The project will have one VPC with one subnet. The CIDR Table is below


Project 1 CIDR = 10.210.0.0/24
Project 2 CIDR =  10.220.0.0/24	
Project 3 CIDR = 10.230.0.0/24	
Project 4 CIDR = 10.240.0.0/24	
Project 5 CIDR = 10.250.0.0/24	


 