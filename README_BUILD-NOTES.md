# CNCjs Raspberry Pi Image
- https://github.com/cncjs/cncjs
- https://github.com/cncjs/cncjs/wiki/Setup-Guide:-Raspberry-Pi-%7C-System-Setup-&-Preparation
- https://beebom.com/how-clone-raspberry-pi-sd-card-windows-linux-macos/
- https://github.com/Drewsif/PiShrink

---------------

## Raspberry Pi
### Configure
`sudo raspi-config`

 - Change Pi Password
 - Change Timezone
 - Change Hostname
 - Change Boot Option: Boot to CLI (No GUI)

~~~### Change ROOT Password~~~
~~~`sudo passwd root`~~~

### Update System
```
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
###sudo rpi-update. # Update Raspberry Pi kernel and firmware, [is already done with 'apt-get update / upgrade'](github.com/cncjs/cncjs/issues/97)
```

### Install Build Essentials & GIT
`sudo apt-get install -y build-essential git htop iotop nmon lsof screen bc`

### Reboot
`sudo reboot`

---------------

## Node Setup
### Install Node.js via Package Manager & Add Package Source
```
# Remove Old Packages (Optional)
###sudo apt-get purge -y npm nodejs
###sudo apt-get autoremove -y

# Install NodeJS v10 (Old Method)
##curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -  # Install NodeJS v10
##sudo apt-get install -y nodejs ## npm  ## npm nodejs-legacy #(Installed with nodesource)

# Install NodeJS (New Method)
sudo apt update
sudo apt -y install curl dirmngr apt-transport-https lsb-release ca-certificates
curl -sL https://deb.nodesource.com/setup_10.x | sudo bash

sudo apt update
sudo apt -y install gcc g++ make build-essential
sudo apt -y install nodejs
```

### Update Node Package Manager (NPM)
```
sudo apt -y install npm
sudo npm install npm@latest -g
```

#### Get Version info
```
echo "[NPM] ============"; which npm; npm -v
echo "[NODE] ============"; which node; node -v
```

## Install Latest Release Version of CNCjs
`sudo npm install -g cncjs@latest --unsafe-perm`

## Install PM2
`sudo npm install -g pm2`

### Setup PM2 Startup Script
### sudo pm2 startup  # To Start PM2 as root
```
pm2 startup  # To start PM2 as pi / current user
  #[PM2] You have to run this command as root. Execute the following command:
  sudo env PATH=$PATH:/usr/bin /usr/local/lib/node_modules/pm2/bin/pm2 startup systemd -u pi --hp /home/pi
```

## Software Setup

### Create CNCjs Directory
```
mkdir ~/.cncjs
cd ~/.cncjs
```

### Web UI Downloads
```
git clone https://github.com/cncjs/cncjs-pendant-tinyweb.git
git clone https://github.com/cncjs/cncjs-shopfloor-tablet.git
```

### CNCjs Startup command.
```
pm2 start $(which cncjs) -- --port 8000 --mount /tinyweb:/home/pi/.cncjs/cncjs-pendant-tinyweb/src --mount /tablet:/home/pi/.cncjs/cncjs-shopfloor-tablet/src --mount /cncjs-widget-boilerplate:https://cncjs.github.io/cncjs-widget-boilerplate/v1/
```

### PM2 Save Settings
```
pm2 save  # Set current running apps to startup
pm2 list  # Get list of PM2 processes
```

### Iptables (allow access to port 8000 from port 80)
```
# Iptables (allow access to port 8000 from port 80)
sudo iptables -t nat -I PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8000

# Make Iptables Persistent
sudo apt-get install iptables-persistent -y

# How-to: Save & Reload Rules
#sudo netfilter-persistent save
#sudo netfilter-persistent reload

# How-to: Manually Save Rules
#sudo sh -c "iptables-save > /etc/iptables/rules.v4"
#sudo sh -c "ip6tables-save > /etc/iptables/rules.v6"

# Run this if issues to reconfigure iptables-persistent
# sudo dpkg-reconfigure iptables-persistent
```

---------------

## CNCjs Raspberry Pi Pendant
### Clone Repository
```
cd ~/.cncjs
git clone https://github.com/cncjs/cncjs-pendant-raspi-gpio.git
cd cncjs-pendant-raspi-gpio*
npm install
```

### Start
```
chmod +x "/home/pi/.cncjs/cncjs-pendant-raspi-gpio/bin/cncjs-pendant-raspi-gpio"
pm2 start "/home/pi/.cncjs/cncjs-pendant-raspi-gpio/bin/cncjs-pendant-raspi-gpio" -- --port /dev/ttyUSB0
```
This is just to make sure it starts.

---------------

## Videos & Camera's

### Update & Install Tools
```
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install build-essential libjpeg8-dev imagemagick libv4l-dev cmake -y
```

## Mjpg-streamer Clone Repo in /tmp
```
cd /tmp
git clone https://github.com/jacksonliam/mjpg-streamer.git
cd mjpg-streamer/mjpg-streamer-experimental
```

### Make
```
make
sudo make install
```

## Install FFMpeg from Package Manager
`sudo apt-get install ffmpeg -y`


### Get Scrips
```
# Download Repo
cd /tmp
git clone https://github.com/cncjs/cncjs-pi-raspbian.git

# Copy Repo Contents
mkdir ~/Videos/
cd ~/Videos/
cp /tmp/cncjs-pi-raspbian/Videos/* ~/Videos/
chmod +x *.sh
```

### Create CRON JOB for Streamer
```
crontab -e
### PASTE: @reboot ~/Videos/mjpg-streamer.sh start
### SAVE & EXIT
```

---------------

## Setup a Raspberry Pi to run a Web Browser in Kiosk Mode

https://die-antwort.eu/techblog/2017-12-setup-raspberry-pi-for-kiosk-mode/
https://www.repetier-server.com/booting-into-touchscreen-mode-for-linux/

### Minimum Environment for GUI Applications

```
# The bare minimum we need are X server and window manager.
sudo apt-get install -y --no-install-recommends xserver-xorg x11-xserver-utils xinit openbox
sudo apt-get install -y --no-install-recommends xserver-xorg-legacy
```


### Web Browser

```
# We’ll use Chromium because it provides a nice kiosk mode:
sudo apt-get install -y --no-install-recommends chromium-browser
###sudo apt-get install -y --no-install-recommends chromium-browser rpi-chromium-mods  # (Optional)
```


### Openbox Configuration

First we disable screen blanking and power management (we don’t want our screen to go blank or even turn off completely after some time).

Then we allow to quit the X server by pressing Ctrl-Alt-Backspace. (Because we didn’t install a desktop environment there won’t be a “Log out” button or the like.)

Finally we tell Openbox to start Chromium in kiosk mode. This turns out to be a bit intricate because Chromium loves to show various tool bubbles for session restore etc. The simplest way to avoid all of these seems to be tricking Chromium into thinking it exited cleanly last time it was run (see this answer on Super User for details).

```
mkdir -p /home/pi/.config/openbox/

cat > /home/pi/.config/openbox/autostart << "EOF"
# Disable any form of screen saver / screen blanking / power management
xset s off
xset s noblank
xset -dpms

# Allow quitting the X server with CTRL-ATL-Backspace
setxkbmap -option terminate:ctrl_alt_bksp

# Start Chromium in kiosk mode
sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' ~/.config/chromium/'Local State'
sed -i 's/"exited_cleanly":false/"exited_cleanly":true/; s/"exit_type":"[^"]\+"/"exit_type":"Normal"/' ~/.config/chromium/Default/Preferences
chromium-browser --noerrdialogs --disable-suggestions-service --disable-translate --disable-save-password-bubble --disable-session-crashed-bubble --disable-infobars --touch-events=enabled --disable-gesture-typing --kiosk 'http://localhost:8000/tinyweb'
EOF
```

### User Permissions
https://www.raspberrypi.org/forums/viewtopic.php?t=171843

```
sudo usermod -a -G tty pi
```


#### TEST
That’s it! Time to give it a try:
NOTE: must run command from terminal with monitor.

`startx -- -nocursor`  

Press Ctrl-Alt-Backspace to quite the X server, bringing you back into the text console.


### Start X automatically on boot

```
cat > '/home/pi/.xinitrc' << "EOF"
exec openbox-session
EOF
```

```
cat >> '/home/pi/.bashrc' << "EOF"
# Start Web Kiosk
[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && startx -- -nocursor
EOF
```

---------------

### Reboot
`sudo reboot`

---------------


# Build the Image (Using Docker)
 - https://beebom.com/how-clone-raspberry-pi-sd-card-windows-linux-macos/
 - https://github.com/Drewsif/PiShrink
 - https://www.raspberrypi.org/documentation/installation/installing-images/README.md
 - https://etcher.io/

1. Take SD card out of PI, and connect to other computer.
2. Set Image Version verable.

`image_version='1.0.1'`

3. Make Disk Backup

```
cd ~/Downloads/
sudo dd if=/dev/sdu | pv -s 16G | dd of=$(pwd)/cncjs-app-1.9.15-raspbian-sketch-light_${image_version}_RAW.img
```

4. [Shrink Pi Image](https://github.com/Drewsif/PiShrink)

```
# Set Working Directory
cd ~/Downloads/

# Make Backup${image_version}
###cp "$(pwd)/cncjs-app-1.9.15-raspbian-sketch-light_${image_version}_RAW.img" "$(pwd)/cncjs-app-1.9.15-raspbian-sketch-light_${image_version}.img"
pv "$(pwd)/cncjs-app-1.9.15-raspbian-sketch-light_${image_version}_RAW.img" > "$(pwd)/cncjs-app-1.9.15-raspbian-sketch-light_${image_version}.img"

# Use Docker Container to Run pishrink.sh
alias pishrink='docker run --privileged --rm -u root:$(id -g) -v "$(pwd):/workdir" turee/pishrink-docker pishrink'
pishrink "cncjs-app-1.9.15-raspbian-sketch-light_${image_version}.img"
```

5. Zip it...
```
zip -9 --junk-paths "cncjs-app-1.9.15-raspbian-sketch-light_${image_version}.zip" "$(pwd)/cncjs-app-1.9.15-raspbian-sketch-light_${image_version}.img"
```

6. [Publish](https://github.com/cncjs/cncjs-pi-raspbian/releases)

Also of note
```
# https://serverfault.com/questions/806812/docker-run-bash-script-then-remove-container

cd ~/Downloads/
cat << EOF > script.sh
echo 'Hello, world'
EOF

docker run --rm -u $(id -u):$(id -g) -v "$(pwd)/script.sh:/script.sh" alpine sh script.sh
```


# Build the Image (Using macOS)
 - https://beebom.com/how-clone-raspberry-pi-sd-card-windows-linux-macos/
 - https://github.com/Drewsif/PiShrink
 - https://www.raspberrypi.org/documentation/installation/installing-images/README.md
 - https://etcher.io/

1. Take SD card out of PI, and connect to other computer.
2. Make Disk Backup
`sudo dd if=/dev/disk2 | pv -s 16G | dd of=~/Downloads/cncjs-app-1.9.15-raspbian-sketch-light_1.x.x_RAW.img`
3. [Shrink Pi Image](https://github.com/Drewsif/PiShrink)
```
cp ~/Downloads/cncjs-app-1.9.15-raspbian-sketch-light_1.x.x_RAW.img ~/Downloads/cncjs-app-1.9.15-raspbian-sketch-light_1.x.x.img
sudo pishrink.sh ~/Downloads/cncjs-app-1.9.15-raspbian-sketch-light_1.x.x.img
```
4. Zip it...
5. [Publish](https://github.com/cncjs/cncjs-pi-raspbian/releases)
