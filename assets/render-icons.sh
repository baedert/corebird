#!/bin/bash

# Oh god I hate bash.

sizes=(16 32 64 128 512)

for size in ${sizes[@]}
do
  rsvg-convert ./corebird.svg --width="${size}" --height="${size}" \
               --format=png -o "./${size}x${size}/corebird.png"
done
