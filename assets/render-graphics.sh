#!/bin/bash

#Sizes needed by tango guidelines:
sizes=(16 22 24 32 48 256 )

for size in ${sizes[@]}
do
  mkdir -p ${size}
  rsvg-convert ./corebird.svg --width="${size}" --height="${size}" \
               --format=png -o "./${size}x${size}/corebird_${size}.png"
done

svg-convert ./no_avatar.svg --width="22" --height="22" \
               --format=png -o "./no_avatar.png"
              
svg-convert ./no_banner.svg --width="360" --height="180" \
               --format=png -o "./no_banner.png"