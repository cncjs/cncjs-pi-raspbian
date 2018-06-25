# [Varables]
source_stram="http://localhost:8080/?action=stream"
destination_directory="/home/pi/Videos"
destination_file="xcarve-recording_$(date +'%Y%m%d_%H%M%S').mpeg"

# Recored Stream w/ ffmpeg
#ffmpeg -i "${source_stram}" "${destination_directory}/${destination_file}"

# https://gist.github.com/indiejoseph/a0547b1c996cea428311
# -use_wallclock_as_timestamps 1  # https://superuser.com/questions/474004/mjpeg-recording-with-ffmpeg-preserving-time-information
ffmpeg -f mjpeg -re -i "${source_stram}" -q:v 10 "${destination_directory}/${destination_file}"