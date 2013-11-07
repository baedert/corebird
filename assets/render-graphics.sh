#!/bin/bash

# Following sizes are now based upon the tango guidelines
sizes=(16 22 24 32 48 256 )

# Render the corebird icon into different sizes
for size in ${sizes[@]}
do
  mkdir -p ${size}x${size}
  rsvg-convert ./corebird.svg --width="${size}" --height="${size}" \
               --format=png -o "./${size}x${size}/corebird_${size}.png"
done

# Render other images
rsvg-convert ./no_avatar.svg --width="24" --height="24" \
               --format=png -o "./no_avatar.png"
              
rsvg-convert ./no_banner.svg --width="320" --height="160" \
               --format=png -o "./no_banner.png"
               
rsvg-convert ./verified.svg --width="16" --height="16" \
               --format=png -o "./verified.png"