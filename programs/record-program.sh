#!/bin/bash

program=$1

stem="${program%,fd1}"
image="$stem.png"
video="$stem.mp4"
roname="${stem//\//.}"
log="$stem.log"

if [ -f "$image" ] ; then
    echo "Skipping $program, as image already exists"
    exit 0
fi

rm -rf video
mkdir -p video

# Run the program
echo "Running $program as $roname"
pyrodev --common \
        --config graphics.implementation=cairo \
        --config graphicscairo.video_directory=video \
        --config graphicscairo.video_enable=true \
        --config graphicscairo.video_pointer=true \
        --config graphicscairo.save_on_exit=yes \
        --config graphicscairo.save_filename="$image" \
        --config emulation.runtime_limit=120s \
        --command "/$roname" < /dev/null 2>&1 | tee "$log"

# Now make a video
echo "Making video"
script='video/ffmpeg_concat_1.txt'
if [ ! -f "$script" ] ; then
    script='video/ffmpeg_concat.txt'
fi
# Extract the command from the video
cmd=$(grep '# *ffmpeg' "$script" | sed -e 's/# *//' -e "s/ video.mp4/ -y ${video//\//\\/}/")
echo "$cmd"
eval "$cmd"
