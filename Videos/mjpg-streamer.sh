#!/bin/bash
# chmod +x mjpg-streamer.sh
# Crontab: @reboot /home/pi/mjpg-streamer/mjpg-streamer.sh start
# Crontab: @reboot /home/pi/mjpg-streamer/mjpg-streamer-experimental/mjpg-streamer.sh start

# https://www.thegeekstuff.com/2010/06/bash-array-tutorial/
# Specify what cameras to start.
# SCRIPTS=("$(dirname "$0")/mjpg-streamer_dev_video0.sh");
SCRIPTS=("$(dirname "$0")/mjpg-streamer_usb-lihappe8_Corp_USB_2_Camera.sh" "$(dirname "$0")/mjpg-streamer_usb-Microsoft_Microsoft_LifeCam_Studio.sh");

# =======================================
for SCRIPT in "${SCRIPTS[@]}"; do
	# Set Scripts as Executable 
	chmod +x "$SCRIPT"
done


function help() {
    echo "Usage: $0 [start|stop|restart]"
    return 0
}

function start() {
	# Run Scripts
	for SCRIPT in "${SCRIPTS[@]}"; do
		bash "$SCRIPT" start
	done
	
	return 0
}

function stop() {
	# Stop Scripts
	for SCRIPT in "${SCRIPTS[@]}"; do
		bash "$SCRIPT" stop
	done
	
    return 0
}


if [ "$1" == "start" ]; then
    start && exit 0 || exit -1
	
elif [ "$1" == "stop" ]; then
    stop && exit 0 || exit -1
	
elif [ "$1" == "restart" ]; then
    stop && sleep 1
    start && exit 0 || exit -1
    
else
    help
	
fi

exit 0