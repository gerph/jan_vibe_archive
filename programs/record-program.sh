#!/bin/bash

force=false

while [[ "${1:0:1}" == '-' ]] ; do
    if [[ "$1" == '--force' ]] ; then
        force=true
    else
        echo "Do not recognise option '$1'" >&2
        exit 1
    fi
    shift
done

program=$1

stem="${program%,fd1}"
image="$stem.png"
video="$stem.mp4"
roname="${stem//\//.}"
log="$stem.log"
rodir="${roname%.*}"
roleaf="${roname##*.}"

if ! $force && [ -f "$image" ] ; then
    echo "Skipping $program, as image already exists"
    exit 0
fi

extra_args=()
input=/dev/null

if [[ -f "$stem.noinput" ]] ; then
    # <file>.noinput means we'll never read anything even at an
    # input prompt.
    extra_args+=(--config input.eof_effect=none)
fi
if [[ -f "$stem.input" ]] ; then
    input="$stem.input"
fi

rm -rf video
mkdir -p video

# Run the program
echo "Running $program as $roname"
pyrodev --common \
        --config graphics.implementation=cairo \
        --config graphics.screen_banks=8 \
        --config graphicscairo.fonts_fontconfig=yes \
        --config graphicscairo.fonts_standard=yes \
        --config graphicscairo.video_directory=video \
        --config graphicscairo.video_enable=true \
        --config graphicscairo.video_pointer=true \
        --config graphicscairo.save_on_exit=yes \
        --config graphicscairo.save_filename="$image" \
        --config emulation.runtime_limit=120s \
        --config spriteutils.system_sprites_enable=true \
        --config input.readline_native=no \
        --config memorymap.appspace_size=4M \
        --config 'modes.numbered_modes=103:base=28,ncolours=256' \
        --config 'modes.numbered_modes=107:base=28,ncolours=256' \
        "${extra_args[@]}" \
        --command "dir $rodir" \
        --command "/$roleaf" < $input 2>&1 | tee "$log"

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
