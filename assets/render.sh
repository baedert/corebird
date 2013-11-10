#!/bin/bash

function render_icons {
        sizes=(16 22 24 32 48 64 128 256 512)

        for size in ${sizes[@]}
        do
	  mkdir -p ${size}x${size}
	  if [ $size != 24 ]
	    then
	      rsvg-convert ./corebird.svg --width="${size}" --height="${size}" \
                       --format=png -o "./${size}x${size}/corebird.png"
          else
	    convert ./22x22/corebird.png -bordercolor none -border 1 ./24x24/corebird_24.png
	  fi
        done
}

function render_alternative {
        sizes=(16 22 24 32 48 64 128 256 512)

        for size in ${sizes[@]}
        do
          mkdir -p ${size}x${size}
          if [ $size != 24 ]
	    then
	      rsvg-convert ./corebird_alternative.svg --width="${size}" --height="${size}" \
                       --format=png -o "./${size}x${size}/corebird_alternative.png"
          else
	    convert ./22x22/corebird_alternative.png -bordercolor none -border 1 ./24x24/corebird_alternative_24.png
	  fi
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
		render_alternative
elif [ "$1" = 'alternative' ]
  then
    render_alternative
else
        echo "Usage: ./render.sh [OPTION], where [OPTION] can be icon, avatar, banner, verified, alternative or all."
fi
