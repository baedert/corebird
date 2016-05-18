#!/bin/bash

# Oh god I hate bash.

sizes=(16 20 24 32 36 40 48 64 96 128 192 512)

for size in ${sizes[@]}
do
  rsvg-convert ./corebird.svg --width="${size}" --height="${size}" \
               --format=png -o "./${size}x${size}/corebird.png"
done
