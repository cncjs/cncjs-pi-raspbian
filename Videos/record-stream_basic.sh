#!/bin/bash
# Recored MPEG Streams from URL to File

# [Varables]
source_stream="http://localhost:8080/?action=stream"
destination_directory="/home/pi/Videos"
destination_file="recording_$(date +'%Y%m%d_%H%M%S').mpeg"

# Recored Stream w/ ffmpeg
# https://gist.github.com/indiejoseph/a0547b1c996cea428311
# -use_wallclock_as_timestamps 1  # https://superuser.com/questions/474004/mjpeg-recording-with-ffmpeg-preserving-time-information
#ffmpeg -i "${source_stream}" "${destination_directory}/${destination_file}"
ffmpeg -f mjpeg -re -i "${source_stream}" -q:v 10 "${destination_directory}/${destination_file}"