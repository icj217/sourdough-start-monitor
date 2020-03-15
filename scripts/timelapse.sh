#!/bin/bash
# Source: https://www.justinmklam.com/posts/2018/06/sourdough-starter-monitor/

# Calls 'raspistill' every 300s (ie. 5 mins) and writes the images
# to a new date/timestamped folder.

TOTAL_DELAY=300 # in seconds
CAM_DELAY=1 # need to have a nonzero delay for raspistill

# Must be 1.33 ratio
RES_W=1080
RES_H=1440

# Camera is mounted off-axis
ROTATE=270

# Calculate the total delay time per cycle
SLEEP_DELAY=$(($TOTAL_DELAY-$CAM_DELAY))

FOLDER_NAME=/srv/images/sourdough

IDX=0 # image index

function cleanup() {
        echo "Exiting."
        exit 0
}

trap cleanup INT

while true; do
        DATE=$(date +%Y-%m-%d)
        TS=$(date +%Y-%m-%d_%H-%M-%S)
        FNAME="${TS}.jpg" # image filename

        # Create folder for current timelapse set
        if [ $IDX -eq 0 ]
        then
                mkdir -p $FOLDER_NAME
                echo "Created folder: ${FOLDER_NAME}"
        fi
        # Take image
        raspistill --nopreview \
                -t $CAM_DELAY \
                -o $FOLDER_NAME/$FNAME \
                -w $RES_W -h $RES_H \
                -rot $ROTATE \
                -cfx 128:128 \ # Greyscale
                --annotate 12 --annotateex 64 # Add date/time in 64px
        echo "Captured: ${FNAME}"

        # Upload to S3
        aws s3 cp --only-show-errors $FOLDER_NAME/${FNAME} s3://${S3_BUCKET_NAME}/raw/${FNAME}

        # Delete images older than 24 hours
        find $FOLDER_NAME -type f -mtime 1 -exec rm -f {} \;

        IDX=$((IDX+1))
        sleep $SLEEP_DELAY
done
