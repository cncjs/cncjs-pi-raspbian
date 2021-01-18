#!/bin/bash
# MJPEG Streamer Recorder w/ FFMpeg - v1
# chmod +x record.sh
# sh ~/record.sh start

FFMPEG_STREAMER_BIN="$(which ffmpeg)"

INPUT_OPTIONS="-y -f mjpeg -re"
SOURCE_STREAM="http://localhost:8080/?action=stream"

OUTPUT_OPTIONS="-q:v 10"
DESTINATION_DIRECTORY="/home/pi/Videos/record-stream_01"
DESTINATION_FILE="xcarve-recording_$(date +'%Y%m%d_%H%M%S').mpeg"

# ==========================================================
function checkFolder() { [ -d "$1" ] && echo "Folder Exsits: $1" || (echo "Making Folder: $1"; mkdir -p "$1"); }

function running() {
    if ps aux | grep ${FFMPEG_STREAMER_BIN} | grep "${SOURCE_STREAM}" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function start() {
    if running; then
        echo "already started"
        return 1
    fi

    export LD_LIBRARY_PATH="$(dirname $FFMPEG_STREAMER_BIN):."
    
    checkFolder "${DESTINATION_DIRECTORY}"

	echo "Starting:  ${FFMPEG_STREAMER_BIN} ${INPUT_OPTIONS} -i \"${SOURCE_STREAM}\" ${OUTPUT_OPTIONS} \"${DESTINATION_DIRECTORY}/${DESTINATION_FILE}\""
	#${FFMPEG_STREAMER_BIN} ${INPUT_OPTIONS} -i "${SOURCE_STREAM}" ${OUTPUT_OPTIONS} "${DESTINATION_DIRECTORY}/${DESTINATION_FILE}"  </dev/null >/dev/null 2>record_ffmpeg.log &  # https://trac.ffmpeg.org/wiki/PHP
	${FFMPEG_STREAMER_BIN} ${INPUT_OPTIONS} -i "${SOURCE_STREAM}" ${OUTPUT_OPTIONS} "${DESTINATION_DIRECTORY}/${DESTINATION_FILE}" >/dev/null 2>/dev/null &  # No Log File

    sleep 1

    if running; then
#         if [ "$1" != "nocheck" ]; then
#             check_running & > /dev/null 2>&1 # start the running checking task
#             check_hanging & > /dev/null 2>&1 # start the hanging checking task
#         fi

        echo "started"
        return 0

    else
        echo "failed to start"
        return 1

    fi
}

function stop() {
    if ! running; then
        echo "not running"
        return 1
    fi

    own_pid=$$

    if [ "$1" != "nocheck" ]; then
        # stop the script running check task
        ps aux | grep $0 | grep start | tr -s ' ' | cut -d ' ' -f 2 | grep -v ${own_pid} | xargs -r kill
        sleep 0.5
    fi

    # stop the process
    ps aux | grep ${FFMPEG_STREAMER_BIN} | grep "${SOURCE_STREAM}" | tr -s ' ' | cut -d ' ' -f 2 | grep -v ${own_pid} | xargs -r kill

    echo "stopped"
    return 0
}

function check_running() {
    echo "starting running check task" >> ${MJPG_STREAMER_LOG_FILE}

    while true; do
        sleep ${RUNNING_CHECK_INTERVAL}

        if ! running; then
            echo "server stopped, starting" >> ${MJPG_STREAMER_LOG_FILE}
            start nocheck
        fi
    done
}

function check_hanging() {
    echo "starting hanging check task" >> ${MJPG_STREAMER_LOG_FILE}

    while true; do
        sleep ${HANGING_CHECK_INTERVAL}

        # treat the "error grabbing frames" case
        if tail -n2 ${MJPG_STREAMER_LOG_FILE} | grep -i "error grabbing frames" > /dev/null; then
            echo "server is hanging, killing" >> ${MJPG_STREAMER_LOG_FILE}
            stop nocheck
        fi
    done
}

function help() {
    echo "Usage: $0 [start|stop|restart|status]"
    return 0
}

if [ "$1" == "start" ]; then
    start && exit 0 || exit -1

elif [ "$1" == "stop" ]; then
    stop && exit 0 || exit -1

elif [ "$1" == "restart" ]; then
    stop && sleep 1
    start && exit 0 || exit -1

elif [ "$1" == "status" ]; then
    if running; then
        echo "running"
        exit 0
    else
        echo "stopped"
        exit 1
    fi
else
    help
fi
