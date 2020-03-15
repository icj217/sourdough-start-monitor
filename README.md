# Sourdough Start Monitor

Inspired by Justin Lam's post [here](https://www.justinmklam.com/posts/2018/06/sourdough-starter-monitor/).

Mono-repository for all things necessary to support the project.

## Repository Structure

The repo is broken into directories with separate areas of concern:
* `scripts` - shell scripts that are meant to be run on the Pi
* `backend` - Serverless project that deploys AWS resources to process images
* `frontend` - Website that is displayed on Pi to show timelapse

## Raspberry Pi Configuration

The following configurations were made to the Raspberry Pi:
* Cloned git repo into `Repositories` folder within home dir
* Bootstrapped `awscli` with credentials for both `pi` and `root` users
* Modified `/etc/rc.local` file start timelapse capture, i.e.
    ```bash
    S3_BUCKET_NAME=my-bucket-name nohup /home/pi/Repositories/sourdough-starter-monitor/scripts/timelapse.sh &> /dev/null &
    ```
* Modified `/etc/xdg/lxsession/LXDE-pi/autostart` to open browser on startup i.e.
    ```bash
    @chromium-browser --kiosk /home/pi/Repositories/sourdough-starter-monitor/frontend/index.html
    ```