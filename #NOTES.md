# https://github.com/cncjs/cncjs
# https://github.com/cncjs/cncjs/wiki/Setup-Guide:-Raspberry-Pi-%7C-System-Setup-&-Preparation
# https://beebom.com/how-clone-raspberry-pi-sd-card-windows-linux-macos/
# https://github.com/Drewsif/PiShrink

# Configure
sudo raspi-config
# Change Pi Password
# Change Timezone
# Change Hostname
# Change Boot Option: Boot to CLI (No GUI)

# Change ROOT Password
sudo passwd root

# Update System
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
# sudo rpi-update. # Update Raspberry Pi kernel and firmware, [is already done with 'apt-get update / upgrade'](github.com/cncjs/cncjs/issues/97)

# Install Build Essentials & GIT
sudo apt-get install -y build-essential git htop iotop nmon lsof screen

# Reboot
sudo reboot


# ====================================================
# Node Setup
# Install Node.js via Package Manager & Add Package Source
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -  # Install NodeJS v10
sudo apt-get install -y nodejs  # npm nodejs-legacy #(Installed with nodesource)

# Optional: install build tools
# To compile and install native addons from npm you may also need to install build tools:
sudo apt-get install -y build-essential

# Update Node Package Manager (NPM)
sudo npm install npm@latest -g

# Get Version info
echo "[NPM] ============"; which npm; npm -v;
echo "[NODE] ============"; which node; node -v

# Install Latest Release Version of CNCjs
sudo npm install -g cncjs@latest --unsafe-perm

# Install PM2
sudo npm install -g pm2

# Setup PM2 Startup Script
# sudo pm2 startup  # To Start PM2 as root
pm2 startup  # To start PM2 as pi / current user
  #[PM2] You have to run this command as root. Execute the following command:
  sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u pi --hp /home/pi

# Iptables (allow access to port 8000 from port 80)
sudo iptables -t nat -I PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8000

# Make Iptables Persistent
sudo apt-get install iptables-persistent -y


# ====================================================
# Software Setup
# Create CNCjs Directory
mkdir ~/.cncjs
cd ~/.cncjs

# Web UI Downloads
git clone https://github.com/cncjs/cncjs-pendant-tinyweb.git
git clone https://github.com/cncjs/cncjs-shopfloor-tablet.git


# CNCjs Startup command.
pm2 start $(which cncjs) -- --port 8000 --mount /tinyweb:/home/pi/.cncjs/cncjs-pendant-tinyweb/src --mount /tablet:/home/pi/.cncjs/cncjs-shopfloor-tablet/src --mount /cncjs-widget-boilerplate:https://cncjs.github.io/cncjs-widget-boilerplate/v1/


# CNCjs Raspberry Pi Pendant
# Clone Repository
cd ~/.cncjs
git clone https://github.com/cncjs/cncjs-pendant-raspi-gpio.git
cd cncjs-pendant-raspi-gpio*
npm install
# Start
chmod +x "/home/pi/.cncjs/cncjs-pendant-raspi-gpio/bin/cncjs-pendant-raspi-gpio"
pm2 start "/home/pi/.cncjs/cncjs-pendant-raspi-gpio/bin/cncjs-pendant-raspi-gpio" -- --port /dev/ttyUSB0


# PM2 Save Settings
pm2 save  # Set current running apps to startup
pm2 list  # Get list of PM2 processes


# ====================================================
# Videos & Camera's

# Update & Install Tools
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install build-essential libjpeg8-dev imagemagick libv4l-dev cmake -y

# Mjpg-streamer Clone Repo in /tmp
cd /tmp
git clone https://github.com/jacksonliam/mjpg-streamer.git
cd mjpg-streamer/mjpg-streamer-experimental

# Make
make
sudo make install


# Install FFMpeg from Package Manager
sudo apt-get install ffmpeg -y


# Scrips
cd ~/Videos/
chmod +x *.sh

# Create CRON JOB for Streamer
crontab -e
### PASTE: @reboot ~/Videos/mjpg-streamer.sh start
### SAVE & EXIT


# ====================================================
# Reboot
sudo reboot











#################################################
# Build the Image
# https://beebom.com/how-clone-raspberry-pi-sd-card-windows-linux-macos/
# https://github.com/Drewsif/PiShrink
# https://www.raspberrypi.org/documentation/installation/installing-images/README.md
# https://etcher.io/

## Take SD card out of PI, and connect to other computer.

## Make Disk Backup
sudo dd if=/dev/disk2 | pv -s 16G | dd of=~/Downloads/cncjs-app-1.9.15-raspbian-sketch-light_1.#.#_RAW.img

## [Shrink Pi Image](https://github.com/Drewsif/PiShrink)
cp ~/Downloads/cncjs-app-1.9.15-raspbian-sketch-light_1.#.#_RAW.img ~/Downloads/cncjs-app-1.9.15-raspbian-sketch-light_1.#.#.img
sudo pishrink.sh ~/Downloads/cncjs-app-1.9.15-raspbian-sketch-light_1.#.#.img

## Zip

## [Publish](https://github.com/cncjs/cncjs-pi-raspbian/releases)









