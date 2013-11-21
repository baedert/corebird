#!/bin/bash

command -v inkscape >/dev/null 2>&1 || { echo "Inkscape is required to render the graphics. Aborting." >&2; exit 1;}

function render_icons {
        sizes=(16 22 24 32 48 64 128 256 512)

        for size in ${sizes[@]}
        do
	  mkdir -p ${size}x${size}
	  if [ $size != 24 ]
	    then
	      inkscape ./corebird.svg -w ${size} -h ${size} -z -C -e ./${size}x${size}/corebird.png
          else
	    convert ./22x22/corebird.png -bordercolor none -border 1 ./24x24/corebird.png
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
	      inkscape ./corebird_alternative.svg -w ${size} -h ${size} -z -C -e ./${size}x${size}/corebird_alternative.png
          else
	    convert ./22x22/corebird_alternative.png -bordercolor none -border 1 ./24x24/corebird_alternative.png
	  fi
        done
}

function render_no_avatar {
	inkscape ./no_avatar.svg -w 24 -h 24 -z -C -e no_avatar.png
}
              
function render_no_banner {
	inkscape ./no_banner.svg -w 320 -h 160 -z -C -e no_banner.png
}
               
function render_verified {
	inkscape ./verified.svg -w 16 -h 16 -z -C -e verified.png
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
elif [ "$1" = 'alternative' ]
  	then
    		render_alternative
elif [ "$1" = 'all' ]
        then
                render_icons
                render_no_avatar
                render_no_banner
                render_verified
		render_alternative
else
        echo "Usage: ./render.sh [OPTION], where [OPTION] can be icon, avatar, banner, verified, alternative or all."
fi
