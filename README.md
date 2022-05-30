Install script for CNCjs on Raspberry Pi w/ Raspberry Pi OS

This install script with get you started quickly with CNCjs on a [Raspberry Pi](https://www.raspberrypi.org/products/). For a more complete introduction, see the [CNCjs Introduction](https://github.com/cncjs/cncjs/wiki/Introduction) section of the wiki page.

### 1. [Setup your Raspberry Pi](https://projects.raspberrypi.org/en/projects/raspberry-pi-setting-up)

Download & Install [Raspberry Pi OS](https://www.raspberrypi.org/downloads/raspberry-pi-os/) (previously called Raspbian) the official operating system for the Raspberry Pi.
NOTE: Tested on [Raspberry Pi OS Lite x32 & x64 - April 4th 2022](https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2022-04-07/2022-04-04-raspios-bullseye-armhf-lite.img.xz) (x32 recommended)

 1. Download [Raspberry Pi OS](https://www.raspberrypi.org/downloads/raspberry-pi-os/), the [Lite](https://downloads.raspberrypi.org/raspios_lite_armhf_latest) edition is recommended.
 2. Then use [Raspberry Pi Imager](https://www.raspberrypi.org/downloads) to write the downloaded image to SD Card or Flash Drive. 
 3. Power-on you Raspberry Pi
 4. [Finish Setting up you Raspberry Pi](https://projects.raspberrypi.org/en/projects/raspberry-pi-setting-up)
    * Run "Welcome to Raspberry Pi" or `sudo raspi-config`

### 2. Install CNCjs
- ##### Method 1: Download and run installer.
```
URL="https://raw.githubusercontent.com/cncjs/cncjs-pi-raspbian/master/cncjs_install.sh"
curl -sSL ${URL} | bash
```

----
- ##### Method 2: Download, then run installer.
```
URL="https://raw.githubusercontent.com/cncjs/cncjs-pi-raspbian/master/cncjs_install.sh"
wget -O cncjs_install.sh "${URL}"
cat --number cncjs_install.sh
sudo bash cncjs_install.sh
```

----
#### Additonal Infomation
If you run into issues with installation on a raspberry pi, please post this repositries "[Issues](https://github.com/cncjs/cncjs-pi-raspbian/issues)".