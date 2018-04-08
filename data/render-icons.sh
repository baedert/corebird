#!/bin/bash

# Oh god I hate bash.

sizes=(16 24 32 48 64 96 128 256)

for size in ${sizes[@]}
do
  name="./hicolor/${size}x${size}/corebird.png"

  rsvg-convert ./corebird.svg --width="${size}" --height="${size}" \
               --format=png -o ${name}
  # https://github.com/baedert/corebird/pull/826

  zopflipng --iterations=500 --keepchunks=iCCP \
    --lossy_transparent --splitting=3 -my ${name} ${name}
done
