#!/bin/bash
# # Source: https://www.justinmklam.com/posts/2018/06/sourdough-starter-monitor/

# Convenience script to run the monitor from home directory and launch
# in background

cd sourdough-starter-monitor

# Start in background so ssh session can be closed
nohup ./timelapse.sh &> /dev/null &