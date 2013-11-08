#!/bin/bash

function render_icons {
        sizes=(16 22 24 32 48 256 )

        for size in ${sizes[@]}
        do
          mkdir -p ${size}x${size}
          rsvg-convert ./corebird.svg --width="${size}" --height="${size}" \
                       --format=png -o "./${size}x${size}/corebird_${size}.png"
        done
}

function render_no_avatar {
        rsvg-convert ./no_avatar.svg --width="24" --height="24" \
                       --format=png -o "./no_avatar.png"
}
              
function render_no_banner {
        rsvg-convert ./no_banner.svg --width="320" --height="160" \
                       --format=png -o "./no_banner.png"
}
               
function render_verified {
        rsvg-convert ./verified.svg --width="16" --height="16" \
                       --format=png -o "./verified.png"
}

if [ "$1" = 'icon' ]
        then
                render_icons
elif [ "$1" = 'avatar' ]
        then
                render_no_avatar
elif [ "$1" = 'banner' ]
        then
                render_no_banner
elif [ "$1" = 'verified' ]
        then 
                render_verified
elif [ "$1" = 'all' ]
        then
                render_icons
                render_no_avatar
                render_no_banner
                render_verified
else
        echo "Usage: ./render.sh [OPTION], where [OPTION] can be icon, avatar, banner, verified or all."
fi
