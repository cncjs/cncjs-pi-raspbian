#!/usr/bin/env bash
# ===========================================================================
# CNCjs Installer
#  - https://cnc.js.org
#  - https://github.com/cncjs
# 
# How-to Use:
#   curl -sSL https://raw.githubusercontent.com/cncjs/cncjs-pi-raspbian/master/cncjs_install.sh | bash
# 
# License: MIT License
#   Copyright (c) 2018-2020 CNCjs (https://github.com/cncjs)
# 
# Notes:
#   Replaces Prebuilt Images: https://github.com/cncjs/cncjs-pi-raspbian
#   Builds from raspi-config https://github.com/RPi-Distro/raspi-config  (MIT license)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
SCRIPT_TITLE="CNCjs Installer"
SCRIPT_VERSION=1.4.4
SCRIPT_DATE=$(date -I --date '2023/02/10')
SCRIPT_AUTHOR="Austin St. Aubin"
SCRIPT_TITLE_FULL="${SCRIPT_TITLE} v${SCRIPT_VERSION}($(date -I -d ${SCRIPT_DATE})) by: ${SCRIPT_AUTHOR}"
# ===========================================================================

# ----------------------------------------------------------------------------------------------------------------------------------
# -- [ Error / Exception Handling ]
# ----------------------------------------------------------------------------------------------------------------------------------
# -e option instructs bash to immediately exit if any command [1] has a non-zero exit status
# We do not want users to end up with a partially working install, so we exit the script
# instead of continuing the installation with something broken
# set -e

# Catch Expections to users home directory.
cd ~/

# ----------------------------------------------------------------------------------------------------------------------------------
# -- Varrables [ General ]  genneral global varables
# ----------------------------------------------------------------------------------------------------------------------------------
readonly SCRIPT_NAME=$(basename $0)
readonly HOST_IP=$(hostname -I | cut -d' ' -f1)

SYSTEM_CHECK=true  # Preform system check to insure this script is known to be compatable with this OS

CNCJS_EXT_DIR="${HOME}/.cncjs"
CNCJS_PORT=80
cncjs_flags="--port ${CNCJS_PORT} --config \\\"${CNCJS_EXT_DIR}/cncrc.cfg\\\" --watch-directory \\\"${CNCJS_EXT_DIR}/watch\\\""  # --host ${HOST_IP}
COMPATIBLE_OS_ID='^(rasp|de)bian$'
COMPATIBLE_OS_ID_VERSION=11  # greater than or equal

# Detect Compatible GUI
[[ $(dpkg -l|egrep -i "(lxde|openbox)" | grep -v library) ]] && COMPATIBLE_OS_GUI=true || COMPATIBLE_OS_GUI=false

# ----------------------------------------------------------------------------------------------------------------------------------
# -- [ Logging ]  log hidden output to syslog for use in debugging
# ----------------------------------------------------------------------------------------------------------------------------------
# https://www.urbanautomaton.com/blog/2014/09/09/redirecting-bash-script-output-to-syslog/
# Sends stdout output to syslog.
# To Use/View Syslog, use command: tail -f -n 50 /var/log/syslog
exec 4> >(logger -t $(basename $0))

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Color / Messange Handling
COL_NC='\e[0m' # No Color
COL_GREY='\e[2;31;37m'
COL_BLACK='\e[1;30m'
COL_RED='\e[1;31m'
COL_GREEN='\e[1;32m'
COL_YELLOW='\e[1;33m'
COL_BLUE='\e[1;34m'
COL_MAGENTA='\e[1;35m'
COL_CYAN='\e[1;36m'
COL_WHITE='\e[1;37m'

# Message
PASS="${COL_NC}[${COL_GREEN}✓${COL_NC}]"
FAIL="${COL_NC}[${COL_RED}✗${COL_NC}]"
WARN="${COL_NC}[${COL_YELLOW}"'!'"${COL_NC}]"
INFO="${COL_NC}[${COL_CYAN}i${COL_NC}]"
QSTN="${COL_NC}[${COL_MAGENTA}?${COL_NC}]"


# ----------------------------------------------------------------------------------------------------------------------------------
# -- Function [ Spinner ]  spinner animation for commands in progress.
# ----------------------------------------------------------------------------------------------------------------------------------
# https://unix.stackexchange.com/questions/225179/display-spinner-while-waiting-for-some-process-to-finish
# https://wiki.tcl-lang.org/page/Text+Spinner
function spinner() {
	# make sure we use non-unicode character type local
	# (that way it works for any locale as long as the font supports the characters)
	local LC_CTYPE=C
	
	local spin_chars=' ⣾ ⣽ ⣻ ⢿ ⡿ ⣟ ⣯ ⣷ '
	
	local pid=$1 # Process Id of the previous running command
	tput civis  # cursor invisible
	
	# spin animation
	###while kill -0 $pid 2>/dev/null; do
	while ps -p $pid >/dev/null; do
		for spin_i in ${spin_chars[@]}; do 
			echo -ne "\r  [$spin_i]  $2  ";
			sleep 0.1;
		done;
	done
	
	tput cnorm  # cursor visible
	
	wait $pid   # capture exit code
	return $?
}

# ----------------------------------------------------------------------------------------------------------------------------------
# -- Function [ Message ]  message formatter, also used for passing commands.
# ----------------------------------------------------------------------------------------------------------------------------------
msg() {
	# Logging to syslog
	logger -p user.notice -t $SCRIPT_NAME "$2"
	
	# User Output
	case $1 in
		'h') # Header
			printf "\\n %b ${2} %b\\n" "${COL_WHITE}" "${COL_NC}  "
			;;
		'p') # Pass 
			printf "  %b %b ${2} %b\\n" "${PASS}" "${COL_GREEN}" "${COL_NC}  "
			;;
		'x') # Fail
			printf "  %b %b ${2} %b\\n" "${FAIL}" "${COL_RED}" "${COL_NC}  "
			;;
		'!') # Warning
			printf "  %b %b ${2} %b\\n" "${WARN}" "${COL_YELLOW}" "${COL_NC}  "
			;;
		'i') # Informational
			printf "  %b %b ${2} %b\\n" "${INFO}" "${COL_WHITE}" "${COL_NC}  "
			;;
		'?') # Question
			printf "  %b %b ${2} %b\\n" "${QSTN}" "${COL_NC}" "${COL_NC}  "
			;;
		'L') # Bracket
			printf "  %b └── ${2} %b\\n" "${COL_GREY}" "${COL_NC}  "
			;;
		'-') # User Log Output
			line_break='- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -'
			echo -e "${COL_GREY}  ${2} ${line_break:${#2} + 1}\n    ${3}\n  ${line_break} ${COL_NC}"
			;;
		'%') # Spinner / Command
			/bin/sh -c "${3}" >&4 2>&1 & spinner $! "${2}" 
			
			# Capture Error Code
			ERROR_CODE=$?

			# Display Pass/Fail based on error Code
			if [[ ${ERROR_CODE} -eq 0 ]]; then 
				echo -ne "\r  ${PASS} ${COL_GREEN} ${2} ${COL_NC} \n";
			else 
				echo -ne "\r  ${FAIL} ${COL_RED} ${2} ${COL_GREY}|${COL_YELLOW} Error Code: ${ERROR_CODE} ${COL_NC} \n";
				echo -e "   └── Try to re-run this part of the script after rebooting."
				msg - "Latest Syslog Entries" "$(tail -n 6 /var/log/syslog)"
			fi
			
			# Return Error Code
			return ${ERROR_CODE}
			;;
		'%%') # Spinner / Command (No stdout Catpture, only capture stderr)
			/bin/sh -c "${3}" 2>&4 & spinner $! "${2}" 
			
			# Capture Error Code
			ERROR_CODE=$?

			# Display Pass/Fail based on error Code
			if [[ ${ERROR_CODE} -eq 0 ]]; then 
				echo -ne "\r  ${PASS} ${COL_GREEN} ${2} ${COL_NC} \n";
			else 
				echo -ne "\r  ${FAIL} ${COL_RED} ${2} ${COL_GREY}|${COL_YELLOW} Error Code: ${ERROR_CODE} ${COL_NC} \n";
				echo -e "└── Try to re-run this part of the script after rebooting."
				msg - "Latest Syslog Entries" "$(tail -n 6 /var/log/syslog)"
			fi
			
			# Return Error Code
			return ${ERROR_CODE}
			;;
		*) # Catch-all
			echo -e "${@}"
			;;
	esac
}

# # ----------------------------------------------------------------------------------------------------------------------------------
# # -- Function [ Calculate Whiptail Size ]  spinner animation for commands in progress. From raspi-config (MIT license)
# # ----------------------------------------------------------------------------------------------------------------------------------
# calc_wt_size() {
#   # NOTE: it's tempting to redirect stderr to /dev/null, so supress error 
#   # output from tput. However in this case, tput detects neither stdout or 
#   # stderr is a tty and so only gives default 80, 24 values
#   WT_HEIGHT=18
#   WT_WIDTH=$(tput cols)

#   if [ -z "$WT_WIDTH" ] || [ "$WT_WIDTH" -lt 60 ]; then
# 	WT_WIDTH=80
#   fi
#   if [ "$WT_WIDTH" -gt 178 ]; then
# 	WT_WIDTH=120
#   fi
#   WT_MENU_HEIGHT=$(($WT_HEIGHT-7))
# }


# ----------------------------------------------------------------------------------------------------------------------------------
# -- Function [ Set/Clear/Get Varables & Settings ]  set/clear/get varables to/from file. From raspi-config (MIT license)
# ----------------------------------------------------------------------------------------------------------------------------------
set_config_var() {
touch "$3"
lua - "$1" "$2" "$3" <<EOF > "$3.bak"
local key=assert(arg[1])
local value=assert(arg[2])
local fn=assert(arg[3])
local file=assert(io.open(fn))
local made_change=false
for line in file:lines() do
  if line:match("^#?%s*"..key.."=.*$") then
    line=key.."="..value
    made_change=true
  end
  print(line)
end

if not made_change then
  print(key.."="..value)
end
EOF
mv "$3.bak" "$3"
}

clear_config_var() {
touch "$3"
 lua - "$1" "$2" <<EOF > "$2.bak"
local key=assert(arg[1])
local fn=assert(arg[2])
local file=assert(io.open(fn))
for line in file:lines() do
  if line:match("^%s*"..key.."=.*$") then
    line="#"..line
  end
  print(line)
end
EOF
mv "$2.bak" "$2"
}

get_config_var() {
lua - "$1" "$2" <<EOF
local key=assert(arg[1])
local fn=assert(arg[2])
local file=assert(io.open(fn))
local found=false
for line in file:lines() do
  local val = line:match("^%s*"..key.."=(.*)$")
  if (val ~= nil) then
    print(val)
    found=true
    break
  end
end
if not found then
   print(0)
end
EOF
}

# ----------------------------------------------------------------------------------------------------------------------------------
# -- Output [ Header ]  welcome message
# ----------------------------------------------------------------------------------------------------------------------------------
# $(curl --silent "https://api.github.com/repos/cncjs/cncjs/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')  # Get CNCjs Latest Version
echo -e "${COL_BLACK}${SCRIPT_TITLE_FULL}${COL_NC}
     _______   ________  _
    / ____/ | / / ____/ (_)____
   / /   /  |/ / /     / / ___/
  / /___/ /|  / /___  / (__  )
  \____/_/ |_/\____/_/ /____/
                  /___/

  Installing CNCjs
   - https://cnc.js.org
   - https://github.com/cncjs
   
  CNCjs is a full-featured web-based interface for CNC controllers running Grbl, Marlin, Smoothieware, or TinyG.
  For a more complete introduction, see the Introduction section of the wiki page ( \e]8;;https://github.com/cncjs/cncjs/wiki/Introduction\ahttps://github.com/cncjs/cncjs/wiki/Introduction\e]8;;\a ).
  ${COL_GREY}NOTE: This installer logs to syslog. You can view the syslog, with terminal command: tail -f -n 50 /var/log/syslog ${COL_NC}
  ${COL_WHITE}==========================================================================${COL_NC}"
  
  # Log Infomation
  echo "===== Starting CNCjs Install Script =====" >&4

# ----------------------------------------------------------------------------------------------------------------------------------
# -- Menu [ Menu Welcome ]  welcome message
# ----------------------------------------------------------------------------------------------------------------------------------
# https://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
# https://www.bradgillap.com/guide/post/bash-gui-whiptail-menu-tutorial-series-1
# https://gist.github.com/wafsek/b78cb3214787a605a28b

message="This script will install the lastest version of CNCjs w/ NodeJS.
                     https://github.com/cncjs

*THIS INSTALL SCRIPT IS STILL IN BETA, IT MIGHT HAVE ISSUES.*
Please report any issues with this install script to: https://github.com/cncjs/cncjs-pi-raspbian/issues
If any part of this script fails, try reboooting, then re-run this script.

CNCjs is a full-featured web-based interface for CNC controllers running Grbl, Marlin, Smoothieware, or TinyG. Such CNC controllers are often implemented with a tiny embedded computer such as an Arduino with added hardware for controlling stepper motors, spindles, lasers, 3D printing extruders, and the like. The GCode commands that tell the CNC controller what to do are fed to it from a serial port.

        PRESS 'ESC' or 'CTRL + C' TO ABORT INSTALL AT ANY TIME.
        
Press 'ok' to start install of the lastest version of CNCjs w/ NodeJS"
whiptail --msgbox --title "Introduction" "$message" 20 76

# ----------------------------------------------------------------------------------------------------------------------------------
# -- Menu [ Main Check List ]  main installer options for installer
# ----------------------------------------------------------------------------------------------------------------------------------
# https://saveriomiroddi.github.io/Shell-scripting-adventures-part-3/
# https://www.shell-tips.com/bash/arrays/

# Menu Checklist CNCjs Pendants & Widgets
whiptail_title="CNCjs Install Options"

whiptail_message='Install script for CNCjs on Raspberry Pi w/ Raspberry Pi OS\n\nThis install script with get you started quickly with CNCjs on a Raspberry Pi. For a more complete introduction, see the CNCjs Introduction section of the wiki page.\n\nPlease select the best options for your install needs.'

# whiptail_list_entry_options=()	
declare whiptail_list_entry_options=(\
	"A00 System Check" "Preform system check to insure this script is known to be compatable with this OS." "YES" \
	"A01 System Update" "Update System Pacakages." "YES" \
	"A02 Install/Update Node.js & NPM via Package Manager" "Install the required NodeJS Framework and Dependacies." "YES" \
	"A03 Install CNCjs with NPM" "Install CNCjs unsing Node Package Manager." "YES" \
	"A04 Install CNCjs Pendants & Widgets" "(Optional) Install CNCjs Extentions." "YES" \
	"A05 Create CNCjs Service for Autostart" "Setup autostart so CNCjs starts when Raspberry Pi boots." "YES" \
	# "A06 Setup IPtables" "(Optional) Allows to access web ui from 80 to make web access easier." "YES" \
	"A07 Setup Web Kiosk" "(Optional) Setup Chrome Web Kiosk UI to start on boot." "NO" \
	"A08 Install & Setup Streamer" "(Optional) Stream connected camera with mjpg stream to a webpage [uStreamer/MPEG-Streamer]." "NO" \
	"A09 Install & Setup FFmpeg" "(Optional) Record MPEG Streams from MJPG streaming service and save to file." "NO" \
	"A10 Reboot" "(Optional) Reboot after install." "NO" \
	"A12 Remove Old NodeJS & NPM Packages" "(Optional) Remove NodeJS or NPM Packages that might have been install incorrectly." "NO" \
  )

whiptail_list_entry_count=$((${#whiptail_list_entry_options[@]} / 3 ))

# Present Checklist
whiptail_list_selected_descriptions=$(whiptail --checklist --separate-output --title "${whiptail_title}" "${whiptail_message}" 20 164 $whiptail_list_entry_count -- "${whiptail_list_entry_options[@]}" 3>&1 1>&2 2>&3)

main_list_entry_selected=()
mapfile -t main_list_entry_selected <<< "$whiptail_list_selected_descriptions"

# for checklist_selected_name in "${main_list_entry_selected[@]}"; do
# 	echo "Selected Name: ${checklist_selected_name}"
# done

# echo " - - - - - - - - "
# echo ${main_list_entry_selected[*]}
# echo ${!main_list_entry_selected[*]}
# echo ${#main_list_entry_selected[*]}
# echo ${main_list_entry_selected[@]}
# echo ${!main_list_entry_selected[@]}
# echo ${#main_list_entry_selected[@]}
# echo " - - - - - - - - "

# ----------------------------------------------------------------------------------------------------------------------------------
# -- Menu [ CNCjs Addons Check List ]  selection of CNCjs Addons / Extentions / Pendants & Widgets
# ----------------------------------------------------------------------------------------------------------------------------------
if [[ ${main_list_entry_selected[*]} =~ 'A04' ]]; then
	# Menu Checklist CNCjs Pendants & Widgets
	whiptail_title="CNCjs Pendants & Widgets"
	
	whiptail_message='CNCjs Pendants and Widgets entend the funtionality of the platform.\n\nThe user interface is organized as a collection of "widgets", each of which manages a specific aspect of machine control. For example, there are widgets for things like toolpath display, jogging, position reporting, spindle control, and many other functions. Users can control which widgets appear on the screen, omitting ones that do not apply to their machine. There is a way to add custom widgets to support new features. \nExample boilerplate pendant can be found at: https://github.com/cncjs/cncjs-pendant-boilerplate\n\nFinally, there is a collection of "pendants" - specialized user interfaces optimized for simplified control panels such as small LCD screens, wireless keyboards, button panels, and the like. Pendants interact with the cncjs server using subsets of the full set of functions that the main user interface uses.\nExample boilerplate pendant can be found at: https://github.com/cncjs/cncjs-pendant-boilerplate\n\nPlease select the Pendants and Widgets you would like to install:'
	
	declare -A whiptail_list_options=(\
		[Pendant TinyWeb]="https://github.com/cncjs/cncjs-pendant-tinyweb","NO" \
		[Pendant Shopfloor Tablet]="https://github.com/cncjs/cncjs-shopfloor-tablet","YES" \
		[Widget Boilerplate]="https://github.com/cncjs/cncjs-widget-boilerplate","NO" \
		[Kiosk Custom Webpage]="A customizable web page at: ${CNCJS_EXT_DIR}/kiosk/index.html","NO" \
	  )
	
	whiptail_list_entry_options=()
	whiptail_list_entry_count=${#whiptail_list_options[@]}
	
	for entry in "${!whiptail_list_options[@]}"; do
		# echo "TESTING: whiptail_list_options[$entry]}:${whiptail_list_options[$entry]} | entry:$entry | ### $(echo ${whiptail_list_options[$entry]} | cut -d',' -f2)"
		whiptail_list_entry_options+=("$entry")
		whiptail_list_entry_options+=("$(echo ${whiptail_list_options[$entry]} | cut -d',' -f1)  ")
		whiptail_list_entry_options+=($(echo ${whiptail_list_options[$entry]} | cut -d',' -f2))
	done
	
	# Present Checklist
	whiptail_list_selected_descriptions=$(whiptail --checklist --separate-output --title "${whiptail_title}" "${whiptail_message}" 30 90 $whiptail_list_entry_count -- "${whiptail_list_entry_options[@]}" 3>&1 1>&2 2>&3)
	
	addons_list_entry_selected=()
	mapfile -t addons_list_entry_selected <<< "$whiptail_list_selected_descriptions"
	
	# for checklist_selected_name in "${addons_list_entry_selected[@]}"; do
	# 	echo "Selected Name: ${checklist_selected_name}"
	# done
	
	# echo " - - - - - - - - "
	# echo ${addons_list_entry_selected[*]}
	# echo ${!addons_list_entry_selected[*]}
	# echo ${#addons_list_entry_selected[*]}
	# echo ${addons_list_entry_selected[@]}
	# echo ${!addons_list_entry_selected[@]}
	# echo ${#addons_list_entry_selected[@]}
	# echo " - - - - - - - - "
fi


# ----------------------------------------------------------------------------------------------------------------------------------
# -- Menu [ Install & Setup Video Streamer Menu ]  selection of ( MPEG-Streamer | uStreamer )
# ----------------------------------------------------------------------------------------------------------------------------------
if [[ ${main_list_entry_selected[*]} =~ 'A08' ]]; then
	# Menu Checklist CNCjs Pendants & Widgets
	whiptail_title="Video Streamer Options"
	
	whiptail_message='Video Streamer Options.\n\nPlease select which MPEG Streamer you would like to install:'
	
	declare -A whiptail_list_options=(\
		[uStreamer]="Newer lightweight and fast mpeg streamer. | https://github.com/pikvm/ustreamer" \
		[MPEG-Streamer]="legacy mpeg streamer. | https://github.com/jacksonliam/mjpg-streamer" \
	  )
	
	whiptail_list_entry_options=()
	whiptail_list_entry_count=${#whiptail_list_options[@]}
	
	for entry in "${!whiptail_list_options[@]}"; do
		# echo "TESTING: whiptail_list_options[$entry]}:${whiptail_list_options[$entry]} | entry:$entry | ### $(echo ${whiptail_list_options[$entry]} | cut -d',' -f2)"
		whiptail_list_entry_options+=("$entry")
		whiptail_list_entry_options+=("$(echo ${whiptail_list_options[$entry]} | cut -d',' -f1)")
	done
	
	# Present Checklist
	whiptail_list_selected_descriptions=$(whiptail --menu --title "${whiptail_title}" "${whiptail_message}" --default-item "uStreamer" 12 100 $whiptail_list_entry_count -- "${whiptail_list_entry_options[@]}" 3>&1 1>&2 2>&3)
	
	streamer_list_entry_selected=()
	mapfile -t streamer_list_entry_selected <<< "$whiptail_list_selected_descriptions"
fi

# ----------------------------------------------------------------------------------------------------------------------------------
# -- Main [ OS Handling / Checking ]  check if detected operating system is known to be compatable with this script
# ----------------------------------------------------------------------------------------------------------------------------------
detected_os_id=$(cat /etc/*release | grep '^ID=' | cut -d '=' -f2- | tr -d '"')
detected_os_id_version=$(cat /etc/*release | grep '^VERSION_ID=' | cut -d '=' -f2- | tr -d '"')
msg i "Detected HW: $(tr -d '\0' </proc/device-tree/model)"
msg i "Detected OS: [\
  $([[ "$detected_os_id" =~ $COMPATIBLE_OS_ID ]] && echo -e ${PASS}${COL_NC} || echo -e ${FAIL}${COL_NC}) $detected_os_id  |\
  $([[ $detected_os_id_version -ge $COMPATIBLE_OS_ID_VERSION ]] && echo -e ${PASS}${COL_NC} || echo -e ${FAIL}${COL_NC}) $detected_os_id_version  |\
  $(${COMPATIBLE_OS_GUI} && echo -e ${PASS}${COL_NC} 'Compatible GUI' || echo -e ${WARN}${COL_NC} 'No GUI (or) Incompatable GUI')  \
]"

# Log OS Build Info
echo "Raspberry Pi OS Image Version" >&4
cat /boot/issue.txt >&4  # /etc/rpi-issue

# Display OS Build Info
OS_DATE=$(grep -oE "[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}" /boot/issue.txt)
case $(grep -o "stage." /boot/issue.txt) in
  'stage1')
    msg L "Raspberry Pi OS | Bare Bones | $OS_DATE"
    ;;
  'stage2')
    msg L "Raspberry Pi OS | Light | $OS_DATE"
    ;;
  'stage3')
    msg L "Raspberry Pi OS | Post-Light | $OS_DATE"
    ;;
  'stage4')
    msg L "Raspberry Pi OS with desktop | Standard | $OS_DATE"
    ;;
  'stage5')
    msg L "Raspberry Pi OS with desktop and recommended software | Full | $OS_DATE"
    ;;
  *)
    msg L "Unknow OS Build"
    ;;
esac

# Check Compatability
if [[ ${SYSTEM_CHECK} == true ]] && [[ ${main_list_entry_selected[*]} =~ "A00" ]] ; then
	if [[ "$detected_os_id" =~ $COMPATIBLE_OS_ID ]] && [[ $detected_os_id_version -ge $COMPATIBLE_OS_ID_VERSION ]]; then
		msg p "Detected OS is compatable with this install script."
	else
		msg x "Detected OS is NOT compatable with this install script!"
		msg i "This installer is designed for the [Raspberry Pi](https://www.raspberrypi.org) | ${COMPATIBLE_OS_ID} >= v${COMPATIBLE_OS_ID_VERSION}"
		exit 1;
	fi
else
	msg ! "Skipped OS Checking | Variable: SYSTEM_CHECK=${SYSTEM_CHECK} | Menu:$([[ ${main_list_entry_selected[*]} =~ 'A00' ]] && echo 'true' || echo 'false'))"
fi

# ----------------------------------------------------------------------------------------------------------------------------------
# -- Main [ Update System ]  update operating system packages
# ----------------------------------------------------------------------------------------------------------------------------------
if [[ ${main_list_entry_selected[*]} =~ 'A01' ]]; then
	msg % "Updating System Packages" \
		'sudo apt-get update -qq'
	msg % "Upgrading System Packages ${COL_YELLOW}(this can take a while, please wait)${COL_NC}" \
		'sudo apt-get upgrade -qq -y'
	msg % "Upgrading System Distribution ${COL_YELLOW}(this can take a while, please wait)${COL_NC}" \
		'sudo apt-get dist-upgrade -qq -y'
	msg % "Fixing Broken Packages (if any)" \
		'sudo apt-get update --fix-missing -qq -y'
fi

# ----------------------------------------------------------------------------------------------------------------------------------
# -- Main [ Setup Node.js & NPM ]  via Package Manager
# ----------------------------------------------------------------------------------------------------------------------------------
if [[ ${main_list_entry_selected[*]} =~ 'A12' ]] || [[ ${main_list_entry_selected[*]} =~ 'A02' ]]; then
	msg h "Setup Node.js & NPM via Package Manager"
	
	# Remove Old NodeJS or NPM Packages (Optional)
	if [[ ${main_list_entry_selected[*]} =~ 'A12' ]]; then
		msg % "Removing any Old NodeJS or NPM Packages" \
			'sudo apt-get purge -y npm nodejs'
		msg % "Removing Un-needed Packages" \
			'sudo apt-get -y autoremove'
	fi
	
	# Install/Update Node.js & NPM via Package Manager
	if [[ ${main_list_entry_selected[*]} =~ 'A02' ]]; then
	
		# Raspbian / Debian Spasific Install
		if [[ "$detected_os_id" == 'raspbian' ]] && [[ $detected_os_id_version -le 10 ]]; then
			# Raspbian 10 (and older)
			# https://github.com/nodesource/distributions#rpminstall
			msg % "Installing Node.js v10.x Package Source" \
				'curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -'
			msg % "Installing Node.js via Package Manager" \
				'sudo apt-get install -qq -y nodejs'
		else
			# Debain
			msg % "Installing Node.js & NPM via Package Manager" \
				'sudo apt-get install -qq -y nodejs npm'
		fi

		msg % "Installing Build Essential" \
			'sudo apt-get install -qq -y -f build-essential gcc g++ make'
		# msg % "Installing Latest Node Package Manager (NPM)" \
		# 	'sudo npm install -g npm@latest'
	fi
else
	msg h "Node.js & NPM Information"
fi

# ----------------------------------------------------------------------------------------------------------------------------------
# -- Output [ NodeJS & NPM Version ]  output installed versions info
# ----------------------------------------------------------------------------------------------------------------------------------
if [[ -x $(which node) ]]; then
	msg i "NodeJS: \t$(node -v) \t|\t $(which node)"
else
	msg i "NodeJS: \tNot Installed"
fi

if [[ -x $(which npm) ]]; then
	msg i "NPM: \tv$(npm -v) \t|\t $(which npm)"
else
	msg i "NPM: \tNot Installed"
fi

# ----------------------------------------------------------------------------------------------------------------------------------
# -- Main [ Install CNCjs ]  w/ NPM
# ----------------------------------------------------------------------------------------------------------------------------------
if [[ ${main_list_entry_selected[*]} =~ 'A03' ]]; then
	msg h "Install CNCjs"
	
	# Get Installed Version of CNCjs
	if [[ $(command -v cncjs) ]]; then
		CNCJS_VERSION_INSTALLED=$(npm view cncjs version)  # cncjs --version
	else
		CNCJS_VERSION_INSTALLED=0
	fi
	
	# Menu Checklist CNCjs Pendants & Widgets
	whiptail_title="CNCjs Version Selection"
	
	whiptail_message='Select the version of CNCjs to install.\nIf not sure, leave on latest version'
	
	CNCJS_VERSIONS_JSON="$(npm view cncjs versions --json)"
	# readarray -t CNCJS_VERSIONS < <(jq -r '.[]' <<<"$json")  # sudo apt-get install jq
	readarray -t CNCJS_VERSIONS < <((grep '"'| cut -d '"' -f2) <<<"${CNCJS_VERSIONS_JSON}")  
	declare -p CNCJS_VERSIONS  >/dev/null 2>&1
	
	whiptail_list_entry_options=()
	whiptail_list_entry_count=${#whiptail_whiptail_list_entry_options[@]}
	
	# First Option (On)
	whiptail_list_entry_options+=("${CNCJS_VERSIONS[${whiptail_list_entry_count} -1]}")
	# Tag Installed Version
	if [[ "$CNCJS_VERSION_INSTALLED" == "${CNCJS_VERSIONS[${whiptail_list_entry_count} -1]}" ]]; then
		whiptail_list_entry_options+=("Latest Version  * Installed * ")
	else
		whiptail_list_entry_options+=("Latest Version ")
	fi
	
	# Proccess and Flip Array (so newest at top)
	# for entry in "${!CNCJS_VERSIONS[@]}"; do
	for entry in $(seq $((${#CNCJS_VERSIONS[@]} - 2)) -1 0); do
		whiptail_list_entry_options+=("${CNCJS_VERSIONS[$entry]}")
		
		# Tag Installed Version
		if [[ "$CNCJS_VERSION_INSTALLED" == "${CNCJS_VERSIONS[$entry]}" ]]; then
			whiptail_list_entry_options+=("* Installed * ")
		else
			whiptail_list_entry_options+=(" ")
		fi
	done
	
	cncjs_version_install=$(whiptail --menu --title "${whiptail_title}" "${whiptail_message}" 30 62 20 "${whiptail_list_entry_options[@]}" 3>&1 1>&2 2>&3)
	
    #msg % "Install CNCjs with NPM" 'sudo npm install -g cncjs@latest --unsafe-perm'
	msg % "Installing CNCjs (v${cncjs_version_install}) with NPM" \
		"sudo npm install -g cncjs@${cncjs_version_install} --unsafe-perm"
	
	# User TTY Permissions
	# https://www.raspberrypi.org/forums/viewtopic.php?t=171843
	msg % "Set User TTY Permissions" \
		"sudo usermod -a -G tty ${USER}"
fi

# ----------------------------------------------------------------------------------------------------------------------------------
# -- Main [ Download & Install CNCjs Pendants & Widgets ]  get some of the CNCjs extentions
# ----------------------------------------------------------------------------------------------------------------------------------
if [[ -n ${addons_list_entry_selected} ]]; then 
	msg h "Download & Install CNCjs Pendants & Widgets\t[ ${CNCJS_EXT_DIR} ]"
fi 

# Create Needed Directories
if [[ ${main_list_entry_selected[*]} =~ 'A03' ]] || [[ ${main_list_entry_selected[*]} =~ 'A04' ]] || [[ ${main_list_entry_selected[*]} =~ 'A05' ]] || [[ ${main_list_entry_selected[*]} =~ 'A08' ]]; then
msg % "Creating CNCjs Directory for Addons / Extentions / Logs / Watch\t( ${CNCJS_EXT_DIR} )" \
	"mkdir -p ${CNCJS_EXT_DIR}/watch"
fi

# Addons
if [[ -n ${addons_list_entry_selected} ]]; then 	

	# Addon: Pendant TinyWeb
	if [[ ${addons_list_entry_selected[*]} =~ 'Pendant TinyWeb' ]]; then
		name="Pendant TinyWeb"
		url="https://codeload.github.com/cncjs/cncjs-pendant-tinyweb"
		dir="${CNCJS_EXT_DIR}/pendant-tinyweb"
		sub="tinyweb"
		cncjs_flags+=" --mount /${sub}:${dir}/src"
		url+="/legacy.tar.gz/latest"
		msg % "Download & Install: $name\t\t( http://${HOST_IP}/${sub} )\t[ ${dir} ]" \
			"mkdir -p ${dir}; curl -sS ${url} | tar -xvzf - -C ${dir} --strip 1"
	fi
	
	# Addon: Pendant Shopfloor Tablet
	if [[ ${addons_list_entry_selected[*]} =~ 'Pendant Shopfloor Tablet' ]]; then
		name="Pendant Shopfloor Tablet"
		url="https://codeload.github.com/cncjs/cncjs-shopfloor-tablet"
		dir="${CNCJS_EXT_DIR}/pendant-shopfloor-tablet"
		sub="tablet"
		cncjs_flags+=" --mount /${sub}:${dir}/src"
		url+="/legacy.tar.gz/latest"
		msg % "Download & Install: $name\t( http://${HOST_IP}/${sub} )\t\t[ ${dir} ]" \
			"mkdir -p ${dir}; curl -sS ${url} | tar -xvzf - -C ${dir} --strip 1"
	fi
	
	# Addon: Widget Boilerplate
	if [[ ${addons_list_entry_selected[*]} =~ 'Widget Boilerplate' ]]; then
		name="Widget Boilerplate"
		url="https://cncjs.github.io/cncjs-widget-boilerplate/v2/"
		sub="widget-boilerplate"
		cncjs_flags+=" --mount /${sub}:${url}"
		msg p "Setup: $name\t\t\t( http://${HOST_IP}/${sub} )\t( ${url} )"
	fi

	# Addon: Kiosk Custom Webpage
	if [[ ${addons_list_entry_selected[*]} =~ 'Kiosk Custom Webpage' ]]; then
		name="Kiosk Custom Webpage"
		dir="${CNCJS_EXT_DIR}/kiosk"
		sub="kiosk"
		cncjs_flags+=" --mount /${sub}:${dir}"
		msg % "Setup: $name\t( http://${HOST_IP}/${sub} )\t\t[ ${dir} ]" \
			"mkdir -p ${dir}; cat > \"${dir}/index.html\" << EOF
<!DOCTYPE html>
<html>

<head>
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
    <style>
        html {
            overflow: hidden;
        }

        body,
        html {
            height: 100%;
            margin: 0;
        }

        .bg {
            /* The image used */
            background-image: url(\"http://localhost:8080/?action=stream\");

            /* Full height */
            height: 100%;

            /* Center and scale the image nicely */
            background-position: center;
            background-repeat: no-repeat;
            background-size: cover;
        }
    </style>
</head>

<body>
    <div class=\"bg\"></div>
    <p>This example creates a full page background image. Try to resize the browser window to see how it always will
        cover the full screen (when scrolled to top), and that it scales nicely on all screen sizes.</p>
</body>
EOF"
	fi
fi


# ----------------------------------------------------------------------------------------------------------------------------------
# -- Main [ Autostart Autostart Service ]  start CNCjs on bootup w/ Systemd
# ----------------------------------------------------------------------------------------------------------------------------------
if [[ ${main_list_entry_selected[*]} =~ 'A05' ]]; then
	msg h "Create CNCjs Service for Autostart"

	# Load Setting if File Exists
	if [[ -f "/etc/systemd/system/cncjs.service" ]]; then
	    # CNCJS_PORT=$(get_config_var KIOSK_URL "/etc/systemd/system/cncjs.service")
		CNCJS_PORT=$(sed -n "/^#/! s|.*--port \([[:digit:]]\+\).*|\1|p" "/etc/systemd/system/cncjs.service") 
	# else
	# 	CNCJS_PORT=80  # Defined in header
	fi

	# Service
	msg i "Creating CNCjs Service w/ Systemd"
	# - - - - - - - - - - - - - - - - - - - - - - - - - - -
	cat << EOF | sudo tee "/etc/systemd/system/cncjs.service" >/dev/null 2>&1
[Unit]
Description=CNCjs is a full-featured web-based interface for CNC controllers running Grbl, Marlin, Smoothieware, or TinyG.
Documentation=https://github.com/cncjs/cncjs
After=syslog.target
After=network.target
Wants=network.target


[Service]
Type=simple
AmbientCapabilities=CAP_NET_BIND_SERVICE

# Restart service after x seconds if node service crashes
Restart=on-failure
RestartSec=5s

# # User & Group
User=${USER}
# Group=user
WorkingDirectory=${HOME}

# Capabilities & Security Settings
CapabilityBoundingSet=CAP_SYS_ADMIN CAP_NET_BIND_SERVICE  # Commment this out if you want CNCjs to be able to run "sudo" commands.
# ProtectHome=true
ProtectSystem=full

# Output to syslog
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=cncjs

# = Start Process =
Environment="NODE_ENV=production"
# CNCjs Parameters
$(cncjs --help | grep .  | sed '1d;$d' | sed 's/^/#/')
# cncjs --help
ExecStart=$(which cncjs) --port 80 --config \"${CNCJS_EXT_DIR}/.cncrc\" --watch-directory \"${HOME}/Documents\"

# = Alternative Method = (EnvironmentFile)
#EnvironmentFile=-/etc/cncjs.d/default.conf
#ExecStart=$(which cncjs) \${OPTIONS}

[Install]
WantedBy=multi-user.target
EOF
	
	# -----------------------------------------------------

	# Update the CNCjs Port
	KIOSK_URL="$(whiptail --inputbox --title 'CNCjs Web UI Port' 'Port to use for CNCjs Web UI (default: 80 | 8000)' 8 39 "${CNCJS_PORT}" 3>&1 1>&2 2>&3)"
	msg % "Editing CNCjs Service Start Port" \
		"sudo sed -i \"/^#/! s|--port [[:digit:]]\+|--port ${CNCJS_PORT}|\" \"/etc/systemd/system/cncjs.service\" "

	# -----------------------------------------------------
	
	# Service Settings
	msg i "Creating CNCjs Service Settings File (Optional)"
	# --------------------------
	sudo mkdir -p "/etc/cncjs.d/" >&4 2>&1
	cat << EOF | sudo tee "/etc/cncjs.d/default.conf" >/dev/null 2>&1
# CNCjs Settings
# https://github.com/cncjs/cncjs

$(cncjs --help | grep .  | sed '1d;$d' | sed 's/^/#/')
# cncjs --help
OPTIONS="--port ${CNCJS_PORT}"

EOF
	
	# -----------------------------------------------------
	
	# Edit Service File w/ Changes
	msg % "Editing CNCjs Service Start Options: OPTIONS HERE" \
		"sudo sed -i \"s|ExecStart=.*|ExecStart=$(which cncjs) ${cncjs_flags}|\" \"/etc/systemd/system/cncjs.service\" "
	
	# Outputing Instance Infomation
	msg - "Service Settings: /etc/systemd/system/cncjs.service" \
		"$(grep "^ExecStart=" "/etc/systemd/system/cncjs.service")
		\n    Note: These settings can be changed with command: sudo systemctl edit --full cncjs\n      Check CNCjs Server Status with: sudo service cncjs status"
	
	# Reload Services
	msg % "Reloading Service Deamon" \
		"sudo systemctl daemon-reload"
	
	# Instance Start
	msg % "Starting Service" \
		"sudo systemctl restart cncjs"
		
	# Instance Enable
	msg % "Enabling Service" \
		"sudo systemctl enable cncjs"

	# Instance Status
	msg - "Status of Service" \
		"$(sudo systemctl status cncjs)"

	# Instance URL Infomation
	msg i "CNCjs is now started and can be accessed at: ( \e]8;;http://localhost:${CNCJS_PORT}\ahttp://localhost:${CNCJS_PORT}\e]8;;\a ) | ( \e]8;;http://${HOST_IP}:${CNCJS_PORT}\ahttp://${HOST_IP}:${CNCJS_PORT}\e]8;;\a )"
	
fi


# # ----------------------------------------------------------------------------------------------------------------------------------
# # -- Main [ Setup IPtables ]  allow access to port 8000 from port 80
# # ----------------------------------------------------------------------------------------------------------------------------------
# if [[ ${main_list_entry_selected[*]} =~ 'A06' ]]; then
# 	msg h "Setup IPtables"

# 	# Install IPtables & any other related packages
# 	msg % "Install Iptables" \
# 		'sudo apt-get install -qq -y -f iptables'
	
# 	# Setup IPtables Rule
# 	msg % "Setup IPtables (allow access to port 8000 from port 80)" \
# 		'sudo iptables -t nat -I PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8000'
	
# 	# Detect if IPtables Rule(s) Fail to Set, if so try after reboot
# 	if [[ $? -ne 0 ]]; then
# 		msg ! "IPtables Setup Failed, running commands after reboot to fix"

# 		# Create Crontab Job to Run at Next Boot, then remove its self
# 		msg L "Creating crontab job to run after next reboot, then will remove itself"
# 		cronjob='@reboot sudo iptables -t nat -I PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8000; sudo netfilter-persistent save; sudo netfilter-persistent reload; sudo bash -c "iptables-save > /etc/iptables/rules.v4"; sudo bash -c "ip6tables-save > /etc/iptables/rules.v6"; touch /home/pi/test01.txt; sudo crontab -u root -l | grep -v "@reboot sudo iptables" | sudo crontab -u root -'
# 		# (sudo crontab -u root -l; echo "${cronjob}" ) | sudo crontab -u root -
# 		((sudo crontab -u root -l | grep -v '@reboot sudo iptables'); echo "${cronjob}" ) | sudo crontab -u root - >&4 2>&1

# 		# Remove Crontab Job
# 		# sudo crontab -u root -l | grep -v '@reboot sudo iptables' | sudo crontab -u root -

# 		# Show Crontab Job
# 		msg - "$(sudo crontab -u root -l)"
# 	fi

# 	# Make Iptables Persistent (silent install)
# 	echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
# 	echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
# 	msg % "Making Iptables Persistent" \
# 		'sudo apt-get install -qq -y -f iptables-persistent'

# 	# How-to: Save & Reload Rules
# 	#sudo netfilter-persistent save
# 	#sudo netfilter-persistent reload
	
# 	# How-to: Manually Save Rules
# 	#sudo sh -c "iptables-save > /etc/iptables/rules.v4"
# 	#sudo sh -c "ip6tables-save > /etc/iptables/rules.v6"
	
# 	# Run this if issues to reconfigure iptables-persistent
# 	# sudo dpkg-reconfigure iptables-persistent
# fi

# ----------------------------------------------------------------------------------------------------------------------------------
# -- Main [ Setup Web Kiosk ]  setup web kiosk for Rasp OS, and Rasp OS Slim
# ----------------------------------------------------------------------------------------------------------------------------------
if [[ ${main_list_entry_selected[*]} =~ 'A07' ]]; then
	msg h "Setup Web Kiosk"
	
	# =============================================
	if [[ -x $(which lightdm) ]]; then
		# Output LXDE Setup w/ Directory Path
		msg i "Configuring LXDE to start Web Kiosk on Startup"
		mkdir -p "${HOME}/.config/lxsession/LXDE-pi"
		# --------------------------------------------
cat > "${HOME}/.config/lxsession/LXDE-pi/autostart" << EOF
@lxpanel --profile LXDE-pi
@pcmanfm --desktop --profile LXDE-pi
${CNCJS_EXT_DIR}/cncjs-kiosk.sh
EOF
		# --------------------------------------------

		# Set Kiosk User Varible
		KIOSK_USER=$USER
		
		# Setup Autologin (GUI) on Raspberry Pi
		msg i "Enabling Autologin (GUI)"
		if [ -e /etc/init.d/lightdm ]; then
			sudo systemctl set-default graphical.target
			sudo ln -fs /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@tty1.service
sudo sh -c "cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $KIOSK_USER --noclear %I \$TERM
EOF"
			sudo sed /etc/lightdm/lightdm.conf -i -e "s/^\(#\|\)autologin-user=.*/autologin-user=$KIOSK_USER/"
		else
			whiptail --msgbox "lightdm auto login setup error" 20 60 2
			return 1
		fi
	# =============================================
	elif [[ ${COMPATIBLE_OS_GUI} == false ]] || [[ -x $(which openbox) ]]; then
		msg i "Raspberry PI GUI (lxde) NOT Detected. Raspberry Pi OS (Slim)?"
		
		# Minimum Environment for GUI Applications | bare minimum needed for X server & window manager
		msg % "Installing OpenBox GUI" \
			"sudo apt-get install -y --no-install-recommends xserver-xorg xserver-xorg-legacy x11-xserver-utils xinit openbox zenity"
		
		# Web Browser | Chromium has a nice kiosk mode
		msg % "Chromium Web Browser (for Kiosk Mode)" \
			"sudo apt-get install -y --no-install-recommends chromium-browser"
		###sudo apt-get install -y --no-install-recommends chromium-browser rpi-chromium-mods  # (Optional)
		
		# Output Openbox Setup w/ Directory Path
		msg i "Configuring Openbox to start Web Kiosk on Startup"
		mkdir -p "${HOME}/.config/openbox/"
		# --------------------------------------------
cat > "${HOME}/.config/openbox/autostart" << EOF
${CNCJS_EXT_DIR}/cncjs-kiosk.sh
EOF
		# --------------------------------------------
		
		# openbox-session start automatically on load
		msg i "Setting Openbox UI to start on login"
		# --------------------------------------------
cat > "${HOME}/.xinitrc" << "EOF"
exec openbox-session
EOF
		# --------------------------------------------
		
		# Start X automatically on boot
		msg i "Setting StartX to start UI on login"
		# --------------------------------------------
cat >> "${HOME}/.bashrc" << "EOF"
# Start Web Kiosk
[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && startx -- -nocursor
EOF
		# --------------------------------------------
	
		# Setup Autologin (Console > GUI) on Raspberry Pi
		msg i "Enabling Autologin (Console > GUI)"
		sudo systemctl set-default multi-user.target
		sudo ln -fs /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@tty1.service
		# --------------------------------------------
cat << EOF | sudo tee "/etc/systemd/system/getty@tty1.service.d/autologin.conf" >/dev/null 2>&1
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER --noclear %I \$TERM
EOF
		# --------------------------------------------
	fi
	# =============================================
	
	
	# Load Setting if File Exists
	if [[ -f "${CNCJS_EXT_DIR}/cncjs-kiosk.sh" ]]; then
	    KIOSK_URL=$(get_config_var KIOSK_URL "${CNCJS_EXT_DIR}/cncjs-kiosk.sh")
		KIOSK_URL=${parameter:=http://localhost:${CNCJS_PORT}}  # Fix if varable blank
	else
		KIOSK_URL=http://localhost:${CNCJS_PORT}
	fi

# Output Chrome Kiosk Script
# --------------------------------------------
cat > "${CNCJS_EXT_DIR}/cncjs-kiosk.sh" << 'EOF'
#!/bin/bash

# Set Display
#export DISPLAY=:0

# URL to open in Chrome Kiosk
KIOSK_URL=http://localhost:80

# Prevent the screen from turning off
#xscreensaver -no-splash  # comment this line out to disable screensaver
xset -dpms     # Disable DPMS (Energy Star) features
xset s off     # Disable screensaver
xset s noblank # Don't blank video device

# Allow quitting the X server with CTRL-ATL-Backspace
setxkbmap -option terminate:ctrl_alt_bksp

# Show the user why it is taking so long
zenity --info --no-wrap --timeout 240 --width=300 --height=100 --text="Waiting for CNCjs server to start\nStart Chrome now to avoid opening in Kiosk Mode\nPress (Ctrl+Alt+S) to Exit Chrome Kiosk\nPress (Ctrl+Alt+Backspace) to Exit UI" & ZENITY_PID=$!

# Detect if running Raspberry Pi UI
if [[ -x $(which lightdm) ]]; then
	# Sleep for 30 sec just in-case users need to make changes in normal GUI lightdm
	sleep 30
fi

# Wait until the CNCjs server becomes responsive before starting the browser
until $(curl --output /dev/null --silent --head --fail "${KIOSK_URL}"); do
  sleep 3
done

# Close Zenity Window
kill $ZENITY_PID

# Reset Chrome Cleanly Exited State
sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' ~/.config/chromium/'Local State'
sed -i 's/"exited_cleanly":false/"exited_cleanly":true/; s/"exit_type":"[^"]\+"/"exit_type":"Normal"/' ~/.config/chromium/Default/Preferences

# Finally, start the browser, pointing to the CNCjs server
# --kiosk makes the browser occupy the entire screen.
# If you want to kill the full-screen browser, use ALT-F4
# If you omit --kiosk, the browser will start in a normal window
chromium-browser  --incognito --kiosk --noerrdialogs --disable-cache --disk-cache-dir=/dev/null --disk-cache-size=1 --disable-suggestions-service --disable-translate --disable-save-password-bubble --disable-session-crashed-bubble --disable-infobars --touch-events=enabled --no-touch-pinch --disable-gesture-typing "${KIOSK_URL}"
EOF
	# --------------------------------------------

	# Update the Kiosk URL in the Chrome Kiosk Script
	###KIOSK_URL=$(get_config_var KIOSK_URL "${CNCJS_EXT_DIR}/cncjs-kiosk.sh")
	KIOSK_URL="$(whiptail --inputbox --title 'Web Kiosk URL' 'URL to open in Chrome Kiosk\nRecommended: (CNCjs "http://localhost:'${CNCJS_PORT}'") | (Camera#1 "http://localhost:8080")\n                           (Kiosk http://localhost/kiosk/)' 10 84 "${KIOSK_URL}" 3>&1 1>&2 2>&3)"
	set_config_var KIOSK_URL "${KIOSK_URL}" "${CNCJS_EXT_DIR}/cncjs-kiosk.sh"
	
	# Set Chrome Kiosk Script as Executable
	sudo chmod a+x "${CNCJS_EXT_DIR}/cncjs-kiosk.sh"
fi


# ----------------------------------------------------------------------------------------------------------------------------------
# -- Main [ Install ustreamer & Tools ]  w/ package manager
# ----------------------------------------------------------------------------------------------------------------------------------
if [[ ${main_list_entry_selected[*]} =~ 'A08' ]]; then
	
	# Note to users regarding camera hardware issues.
	msg i "NOTE: If you happen to experience camera issues, try reducing frame rate and/or resolution. https://github.com/pikvm/ustreamer/issues/14#issuecomment-583172852"
	
	# uStreamer --------------------------------------------------------------------------------------------------------------------
	if [[ ${streamer_list_entry_selected[*]} =~ 'uStreamer' ]]; then
		msg h "uStreamer Setup"
		
		# Raspbian / Debian Spasific Install
		if [[ "$detected_os_id" == 'raspbian' ]] && [[ $detected_os_id_version -le 10 ]]; then
			# Raspbian 10 (and older)
			msg % "Installing Build Tools & Dependencies (Raspbian)" \
				'sudo apt-get install -qq -y build-essential libevent-dev libjpeg8-dev libbsd-dev libv4l-dev cmake git'
		else
			# Debain
			msg % "Installing Build Tools & Dependencies (Raspbian)" \
				'sudo apt-get install -qq -y build-essential libevent-dev libjpeg-dev libbsd-dev libv4l-dev cmake git'
		fi
		msg % "Building & Installing Latest µStreamer from GIT Repository" \
			'cd /tmp; git clone --depth=1 https://github.com/pikvm/ustreamer; cd ustreamer; make; sudo make install'
		
		# Create System Account for ustreamer process
		SERVICE_ACCOUNT=ustreamer
		msg % "Creating System Account (${SERVICE_ACCOUNT}) for ustreamer process" \
			"[ ! $(getent passwd ${SERVICE_ACCOUNT}) ] && sudo useradd --system ${SERVICE_ACCOUNT} || echo 'User Already Exist'"
		msg % "Adding System Account (${SERVICE_ACCOUNT}) to (video) group" \
			"[ ! $(user=${SERVICE_ACCOUNT}; group=video; getent group ${group} | grep "\b${user}\b") ] && sudo usermod --append --group video ${SERVICE_ACCOUNT} || echo 'User Already Member of Group'"
		msg %% "Granting System Account (${SERVICE_ACCOUNT}) access to video devices" \
			"sudo usermod -a -G video ${SERVICE_ACCOUNT}"

		# -----------------------------------------------------

		# Main Service
		msg i "Creating uStreamerService"
		# - - - - - - - - - - - - - - - - - - - - - - - - - - -
		cat << EOF | sudo tee "/lib/systemd/system/ustreamer.service" >/dev/null 2>&1
[Unit]
Description=uStreamer Service | µStreamer is a lightweight and very quick server to stream MJPG video from any V4L2 device to the net. All new browsers have native support of this video format, as well as most video players such as mplayer, VLC etc. µStreamer is a part of the Pi-KVM project designed to stream VGA and HDMI screencast hardware data with the highest resolution and FPS possible.
Documentation=https://github.com/pikvm/ustreamer
After=syslog.target
After=network.target
Wants=network.target


[Service]
Type=simple

# Process Priority
Nice=+10

# Restart service after x seconds if node service crashes
Restart=always
RestartSec=5

# User & Group
User=ustreamer
Group=video

# Capabilities & Security Settings
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
ProtectHome=true
ProtectSystem=full

# Output to syslog
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=uStreamer

# uStreamer Info
$(ustreamer --help | grep .  | sed '1d;$d' | sed 's/^/# /')
# ustreamer --help"

# = Start Process =
ExecStart=/usr/local/bin/ustreamer --device=/dev/video0 --host=0.0.0.0 --port=8080 --quality 80 --resolution 640x480 --format=MJPEG --desired-fps=15


[Install]
WantedBy=multi-user.target
EOF

		# -----------------------------------------------------

		# Create Template Service
		msg i "Creating uStreamer Service Template"
		# - - - - - - - - - - - - - - - - - - - - - - - - - - -
		cat << EOF | sudo tee "/lib/systemd/system/ustreamer@.service" >/dev/null 2>&1
[Unit]
Description="uStreamer Service Instance: %I | Default Device: /dev/video%i | Default Port: 808%i"
Documentation=https://github.com/pikvm/ustreamer
After=syslog.target
After=network.target
Wants=network.target


[Service]
Type=simple

# Process Priority
Nice=+10

# Restart service after x seconds if node service crashes
Restart=always
RestartSec=5

# User & Group
User=ustreamer
Group=video

# Capabilities & Security Settings
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
ProtectHome=true
ProtectSystem=full

# Output to syslog
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=uStreamer

# uStreamer Info
$(ustreamer --help | grep .  | sed '1d;$d' | sed 's/^/# /')
# ustreamer --help"

# = Start Process =
Environment="SCRIPT_ARGS=%I"
ExecStart=/usr/local/bin/ustreamer --process-name-prefix ustreamer-%I --host=0.0.0.0 --port=808%I --quality 80 --device=/dev/video%I --resolution 640x480 --desired-fps=15

[Install]
WantedBy=multi-user.target
EOF

		# -----------------------------------------------------
		
		# Reload Services
		msg % "Reloading Service Deamon" \
			"sudo systemctl daemon-reload"
		
		# =====================================================
		
		# Check if Camera's Avalible 
		if [[ -e "/dev/video0" ]]; then
			
			# Menu uStreamer Setup
			whiptail_title="uStreamer Camera Options"
			whiptail_message="µStreamer is a lightweight and very quick server to stream MJPG video from any V4L2 device to the net. All new browsers have native support of this video format, as well as most video players such as mplayer, VLC etc. µStreamer is a part of the Pi-KVM project designed to stream VGA and HDMI screencast hardware data with the highest resolution and FPS possible.\n\nStream JPEG files over an IP-based network from a webcam to various types of viewers such as Chrome, Firefox, Cambozola, VLC, mplayer, and other software capable of receiving MJPG streams\n\nWould you like MJPG Stream setup for any one camera you plug in. This makes using a camera very easy. Just plug any camera in and it will work.\n\nAlternatively, if you plan to plugin muluple camera's at once and want seperate streams for each camera. This script can setup seperate streams where each stream has a camera assisgend to it by device ID. This way the streams do not change on reboot.\nHowever, new cameras will require changing ID. You can do that by just reruning this script."
			
			whiptail_menu_entry_selected=$(whiptail --menu --backtitle "${SCRIPT_TITLE_FULL}  |  To ABORT at anytime, press 'ESC' or 'CTRL + C'" --nocancel --ok-button "Setup Camera(s)" --title "${whiptail_title}" "${whiptail_message}" 24 78 2 \
				"Single Camera" "  Setup uStreamer for a single camera on /dev/video0" \
				"Multiple Cameras" "  Setup uStreamer cameras based on /dev/v4l/by-id/*" 3>&1 1>&2 2>&3)
			
			
			# uStreamer Single/Multi Camera Setup
			if [[ ${whiptail_menu_entry_selected[*]} =~ 'Multiple' ]]; then
				msg h "uStreamer Multi Camera Setup"
				
				# Menu Checklist uStreamer Camera(s)
				whiptail_list_entry_options=()
				whiptail_title="uStreamer Camera(s)"
				whiptail_message='Seletect cameras to be configured.'
				
				# Entry Options by ID (so they can be mapped to a particular port)
				for dev in $(ls -1 /dev/v4l/by-id/ | grep index0); do
					whiptail_list_entry_options+=("$dev")
					whiptail_list_entry_options+=("Device by ID")
					whiptail_list_entry_options+=("ON")
				done
				
				# Present Checklist
				whiptail_list_entry_count=$((${#whiptail_list_entry_options[@]} / 3 ))
				whiptail_list_entry_selected=$(whiptail --checklist --separate-output --title "${whiptail_title}" "${whiptail_message}" 20 150 $whiptail_list_entry_count -- "${whiptail_list_entry_options[@]}" 3>&1 1>&2 2>&3)
				
			else # [[ ${whiptail_menu_entry_selected[*]} =~ 'Single' ]]; then
				msg h "uStreamer Single Camera Setup"
				whiptail_list_entry_selected+=("/dev/video0")
			fi
		else 
			msg ! "No Camera Detected, setting up for single camera operation."
			msg h "uStreamer Single Camera Setup"
			whiptail_list_entry_selected+=("/dev/video0")
		fi
			
		# Process Selections
		i=0  # Instance Counter
		mapfile -t list_entry_selected <<< "${whiptail_list_entry_selected}"
		for entry_selected in "${list_entry_selected[@]}"; do
			
			# Add Path to Camera Devices based on selection
			if [[ ${whiptail_menu_entry_selected[*]} =~ 'Multiple' ]]; then
				# Multiple Device by ID
				camera_device="/dev/v4l/by-id/${entry_selected}"
			else 
				# Single Device by ID
				camera_device="${list_entry_selected}"
			fi
			
			# Detect if camera exist, then promt for customisations
			if [[ -e "${camera_device}" ]]; then
				
				# Camera Resolution Get Options
				whiptail_list_entry_resolution=()
				for entry in $(v4l2-ctl --list-formats-ext --device "${camera_device}" | grep -oP "[[:digit:]]+x[[:digit:]]+" | sort -nr | uniq); do
					whiptail_list_entry_resolution+=("$entry"  "Resolution")
				done
				
				# Camera Resolution Menu
				camera_resolution=$(whiptail --menu --title "uStreamer Camera(s) Resolution" \
				"Select Camera Resolution for Camera: \n${camera_device}\n\nThe lower the resolution the less proccessing power required. Lower resolutions are recommeneded." \
				--nocancel --ok-button "Apply" \
				--backtitle "${SCRIPT_TITLE_FULL}  |  To ABORT at anytime, press 'ESC' or 'CTRL + C'" \
				18 84 6 \
				"${whiptail_list_entry_resolution[@]}" 3>&1 1>&2 2>&3)
				
				# Camera FPS Get Options
				whiptail_list_entry_fps=()
				for entry in $(v4l2-ctl --list-formats-ext --device "${camera_device}" | grep -oP '\(\K(\d+)(?=.*fps)' | sort -n | uniq); do
					whiptail_list_entry_fps+=("$entry"  "FPS")
				done
				
				# Camera FPS Menu
				camera_fps=$(whiptail --menu --title "uStreamer Camera(s) FPS" \
				"Select Camera Frame Per Second (FPS) for Camera: \n${camera_device}\n\nThe lower the FPS the less proccessing power required. Lower FPS are recommeneded." \
				--nocancel --ok-button "Apply" \
				--backtitle "${SCRIPT_TITLE_FULL}  |  To ABORT at anytime, press 'ESC' or 'CTRL + C'" \
				18 84 6 \
				"${whiptail_list_entry_fps[@]}" 3>&1 1>&2 2>&3)
				
				# Copy Instance from Template to /etc to take priorty over template, then make needed changes to service file.
				msg i "uStreamer Service Instance: ustreamer@${i} | ${list_entry_selected}"
				msg % "Creating uStreamer Service Instance: ustreamer@${i}" \
					"sudo cp --update \"/lib/systemd/system/ustreamer@.service\" \"/etc/systemd/system/ustreamer@${i}.service\";
					sudo sed -i '/^ExecStart/{s|--device=[a-zA-Z0-9_\-\%\\/\]*|--device=${camera_device}|}' \"/etc/systemd/system/ustreamer@${i}.service\";
					sudo sed -i '/^ExecStart/{s|--desired-fps=\\w*|--desired-fps=${camera_fps}|}' \"/etc/systemd/system/ustreamer@${i}.service\";
					sudo sed -i '/^ExecStart/{s|--resolution\\s\+\\w*|--resolution ${camera_resolution}|}' \"/etc/systemd/system/ustreamer@${i}.service\" "
			else 
				msg ! "Camera NOT Detected, default settings will be used for camera: ${camera_device}"
				
				# Copy Instance from Template to /etc to take priorty over template, then make needed changes to service file.
				msg i "uStreamer Service Instance: ustreamer@${i} | ${list_entry_selected}"
				msg % "Creating uStreamer Service Instance: ustreamer@${i}" \
					"sudo cp --update \"/lib/systemd/system/ustreamer@.service\" \"/etc/systemd/system/ustreamer@${i}.service\" "
			fi
			
			# Outputing Instance Infomation
			msg - "Service Instance Settings: ustreamer@${i} | /etc/systemd/system/ustreamer@${i}.service" \
				"$(grep "^ExecStart=" "/etc/systemd/system/ustreamer@${i}.service")
				\n    Note: These settings can be changed with command: sudo systemctl edit --full ustreamer@${i}"
			
			# Reload Services
			msg % "Reloading Service Deamon" \
				"sudo systemctl daemon-reload"
			
			# Instance Start
			msg % "Starting Service Instance Settings: ustreamer@${i}" \
				"sudo systemctl restart ustreamer@${i}"
				
			# Instance Start
			msg % "Enabling Service Instance Settings: ustreamer@${i}" \
				"sudo systemctl enable ustreamer@${i}"
			
			# Instance Status
			msg - "Status of Service Instance: ustreamer@${i}" \
				"$(sudo systemctl status ustreamer@${i})"
			
			# Instance URL Infomation
			msg i "uStreamer@${i} is now ready can be accessed at: ( \e]8;;http://localhost:808${i}\ahttp://localhost:808${i}\e]8;;\a ) | ( \e]8;;http://${HOST_IP}:808${i}\ahttp://${HOST_IP}:808${i}\e]8;;\a )"
			
			# Increment Index
			((i=i+1))  # let "i++"
		done


	# MJPEG-Streamer ---------------------------------------------------------------------------------------------------------------
	elif [[ ${streamer_list_entry_selected[*]} =~ 'MPEG-Streamer' ]]; then
	
	msg h "MJPEG-Streamer Setup"
	
	msg % "Installing Build Tools & Dependencies" \
		'sudo apt-get install -qq -y build-essential libjpeg8-dev imagemagick libv4l-dev cmake git'
	msg % "Building & Installing Latest MJPEG-Streamer from GIT Repository" \
		'cd /tmp; git clone https://github.com/jacksonliam/mjpg-streamer.git; cd mjpg-streamer/mjpg-streamer-experimental; make; sudo make install'
	
	# Create System Account for mjpg-streamer process
	SERVICE_ACCOUNT=webcam
	msg % "Creating System Account (${SERVICE_ACCOUNT}) for mjpg-streamer process" \
		"[ ! $(getent passwd ${SERVICE_ACCOUNT}) ] && sudo useradd --system ${SERVICE_ACCOUNT} || echo 'User Already Exist'"
	msg % "Adding System Account (${SERVICE_ACCOUNT}) to (video) group" \
		"[ ! $(user=${SERVICE_ACCOUNT}; group=video; getent group ${group} | grep "\b${user}\b") ] && sudo adduser ${SERVICE_ACCOUNT} video || echo 'User Already Member of Group'"
	msg %% "Granting System Account (${SERVICE_ACCOUNT}) access to video devices" \
		"sudo usermod -a -G video ${SERVICE_ACCOUNT}"

	# -----------------------------------------------------

# Main Service
msg i "Creating MJPEG-Streamer Service"
# - - - - - - - - - - - - - - - - - - - - - - - - - - -
cat << EOF | sudo tee "/lib/systemd/system/mjpg-streamer.service" >/dev/null 2>&1
[Unit]
Description=MJPEG-Streamer Service | A Linux-UVC streaming application with Pan/Tilt
Documentation=https://github.com/jacksonliam/mjpg-streamer
After=syslog.target
After=network.target
Wants=network.target


[Service]
Type=simple

# Process Priority
Nice=+10

# Restart service after x seconds if node service crashes
Restart=always
RestartSec=5

# User & Group
User=webcam
Group=video

# Capabilities & Security Settings
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
ProtectHome=true
ProtectSystem=full

# Output to syslog
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=mjpg-streamer

# = Option 1 = (Environment)
# - Input Process -
$(mjpg_streamer --input "input_uvc.so --help" 3>&1 1>&2 2>&3 | grep .  | sed '1d;$d' | sed 's/^/#/')
# mjpg_streamer --input "input_uvc.so --help"
Environment=INPUT_OPTIONS="input_uvc.so --device /dev/video0"

# - Output Process -
$(mjpg_streamer --output "output_http.so --help" 3>&1 1>&2 2>&3 | grep .  | sed '1d;$d' | sed 's/^/#/')
# mjpg_streamer --output "output_http.so --help"
Environment=OUTPUT_OPTIONS="output_http.so --port 8080 --www /usr/local/share/mjpg-streamer/www"

# = Option 2 = (EnvironmentFile)
# EnvironmentFile=-/etc/mjpg-streamer.d/default.conf

# = Start Process =
ExecStart=/usr/local/bin/mjpg_streamer --input "\${INPUT_OPTIONS}" --output "\${OUTPUT_OPTIONS}"


[Install]
WantedBy=multi-user.target
EOF

# -----------------------------------------------------

# Service Settings
msg i "Creating MJPEG-Streamer Service Settings File (Optional)"
# --------------------------
sudo mkdir -p "/etc/mjpg-streamer.d/" >&4 2>&1
cat << EOF | sudo tee "/etc/mjpg-streamer.d/default.conf" >/dev/null 2>&1
# MJPG-Streamer Settings
# https://github.com/jacksonliam/mjpg-streamer

# - Input Process -
$(mjpg_streamer --input "input_uvc.so --help" 3>&1 1>&2 2>&3 | grep .  | sed '1d;$d' | sed 's/^/#/')
# mjpg_streamer --input "input_uvc.so --help"
INPUT_OPTIONS="input_uvc.so --device /dev/video0 --resolution 640x480 --quality 80 --fps 15"

# - Output Process -
$(mjpg_streamer --output "output_http.so --help" 3>&1 1>&2 2>&3 | grep .  | sed '1d;$d' | sed 's/^/#/')
# mjpg_streamer --output "output_http.so --help"
OUTPUT_OPTIONS="output_http.so --port 8080 --www '/usr/local/share/mjpg-streamer/www'"

EOF

# -----------------------------------------------------

# Create Template Service
msg i "Creating MJPEG-Streamer Service Template"
# - - - - - - - - - - - - - - - - - - - - - - - - - - -
cat << EOF | sudo tee "/lib/systemd/system/mjpg-streamer@.service" >/dev/null 2>&1
[Unit]
Description="MJPEG-Streamer Service Instance: %I | Default Device: /dev/video%i | Default Port: 808%i"
Documentation=https://github.com/jacksonliam/mjpg-streamer
After=syslog.target
After=network.target
Wants=network.target


[Service]
Type=simple

# Process Priority
Nice=+10

# Restart service after x seconds if node service crashes
Restart=always
RestartSec=5

# User & Group
User=webcam
Group=video

# Capabilities & Security Settings
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
ProtectHome=true
ProtectSystem=full

# Output to syslog
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=mjpg-streamer

# = Option 1 = (Environment)
# - Input Process -
$(mjpg_streamer --input "input_uvc.so --help" 3>&1 1>&2 2>&3 | grep .  | sed '1d;$d' | sed 's/^/#/')
# mjpg_streamer --input "input_uvc.so --help"
Environment=INPUT_OPTIONS="input_uvc.so --device /dev/video%i"

# - Output Process -
$(mjpg_streamer --output "output_http.so --help" 3>&1 1>&2 2>&3 | grep .  | sed '1d;$d' | sed 's/^/#/')
# mjpg_streamer --output "output_http.so --help"
Environment=OUTPUT_OPTIONS="output_http.so --port 808%i --www /usr/local/share/mjpg-streamer/www"

# = Option 2 = (EnvironmentFile)
# ExecStartPre=+/bin/cp --update '/etc/mjpg-streamer.d/default.conf' '/etc/mjpg-streamer.d/%i.conf'
# EnvironmentFile=-/etc/mjpg-streamer.d/%i.conf

# = Start Process =
ExecStart=/usr/local/bin/mjpg_streamer --input "\${INPUT_OPTIONS}" --output "\${OUTPUT_OPTIONS}"


[Install]
WantedBy=multi-user.target
EOF

	# -----------------------------------------------------
	
	# Reload Services
	msg % "Reloading Service Deamon" \
		"sudo systemctl daemon-reload"
	
	# =====================================================
	
	# Check if Camera's Avalible 
	if [[ -e "/dev/video0" ]]; then
		
		# Menu MJPEG Streamer Setup
		whiptail_title="MJPEG-Streamer Camera Options"
		whiptail_message="mjpg-streamer is a command line application that copies JPEG frames from one or more input plugins to multiple output plugins. It can be used to stream JPEG files over an IP-based network from a webcam to various types of viewers such as Chrome, Firefox, Cambozola, VLC, mplayer, and other software capable of receiving MJPG streams\n\nWould you like MJPG Stream setup for any one camera you plug in. This makes using a camera very easy. Just plug any camera in and it will work.\n\nAlternatively, if you plan to plugin muluple camera's at once and want seperate streams for each camera. This script can setup seperate streams where each stream has a camera assisgend to it by device ID. This way the streams do not change on reboot.\nHowever, new cameras will require changing ID. You can do that by just reruning this script."
		
		whiptail_menu_entry_selected=$(whiptail --menu --backtitle "${SCRIPT_TITLE_FULL}  |  To ABORT at anytime, press 'ESC' or 'CTRL + C'" --nocancel --ok-button "Setup Camera(s)" --title "${whiptail_title}" "${whiptail_message}" 24 78 2 \
			"Single Camera" "  Setup MJPEG-Streamer for a single camera on /dev/video0" \
			"Multiple Cameras" "  Setup MJPEG-Streamer cameras based on /dev/v4l/by-id/*" 3>&1 1>&2 2>&3)
		
		
		# MJPEG-Streamer Single/Multi Camera Setup
		if [[ ${whiptail_menu_entry_selected[*]} =~ 'Multiple' ]]; then
			msg h "MJPEG-Streamer Multi Camera Setup"
			 
			# Menu Checklist MJPEG Streamer Camera(s)
			whiptail_list_entry_options=()
			whiptail_title="MJPEG Streamer Camera(s)"
			whiptail_message='Seletect cameras to be configured.'
			
			# Entry Options by ID (so they can be mapped to a particular port)
			for dev in $(ls -1 /dev/v4l/by-id/ | grep index0); do
				whiptail_list_entry_options+=("$dev")
				whiptail_list_entry_options+=("Device by ID")
				whiptail_list_entry_options+=("ON")
			done
			
			# Present Checklist
			whiptail_list_entry_count=$((${#whiptail_list_entry_options[@]} / 3 ))
			whiptail_list_entry_selected=$(whiptail --checklist --separate-output --title "${whiptail_title}" "${whiptail_message}" 20 150 $whiptail_list_entry_count -- "${whiptail_list_entry_options[@]}" 3>&1 1>&2 2>&3)
			
		else # [[ ${whiptail_menu_entry_selected[*]} =~ 'Single' ]]; then
			msg h "MJPEG-Streamer Single Camera Setup"
			whiptail_list_entry_selected+=("/dev/video0")
		fi
	else 
		msg ! "No Camera Detected, setting up for single camera operation."
		msg h "MJPEG-Streamer Single Camera Setup"
		whiptail_list_entry_selected+=("/dev/video0")
	fi
		
	# Process Selections
	i=0  # Instance Counter
	mapfile -t list_entry_selected <<< "${whiptail_list_entry_selected}"
	for entry_selected in "${list_entry_selected[@]}"; do
		
		# Add Path to Camera Devices based on selection
		if [[ ${whiptail_menu_entry_selected[*]} =~ 'Multiple' ]]; then
			# Multiple Device by ID
			camera_device="/dev/v4l/by-id/${entry_selected}"
		else 
			# Single Device by ID
			camera_device="${list_entry_selected}"
		fi
		
		# Detect if camera exist, then promt for customisations
		if [[ -e "${camera_device}" ]]; then
			
			# Camera Resolution Get Options
			whiptail_list_entry_resolution=()
			for entry in $(v4l2-ctl --list-formats-ext --device "${camera_device}" | grep -oP "[[:digit:]]+x[[:digit:]]+" | sort -nr | uniq); do
				whiptail_list_entry_resolution+=("$entry"  "Resolution")
			done
			
			# Camera Resolution Menu
			camera_resolution=$(whiptail --menu --title "MJPEG Streamer Camera(s) Resolution" \
			"Select Camera Resolution for Camera: \n${camera_device}\n\nThe lower the resolution the less proccessing power required. Lower resolutions are recommeneded." \
			--nocancel --ok-button "Apply" \
			--backtitle "${SCRIPT_TITLE_FULL}  |  To ABORT at anytime, press 'ESC' or 'CTRL + C'" \
			18 84 6 \
			"${whiptail_list_entry_resolution[@]}" 3>&1 1>&2 2>&3)
			
			# Camera FPS Get Options
			whiptail_list_entry_fps=()
			for entry in $(v4l2-ctl --list-formats-ext --device "${camera_device}" | grep -oP '\(\K(\d+)(?=.*fps)' | sort -n | uniq); do
				whiptail_list_entry_fps+=("$entry"  "FPS")
			done
			
			# Camera FPS Menu
			camera_fps=$(whiptail --menu --title "MJPEG Streamer Camera(s) FPS" \
			"Select Camera Frame Per Second (FPS) for Camera: \n${camera_device}\n\nThe lower the FPS the less proccessing power required. Lower FPS are recommeneded." \
			--nocancel --ok-button "Apply" \
			--backtitle "${SCRIPT_TITLE_FULL}  |  To ABORT at anytime, press 'ESC' or 'CTRL + C'" \
			18 84 6 \
			"${whiptail_list_entry_fps[@]}" 3>&1 1>&2 2>&3)
			
			# Copy Instance from Template to /etc to take priorty over template, then make needed changes to service file.
			msg i "MJPEG-Streamer Service Instance: mjpg-streamer@${i} | ${list_entry_selected}"
			msg % "Creating MJPEG-Streamer Service Instance: mjpg-streamer@${i}" \
				"sudo cp --update \"/lib/systemd/system/mjpg-streamer@.service\" \"/etc/systemd/system/mjpg-streamer@${i}.service\";
				 sudo sed -i \"s|Environment=INPUT_OPTIONS.*|Environment=INPUT_OPTIONS=\\\"input_uvc.so --device ${camera_device} --resolution ${camera_resolution} --fps ${camera_fps} --yuv\\\"|\" \"/etc/systemd/system/mjpg-streamer@${i}.service\" "
		else 
			msg ! "Camera NOT Detected, default settings will be used for camera: ${camera_device}"
			
			# Copy Instance from Template to /etc to take priorty over template, then make needed changes to service file.
			msg i "MJPEG-Streamer Service Instance: mjpg-streamer@${i} | ${list_entry_selected}"
			msg % "Creating MJPEG-Streamer Service Instance: mjpg-streamer@${i}" \
				"sudo cp --update \"/lib/systemd/system/mjpg-streamer@.service\" \"/etc/systemd/system/mjpg-streamer@${i}.service\" "
		fi
		
		# Outputing Instance Infomation
		msg - "Service Instance Settings: mjpg-streamer@${i} | /etc/systemd/system/mjpg-streamer@${i}.service" \
			"$(grep "Environment=INPUT_OPTIONS" "/etc/systemd/system/mjpg-streamer@${i}.service"; \
			echo -ne '    '; grep "Environment=OUTPUT_OPTIONS" "/etc/systemd/system/mjpg-streamer@${i}.service"; \
			echo -ne '    '; grep "^ExecStart=" "/etc/systemd/system/mjpg-streamer@${i}.service")
			\n    Note: These settings can be changed with command: sudo systemctl edit --full mjpg-streamer@${i}"
		
		# Reload Services
		msg % "Reloading Service Deamon" \
			"sudo systemctl daemon-reload"
		
		# Instance Start
		msg % "Starting Service Instance Settings: mjpg-streamer@${i}" \
			"sudo systemctl restart mjpg-streamer@${i}"
			
		# Instance Start
		msg % "Enabling Service Instance Settings: mjpg-streamer@${i}" \
			"sudo systemctl enable mjpg-streamer@${i}"
		
		# Instance Status
		msg - "Status of Service Instance: mjpg-streamer@${i}" \
			"$(sudo systemctl status mjpg-streamer@${i})"
		
		# Instance URL Infomation
		msg i "MJPEG-Streamer@${i} is now ready can be accessed at: ( \e]8;;http://localhost:808${i}\ahttp://localhost:808${i}\e]8;;\a ) | ( \e]8;;http://${HOST_IP}:808${i}\ahttp://${HOST_IP}:808${i}\e]8;;\a )"
		
		# Increment Index
		((i=i+1))  # let "i++"
	done
fi
fi


# ----------------------------------------------------------------------------------------------------------------------------------
# -- Main [ Install FFmpeg from Package Manager ]  for recording mjpg-streamer streams to file, saving live streams
# ----------------------------------------------------------------------------------------------------------------------------------
if [[ ${main_list_entry_selected[*]} =~ 'A09' ]]; then
	msg h "FFmpeg-Streamer Setup"

	# Install FFMpeg from Package Manager
	msg % "Install FFmpeg from Package Manager" \
		"sudo apt-get install -y ffmpeg"

	# Clone GIT Repository: cncjs/cncjs-pi-raspbian, if directory does not exist
	if [ ! -d '/tmp/cncjs-pi-raspbian' ]; then
		msg % "Cloning GIT Repository: cncjs/cncjs-pi-raspbian" \
			"git clone https://github.com/cncjs/cncjs-pi-raspbian.git /tmp/cncjs-pi-raspbian"
	else
		msg i "Cloned GIT Repository: cncjs/cncjs-pi-raspbian to /tmp/cncjs-pi-raspbian"
	fi

	# Create Videos Direcory
	if [ ! -d "${HOME}/Videos/" ]; then
		msg % "Creating Videos Folder: ${HOME}/Videos/" \
			"mkdir "${HOME}/Videos/""
	else
		msg i "Videos Folder: ${HOME}/Videos/"
	fi

	# Copy Video Files from Repository
	msg % "Copy Video Scripts from Repository" \
		"cp "/tmp/cncjs-pi-raspbian/accessories/video/"* "${HOME}/Videos/"; \
		chmod +x "${HOME}/Videos/"*.sh"
fi


# # ----------------------------------------------------------------------------------------------------------------------------------
# # -- Main [ Start CNCjs ]  start CNCjs for testing / validating
# # ----------------------------------------------------------------------------------------------------------------------------------
# if [[ ${main_list_entry_selected[*]} =~ 'A10' ]]; then
# 	msg h "Starting CNCjs"
# 	msg i "Starting CNCjs"
# 	msg ! " └ To Stop Press (CTRL + C)"
# 	msg i " └ ( \e]8;;http://${HOST_IP}\ahttp://${HOST_IP}\e]8;;\a ) | ( \e]8;;http://${HOST_IP}:${CNCJS_PORT}\ahttp://${HOST_IP}:${CNCJS_PORT}\e]8;;\a )"
# 	msg - 'CNCjs Start Command' "(which cncjs) --verbose ${cncjs_flags}"
# 	$(which cncjs) --verbose ${cncjs_flags}
# fi

# ----------------------------------------------------------------------------------------------------------------------------------
# -- Main [ Reboot ]  reboot after install
# ----------------------------------------------------------------------------------------------------------------------------------
if [[ ${main_list_entry_selected[*]} =~ 'A10' ]]; then
	msg h "Rebooting"
	msg % "Rebooting Raspberry Pi" \
	  "sudo reboot"
fi


# ----------------------------------------------------------------------------------------------------------------------------------
# -- Main [ Finished ]  
# ----------------------------------------------------------------------------------------------------------------------------------
msg h "Finished"
msg i "Script Finished, its recommended that you reboot your Raspberry Pi."
msg L "To reboot run the command: sudo reboot"
