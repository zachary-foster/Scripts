#!/bin/bash
if [ "$#" -ne 3 ]; then
   echo 'Makes a copy of a directory structure (i.e. including subdirectories) containing images with resized versions of the images.'
   echo 'usage: resized_image_directory_clone.sh <input directory> <output directory> <percentage of original size>'
else
	for i in $( find $1 -type d | sed 's/^..//'); do mkdir -p $2/$i; done
	for i in $( find $1 -type f | sed 's/^..//'); do convert -resize $3% $i $2/$i; done
fi


