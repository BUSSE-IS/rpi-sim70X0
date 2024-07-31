**Raspberry Pi and SIM70X0 via PPP**
This is a little repo to simplify NB-IoT connections on a Raspberry Pi with Waveshare SIM7000/SIM7070 modules. Running the "install.sh" script will install the basic config for PPP connection via USB to the modules. The modules will then connect via NB-IoT. Use the following commands to switch between NB-IoT/CAT-M in the chat-connect scripts connection (NB-IoT is preset in the script):

```
AT+CMNB=2 //Fixed NB-IOT
AT+CMNB=1 //Fixed CAT-M
```
Also, fixed LTE connection might help to connect faster to the network (preset in the script):
```AT+CNMP=38```
For more information visit [M2MSupport](https://m2msupport.net/m2msupport/atcmnb-preferred-selection-between-cat-m-and-nb-iot/).

**Caution**
This repo is part of a bigger project. Therefore you will find the line ```sudo /etc/init.d/rinetd restart``` in the script. If you do not use rinetd as a service, simply remove the line from the ```reconnect.sh``` script.

**Installation**
Simply ```cd``` into the repo and run
```
sudo chmod +x install.sh
sudo ./install.sh
```
All necessary packages will be installed. You will be asked to install a service that will care for automatically reconnecting the device to the network. If you do that, the device will check every 3 minutes for an internet connection. If more than 90 minutes passed without internet connection, the device will initate a reboot.

