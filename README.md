Install script for CNCjs on Raspberry Pi w/ Raspberry Pi OS

This install script with get you started quickly with CNCjs on a Raspberry Pi. For a more complete introduction, see the [CNCjs Introduction](https://github.com/cncjs/cncjs/wiki/Introduction) section of the wiki page.

### Install Raspberry Pi OS

Download & Install [Raspberry Pi OS](https://www.raspberrypi.org/downloads/raspberry-pi-os/) (previously called Raspbian) the official operating system for the Raspberry Pi.

 1. Download [Raspberry Pi OS Lite](https://downloads.raspberrypi.org/raspios_lite_armhf_latest). 
 2. Then use [Raspberry Pi Imager](https://www.raspberrypi.org/downloads) to write the downloaded image to SD Card or Flash Drive. 

### Install CNCjs
- ##### Method 1: Donwload and run installer.
### `curl -sSL https://raw.githubusercontent.com/cncjs/cncjs-pi-raspbian/master/cncjs_install.sh | bash`

- ##### Method 2: Download, then run installer.
```
wget -O basic-install.sh https://raw.githubusercontent.com/cncjs/cncjs-pi-raspbian/master/cncjs_install.sh
sudo bash basic-install.sh
```
