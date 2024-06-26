# Step-by-Step Installation Security Onion
- This guide provide step by step installation of the Security Onion involves several steps to set up the system and configure it for network security monitoring.
- Begin Installation: Follow the on-screen instructions to start the installation process. 
- Security Onion offers options for standalone, distributed, or evaluation mode. This page provides details of deployment on a single-server setup
-  Login to the Google Compute Engine (VM)  using GCloud
```
gcloud compute ssh --zone "us-east4-a" "security-onio" --tunnel-through-iap --project "project-name"
```
- Once on the Operating System terminal

```
sudo su -
cd /securityonion
sudo bash so-setup-network
```
- It will start the installation process. Click Yes to continue
![Google Compute Engine](../images/so1.png?raw=true "Google Compute Engine")
 
- Select the installation Option (For the GCP Blueprint project, we attempted with EVAL)
![Security Onion ](../images/so2.png?raw=true "Security Onion ")

- Once prompted Type AGREE on the Elastic License version and select OK
![Security Onion ](../images/so3.png?raw=true "Security Onion ")

- Type the hostname try keeping a short hostname seconion
![Security Onion ](../images/so4.png?raw=true "Security Onion ")

- Select Yes in the network install we assume the management, interface, DNS, Hostname, etc are already set up.
![Security Onion ](../images/so5.png?raw=true "Security Onion ")

- Select Yes in the Using DHCP
![Security Onion ](../images/so6.png?raw=true "Security Onion ")

- Select the NIC  eth0
![Security Onion ](../images/so7.png?raw=true "Security Onion ")

- Select Direct to connect to Internet
![Security Onion ](../images/so8.png?raw=true "Security Onion ")

- Select Yes on Docker IP Range  
![Security Onion ](../images/so9.png?raw=true "Security Onion ")

- Select the NICs to Monitor Interface
![Security Onion ](../images/so10.png?raw=true "Security Onion ")

- Enter the email address of the Security Admin
![Security Onion ](../images/so11.png?raw=true "Security Onion ")

- Enter the password 
![Security Onion ](../images/so12.png?raw=true "Security Onion ")

- Important STEP:  Need External IP with DNS Setup. (Assured work load)
![Security Onion ](../images/so14.png?raw=true "Security Onion ")

- Select Yes to web interface
![Security Onion ](../images/so15.png?raw=true "Security Onion ")

- Enter the Single IP Address or range of CIDR 
![Security Onion ](../images/so16.png?raw=true "Security Onion ")

- Select No on SOC Telemetry 
![Security Onion ](../images/so17.png?raw=true "Security Onion ")

- Review the Options
![Security Onion ](../images/so18.png?raw=true "Security Onion ")

- It will take about 30-40 minutes for Security Onion to completed the installation
Once done, you will see following message
![Security Onion](../images/so19.png?raw=true "Security Onion ")
- The console window will show following
![Security Onion](../images/so20.png?raw=true "Security Onion ")