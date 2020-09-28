#!/usr/bin/env bash
# ===========================================================================
# CNCjs Installer
#  - https://cnc.js.org
#  - https://github.com/cncjs
# 
#  curl -sSL https://install.pi-hole.net | bash
# 
# License: MIT License
# Copyright (c) 2018-2020 CNCjs (https://github.com/cncjs)
# 
# Version: 1.0.2
# Date: 2020 / 09 / 27
# Author: Austin St. Aubin
# 
# Notes:
#   Replaces Prebuilt Images: https://github.com/cncjs/cncjs-pi-raspbian
# =============================================================================

# ----------------------------------------------------------------------------------------------------------------------------------
# -- [ Error / Exception Handling ]
# ----------------------------------------------------------------------------------------------------------------------------------
# -e option instructs bash to immediately exit if any command [1] has a non-zero exit status
# We do not want users to end up with a partially working install, so we exit the script
# instead of continuing the installation with something broken
set -e

# Catch Expections to users home directory.
cd ~/

# ----------------------------------------------------------------------------------------------------------------------------------
# -- Varrables [ General ]  genneral global varables
# ----------------------------------------------------------------------------------------------------------------------------------
HOST_IP=$(hostname -I | cut -d' ' -f1)
CNCJS_EXT_DIR="${HOME}/.cncjs"
cncjs_flags="--port 8000 --config "${CNCJS_EXT_DIR}/cncrc.cfg" --watch-directory "${CNCJS_EXT_DIR}/watch" --host ${HOST_IP}"
SKIP_OS_CHECK=false
COMPATIBLE_OS_ID='raspbian'
COMPATIBLE_OS_ID_VERSION=10  # greater than or equal

# Color / Messange Handling
COL_NC='\e[0m' # No Color
COL_BLACK='\e[1;30m'
COL_RED='\e[1;31m'
COL_GREEN='\e[1;32m'
COL_YELLOW='\e[1;33m'
COL_BLUE='\e[1;34m'
COL_MAGENTA='\e[1;35m'
COL_CYAN='\e[1;36m'
COL_WHITE='\e[1;37m'

# Message
PASS="[${COL_GREEN}✓${COL_NC}]"
FAIL="[${COL_RED}✗${COL_NC}]"
WARN="[${COL_YELLOW}"'!'"${COL_NC}]"
INFO="[${COL_CYAN}i${COL_NC}]"
QSTN="[${COL_MAGENTA}?${COL_NC}]"


# ----------------------------------------------------------------------------------------------------------------------------------
# -- Function [ Spinner ]  spinner animation for commands in progress.
# ----------------------------------------------------------------------------------------------------------------------------------
# https://unix.stackexchange.com/questions/225179/display-spinner-while-waiting-for-some-process-to-finish
# https://wiki.tcl-lang.org/page/Text+Spinner
function spinner() {
    # make sure we use non-unicode character type locale 
    # (that way it works for any locale as long as the font supports the characters)
    local LC_CTYPE=C
    
    local spin_chars=' ⣾ ⣽ ⣻ ⢿ ⡿ ⣟ ⣯ ⣷ '
    
    local pid=$1 # Process Id of the previous running command
    tput civis  # cursor invisible
    
    # spin animation
    ###while kill -0 $pid 2>/dev/null; do
	while ps -p $pid >/dev/null; do
        for i in ${spin_chars[@]}; do 
            echo -ne "\r  [$i]  $2  ";
            sleep 0.1;
        done;
    done
    
    tput cnorm  # cursor visible
    
    echo -ne "\r  ${PASS} ${COL_GREEN} $2 ${COL_NC}  \n";
    
    wait $pid   # capture exit code
    return $?
}

# ----------------------------------------------------------------------------------------------------------------------------------
# -- Function [ Message ]  message formatter, also used for passing commands.
# ----------------------------------------------------------------------------------------------------------------------------------
msg() {
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
        '%') # Spinner / Command
            # echo "[${1}] | [${2}] | [${3}] | [${4}]"
            /bin/sh -c "${3}" & spinner $! "${2}"
            ;;
        *) # Catch-all
            echo -e "${@}"
            ;;
    esac
}

# msg h "These are test!"
# msg p "This is a test!"
# msg x "This is a test!"
# msg ! "This is a test!"
# msg i "This is a test!"
# msg ? "This is a test!"
# msg % "This is a test!" "sleep 6"


# ----------------------------------------------------------------------------------------------------------------------------------
# -- Output [ Header ]  welcome message
# ----------------------------------------------------------------------------------------------------------------------------------
# $(curl --silent "https://api.github.com/repos/cncjs/cncjs/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')  # Get CNCjs Latest Version
echo -e "
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
  ${COL_WHITE}==========================================================================${COL_NC}"

# ----------------------------------------------------------------------------------------------------------------------------------
# -- Menu [ Menu Welcome ]  welcome message
# ----------------------------------------------------------------------------------------------------------------------------------
# https://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
# https://www.bradgillap.com/guide/post/bash-gui-whiptail-menu-tutorial-series-1
# https://gist.github.com/wafsek/b78cb3214787a605a28b

message="This script will install the lastest version of CNCjs w/ NodeJS.
                     https://github.com/cncjs

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
checklist_title="CNCjs Install Options"

checklist_message='asd'

declare -A checklist_options=(\
	[Skip OS Check]="Skip checking if this script is known to be compatable with this OS.","NO" \
	[Update System]="Update System to latest Pacakages","YES" \
	[Remove Old NodeJS or NPM Packages]="Remove NodeJS or NPM Packages that might have been install incorrectly","NO" \
	[Install/Update Node.js & NPM via Package Manager]="as","YES" \
	[Install CNCjs with NPM]="Install CNCjs","YES" \
	[Install CNCjs Pendants & Widgets]="","YES" \
	[Setup IPtables]="Allows to access web ui from 80 to make web access easier","YES" \
	[Autostart & Managment Task w/ Crontab]="Setup autostart so CNCjs starts when Raspberry Pi boots","YES" \
	[Start CNCjs after Install]="","YES" \
  )
	
checklist_entry_options=()
checklist_entries_count=${#checklist_options[@]}
checklist_selected_names=()

for entry in "${!checklist_options[@]}"; do
	# echo "TESTING: checklist_options[$entry]}:${checklist_options[$entry]} | entry:$entry | ### $(echo ${checklist_options[$entry]} | cut -d',' -f2)"
	checklist_entry_options+=("$entry")
	checklist_entry_options+=("$(echo ${checklist_options[$entry]} | cut -d',' -f1)  ")
	checklist_entry_options+=($(echo ${checklist_options[$entry]} | cut -d',' -f2))
done

# Present Checklist
checklist_selected_descriptions=$(whiptail --checklist --separate-output --title "${checklist_title}" "$checklist_message" 30 140 $checklist_entries_count -- "${checklist_entry_options[@]}" 3>&1 1>&2 2>&3)

mapfile -t checklist_selected_names <<< "$checklist_selected_descriptions"

# for checklist_selected_name in "${checklist_selected_names[@]}"; do
# 	echo "Selected Name: ${checklist_selected_name}"
# done

# echo " - - - - - - - - "
# echo ${checklist_selected_names[*]}
# echo ${!checklist_selected_names[*]}
# echo ${#checklist_selected_names[*]}
# echo ${checklist_selected_names[@]}
# echo ${!checklist_selected_names[@]}
# echo ${#checklist_selected_names[@]}
# echo " - - - - - - - - "

# ----------------------------------------------------------------------------------------------------------------------------------
# -- Menu [ CNCjs Addons Check List ]  selection of CNCjs Addons / Extentions / Pendants & Widgets
# ----------------------------------------------------------------------------------------------------------------------------------
if [[ ${checklist_selected_names[*]} =~ 'Install CNCjs Pendants & Widgets' ]]; then
	# Menu Checklist CNCjs Pendants & Widgets
	checklist_title="CNCjs Pendants & Widgets"
	
	checklist_message='CNCjs Pendants and Widgets entend the funtionality of the platform.\n\nThe user interface is organized as a collection of "widgets", each of which manages a specific aspect of machine control. For example, there are widgets for things like toolpath display, jogging, position reporting, spindle control, and many other functions. Users can control which widgets appear on the screen, omitting ones that do not apply to their machine. There is a way to add custom widgets to support new features. \nExample boilerplate pendant can be found at: https://github.com/cncjs/cncjs-pendant-boilerplate\n\nFinally, there is a collection of "pendants" - specialized user interfaces optimized for simplified control panels such as small LCD screens, wireless keyboards, button panels, and the like. Pendants interact with the cncjs server using subsets of the full set of functions that the main user interface uses.\nExample boilerplate pendant can be found at: https://github.com/cncjs/cncjs-pendant-boilerplate\n\nPlease select the Pendants and Widgets you would like to install:'
	
	declare -A checklist_options=(\
		[Pendant TinyWeb]="https://github.com/cncjs/cncjs-pendant-boilerplate","YES" \
		[Pendant Shopfloor Tablet]="https://github.com/cncjs/cncjs-shopfloor-tablet","NO" \
		[Widget Boilerplate]="https://github.com/cncjs/cncjs-widget-boilerplate","YES" \
	  )
	
	checklist_entry_options=()
	checklist_entries_count=${#checklist_options[@]}
	checklist_addons_selected_names=()
	
	for entry in "${!checklist_options[@]}"; do
		# echo "TESTING: checklist_options[$entry]}:${checklist_options[$entry]} | entry:$entry | ### $(echo ${checklist_options[$entry]} | cut -d',' -f2)"
		checklist_entry_options+=("$entry")
		checklist_entry_options+=("$(echo ${checklist_options[$entry]} | cut -d',' -f1)  ")
		checklist_entry_options+=($(echo ${checklist_options[$entry]} | cut -d',' -f2))
	done
	
	# Present Checklist
	checklist_selected_descriptions=$(whiptail --checklist --separate-output --title "${checklist_title}" "$checklist_message" 30 90 $checklist_entries_count -- "${checklist_entry_options[@]}" 3>&1 1>&2 2>&3)
	
	mapfile -t checklist_addons_selected_names <<< "$checklist_selected_descriptions"
	
	# for checklist_selected_name in "${checklist_addons_selected_names[@]}"; do
	# 	echo "Selected Name: ${checklist_selected_name}"
	# done
	
	# echo " - - - - - - - - "
	# echo ${checklist_addons_selected_names[*]}
	# echo ${!checklist_addons_selected_names[*]}
	# echo ${#checklist_addons_selected_names[*]}
	# echo ${checklist_addons_selected_names[@]}
	# echo ${!checklist_addons_selected_names[@]}
	# echo ${#checklist_addons_selected_names[@]}
	# echo " - - - - - - - - "
fi

# ----------------------------------------------------------------------------------------------------------------------------------
# -- Main [ OS Handling / Checking ]  check if detected operating system is known to be compatable with this script
# ----------------------------------------------------------------------------------------------------------------------------------
detected_os_id=$(cat /etc/*release | grep '^ID=' | cut -d '=' -f2- | tr -d '"')
detected_os_id_version=$(cat /etc/*release | grep '^VERSION_ID=' | cut -d '=' -f2- | tr -d '"')

if [[ $SKIP_OS_CHECK != true ]] && [[ ! ${checklist_selected_names[*]} =~ 'Skip OS Check' ]] ; then
    if [[ "$detected_os_id" == "$COMPATIBLE_OS_ID" ]] && [[ $detected_os_id_version -ge $COMPATIBLE_OS_ID_VERSION ]]; then
        msg p "Detected OS is compatable with this install script. [ $detected_os_id | $detected_os_id_version ]"
    else
        msg p "Detected OS is NOT compatable with this install script! [ $detected_os_id | $detected_os_id_version ]"
        msg i "This installer is designed for the [Raspberry Pi](https://www.raspberrypi.org)"
        exit 1;
    fi
else
    msg i "Detected OS: [ $detected_os_id | $detected_os_id_version ]"
    msg ! "Skipped OS Checking | Variable: SKIP_OS_CHECK=$SKIP_OS_CHECK"
fi

# ----------------------------------------------------------------------------------------------------------------------------------
# -- Main [ Update System ]  update operating system packages
# ----------------------------------------------------------------------------------------------------------------------------------
if [[ ${checklist_selected_names[*]} =~ 'Update System' ]]; then
	msg % "Update System Packages" 'sudo apt-get update -qq'
	msg % "Upgrade System Packages" 'sudo apt-get upgrade -qq -y'
	msg % "Upgrade System Distribution" 'sudo apt-get dist-upgrade -qq -y'
	msg % "Fix Broken Packages (if any)" 'sudo apt-get update --fix-missing -qq -y'
fi

# ----------------------------------------------------------------------------------------------------------------------------------
# -- Main [ Setup Node.js & NPM ]  via Package Manager
# ----------------------------------------------------------------------------------------------------------------------------------
if [[ ${checklist_selected_names[*]} =~ 'Remove Old NodeJS or NPM Packages' ]] || [[ ${checklist_selected_names[*]} =~ 'Install/Update Node.js & NPM via Package Manager' ]]; then
	msg h "Setup Node.js & NPM via Package Manager"
	
	# Remove Old NodeJS or NPM Packages (Optional)
	if [[ ${checklist_selected_names[*]} =~ 'Remove Old NodeJS or NPM Packages' ]]; then
		msg % "Removing any Old NodeJS or NPM Packages" 'sudo apt-get purge -y npm nodejs'
		msg % "Removing Un-needed Packages" 'sudo apt-get autoremove -y'
	fi
	
	# Install/Update Node.js & NPM via Package Manager
	if [[ ${checklist_selected_names[*]} =~ 'Install/Update Node.js & NPM via Package Manager' ]]; then
		# https://github.com/nodesource/distributions#rpminstall
		msg % "Install Node.js v10.x Package Source" 'curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash - > /dev/null 2>&1'
		msg % "Install Node.js v10.x via Package Manager" 'sudo apt-get install nodejs -qq -y'
		msg % "Install Build Essential" 'sudo apt-get install build-essential gcc g++ make -qq -y -f'
		msg % "Install Latest Node Package Manager (NPM)" 'sudo npm install -g npm@latest >/dev/null 2>&1'
	fi
fi

# ----------------------------------------------------------------------------------------------------------------------------------
# -- Output [ NodeJS & NPM Version ]  output installed versions info
# ----------------------------------------------------------------------------------------------------------------------------------
msg i "NodeJS: \t$(node -v) \t|\t $(which node)"
msg i "NPM: \tv$(npm -v) \t|\t $(which npm)"

# ----------------------------------------------------------------------------------------------------------------------------------
# -- Main [ Install CNCjs ]  w/ NPM
# ----------------------------------------------------------------------------------------------------------------------------------
if [[ ${checklist_selected_names[*]} =~ 'Install CNCjs with NPM' ]]; then
	msg h "Install CNCjs"
	msg % "Install CNCjs with NPM" 'sudo npm install -g cncjs@latest --unsafe-perm >/dev/null 2>&1'
fi

# ----------------------------------------------------------------------------------------------------------------------------------
# -- Main [ Download & Install CNCjs Pendants & Widgets ]  get some of the CNCjs extentions
# ----------------------------------------------------------------------------------------------------------------------------------
if [[ -n ${checklist_addons_selected_names} ]]; then 
	msg h "Download & Install CNCjs Pendants & Widgets\t[ ${CNCJS_EXT_DIR} ]"
fi 

msg % "Create CNCjs Directory for Addons / Extentions / Logs / Watch\t( ${CNCJS_EXT_DIR} )" "mkdir -p ${CNCJS_EXT_DIR}/watch"

if [[ -n ${checklist_addons_selected_names} ]]; then 	
	if [[ ${checklist_addons_selected_names[*]} =~ 'Pendant TinyWeb' ]]; then
		name="Pendant TinyWeb"
		url="https://codeload.github.com/cncjs/cncjs-pendant-tinyweb"
		dir="${CNCJS_EXT_DIR}/pendant-tinyweb"
		sub="tinyweb"
		cncjs_flags+=" --mount /${sub}:${dir}/src"
		url+="/legacy.tar.gz/latest"
		msg % "Download & Install: $name\t\t( http://${HOST_IP}/${sub} )\t[ ${dir} ]" "mkdir -p ${dir}; curl -sS ${url} | tar -xvzf - -C ${dir} --strip 1 >/dev/null 2>&1"
	fi
	
	if [[ ${checklist_addons_selected_names[*]} =~ 'Pendant Shopfloor Tablet' ]]; then
		name="Pendant Shopfloor Tablet"
		url="https://codeload.github.com/cncjs/cncjs-shopfloor-tablet"
		dir="${CNCJS_EXT_DIR}/pendant-shopfloor-tablet"
		sub="tablet"
		cncjs_flags+=" --mount /${sub}:${dir}/src"
		url+="/legacy.tar.gz/latest"
		msg % "Download & Install: $name\t( http://${HOST_IP}/${sub} )\t\t[ ${dir} ]" "mkdir -p ${dir}; curl -sS ${url} | tar -xvzf - -C ${dir} --strip 1 >/dev/null 2>&1"
	fi
	
	if [[ ${checklist_addons_selected_names[*]} =~ 'Widget Boilerplate' ]]; then
		name="Widget Boilerplate"
		url="https://cncjs.github.io/cncjs-widget-boilerplate/v2/"
		sub="widget-boilerplate"
		cncjs_flags+=" --mount /${sub}:${url}"
		msg p "Setup: $name\t\t\t( http://${HOST_IP}/${sub} )\t( ${url} )"
	fi
fi

# ----------------------------------------------------------------------------------------------------------------------------------
# -- Main [ Setup IPtables ]  allow access to port 8000 from port 80
# ----------------------------------------------------------------------------------------------------------------------------------
if [[ ${checklist_selected_names[*]} =~ 'Setup IPtables' ]]; then
	msg % "Setup IPtables (allow access to port 8000 from port 80)" 'sudo iptables -t nat -I PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8000'
	
	# Make Iptables Persistent
	msg % "Make Iptables Persistent, select yes if prompted" 'sudo apt-get install iptables-persistent -qq -y -f'
	
	# How-to: Save & Reload Rules
	#sudo netfilter-persistent save
	#sudo netfilter-persistent reload
	
	# How-to: Manually Save Rules
	#sudo sh -c "iptables-save > /etc/iptables/rules.v4"
	#sudo sh -c "ip6tables-save > /etc/iptables/rules.v6"
	
	# Run this if issues to reconfigure iptables-persistent
	# sudo dpkg-reconfigure iptables-persistent
fi

# ----------------------------------------------------------------------------------------------------------------------------------
# -- Main [ Autostart & Managment Task w/ Crontab ]  start CNCjs on bootup
# ----------------------------------------------------------------------------------------------------------------------------------
if [[ ${checklist_selected_names[*]} =~ 'Autostart & Managment Task w/ Crontab' ]]; then
	# https://github.com/cncjs/cncjs/wiki/Setup-Guide:-Raspberry-Pi-%7C-Install-Node.js-via-Package-Manager-*(Recommended)*
	msg h "Autostart & Managment Task w/ Crontab"
	msg % "Setup & Configure CNCjs Autostart" "((crontab -l || true) | grep -v cncjs; echo \"@reboot $(which cncjs) ${cncjs_flags} >> $HOME/.cncjs/cncjs.log 2>&1\") | crontab -"
	# Disable Autostart
	# crontab -l | grep -v cncjs | crontab -
	msg % "Rotate Log Weekly (4000 lines)" "((crontab -l || true) | grep -v 'tail -n'; echo \"@weekly tail -n 4000 $HOME/.cncjs/cncjs.log > $HOME/.cncjs/cncjs.log 2>&1\") | crontab -"
	echo -e "${COL_BLUE}  Crontab Schedualed Task - - - - - - - - - - - - - - - -\n$(crontab -l)\n  - - - - - - - - - - - - - - - - - - - - - - - - - - - -${COL_NC}"
fi

# ----------------------------------------------------------------------------------------------------------------------------------
# -- Main [ Start CNCjs ]  start CNCjs for testing / validating
# ----------------------------------------------------------------------------------------------------------------------------------
if [[ ${checklist_selected_names[*]} =~ 'Start CNCjs after Install' ]]; then
	msg h "Starting CNCjs"
	msg i "Starting CNCjs"
	msg ! " └ To Stop Press (CTRL + C)"
	msg i " └ ( \e]8;;http://${HOST_IP}\ahttp://${HOST_IP}\e]8;;\a ) | ( \e]8;;http://${HOST_IP}:8000\ahttp://${HOST_IP}:8000\e]8;;\a )"
	echo -e "${COL_BLUE}  CNCjs Start Command - - - - - - - - - - - - - - - - - -\n$(which cncjs) --verbose ${cncjs_flags}\n  - - - - - - - - - - - - - - - - - - - - - - - - - - - -${COL_NC}"
	$(which cncjs) --verbose ${cncjs_flags}
fi