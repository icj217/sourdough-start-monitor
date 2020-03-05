#!/bin/bash
# Source: https://www.justinmklam.com/posts/2018/06/sourdough-starter-monitor/

# Calls 'raspistill' every 300s (ie. 5 mins) and writes the images
# to a new date/timestamped folder.

TOTAL_DELAY=300 # in seconds
CAM_DELAY=1 # need to have a nonzero delay for raspistill

# Must be 1.33 ratio
RES_W=1440
RES_H=1080

# Calculate the total delay time per cycle
SLEEP_DELAY=$(($TOTAL_DELAY-$CAM_DELAY))

FOLDER_NAME=images
mkdir -p $FOLDER_NAME # create image root folder if not exist

IDX=0 # image index

function cleanup() {
        echo "Exiting."
        exit 0
}

trap cleanup INT

while true; do
        DATE=$(date +%Y-%m-%d_%H-%M-%S)
        FNAME="${DATE}_(${IDX})" # image filename

        # Create folder for current timelapse set
        if [ $IDX -eq 0 ]
        then
                FOLDER_NAME=$FOLDER_NAME/$DATE
                mkdir -p $FOLDER_NAME
                echo "Created folder: ${FOLDER_NAME}"
        fi
        # Take image
        raspistill --nopreview -t $CAM_DELAY -o ./$FOLDER_NAME/$FNAME.jpg -w $RES_W -h $RES_H

        echo "Captured: ${FNAME}"
        IDX=$((IDX+1))
        sleep $SLEEP_DELAY
done