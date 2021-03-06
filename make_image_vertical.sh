#!/bin/bash
if [ "$#" -eq 0 ]; then
   echo ''
   echo 'Rotates images so that they are taller than wide. Original image is replaced. Accepts wildcards.'
   echo 'CAUTION: if this process fails, the image can be corrupted.'
   echo ''
   echo 'usage: make_image_vertical.sh <image name>'
   echo ''
else
	for file in "$@"
	do
		convert -rotate "-90<" $file $file 
	done
fi


