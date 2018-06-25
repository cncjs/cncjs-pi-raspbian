# cncjs-pi-raspbian

Raspberry PI distribution of CNCjs in a ready to deploy image. Includes some useful script and documentation.

CNCjs on Raspberry Pi w/ Raspbian
=================================

![CNCjs logo](https://cloud.githubusercontent.com/assets/447801/24392019/aa2d725e-13c4-11e7-9538-fd5f746a2130.png)

A [Raspberry Pi](http://www.raspberrypi.org/) distribution for CNCjs user to get started quickly. It includes the [CNCjs](https://github.com/cncjs/cncjs) software for out of the box functionality, [mjpg-streamer with RaspiCam support](https://github.com/jacksonliam/mjpg-streamer) for live viewing, and [FFmpeg](https://www.ffmpeg.org/) for recording. Several Pendants and Web UI's are also included. For a more complete introduction, see the [CNCjs Introduction](https://github.com/cncjs/cncjs/wiki/Introduction) section of the wiki page. All primary documentation still resides in the [CNCjs Wiki](https://github.com/cncjs/cncjs/wiki).


## Getting Started

This resource explains how to install a Raspberry Pi operating system image on an SD card. You will need another computer with an SD card reader to install the image, and use the web interface.

### Download Image

Download the pre-built image(s) from this [reposities release](https://github.com/cncjs/cncjs-pi-raspbian/releases) page.

### Write Image to SD

You will need to use an image writing tool to install the image you have downloaded on your SD card.

[Etcher](https://etcher.io/) is a graphical SD card writing tool that works on Mac OS, Linux and Windows, and is the easiest option for most users. Etcher also supports writing images directly from the zip file, without any unzipping required. 

#### To write your image with Etcher:

 - Download [Etcher](https://etcher.io/) and install it.
 - Connect an SD card reader with the SD / Micro SD card inside.
 - Open Etcher and select from your hard drive the Raspberry Pi `.img` or `.zip` file you wish to write to the SD card.
 - Select the SD card you wish to write your image to.
 - Review your selections and click 'Flash!' to begin writing data to the SD card.
 - For more advanced control of this process, see the raspberrypi.org system-specific guides:
	 - [Linux](https://www.raspberrypi.org/documentation/installation/installing-images/linux.md)
	 - [Mac OS](https://www.raspberrypi.org/documentation/installation/installing-images/mac.md)
	 - [Windows](https://www.raspberrypi.org/documentation/installation/installing-images/windows.md)

If you're not using Etcher, you'll need to unzip .zip downloads to get the image file (.img) to write to your SD card.

### Usage

Once the iamge is installed, the Raspberry Pi is booted, and connected to your network.

On a seperate computer.

 - Navigate to [http://cncjs/](http://cncjs/).
 - Load the perbuilt Workspace. (Optional)
	- Download [cncjs-app-1.9.15.json](https://github.com/cncjs/cncjs-pi-raspbian/blob/master/cncjs-app-1.9.15.json)
	- In CNCjs, go to Settings > Workspace
	- Import the downloaded workspace.
- SSH into the Raspberry Pi with a terminal enulator, or tool like [Putty](https://www.putty.org/).
	- Run `sudo raspi-config` and make any needed change.

## Build Notes

The main source of documentation regarding CNCjs is the [CNCjs Wiki](https://github.com/cncjs/cncjs/wiki).
This repository contains some additional notes, documenation, and source script to generate this raspbian distribution with CNCjs out of an existing [Raspbian](http://www.raspbian.org/) distro image.

Image made with/using [Raspbain Stretch Light](https://www.raspberrypi.org/downloads/raspbian/), [Linux Data Dumping](https://beebom.com/how-clone-raspberry-pi-sd-card-windows-linux-macos/), [PiShrink](https://github.com/Drewsif/PiShrink).

#### Preinstalled Pendants

 - [cncjs-pendant-raspi-gpio](https://github.com/cncjs/cncjs-pendant-raspi-gpio) - Simple Raspberry Pi GPIO Pendant control for CNCjs.

#### Preinstalled Tablet UI

 - [cncjs-pendant-tinyweb](https://github.com/cncjs/cncjs-pendant-tinyweb) - A tiny web console for small 320x240 LCD display.<br>
    ![cncjs-pendant-tinyweb](https://raw.githubusercontent.com/cncjs/cncjs/master/media/tinyweb-axes.png)
 - [cncjs-shopfloor-tablet](https://github.com/cncjs/cncjs-shopfloor-tablet) - A simplified UI for cncjs optimized for tablet computers in a production (shop floor) environment.<br>
    ![cncjs-shopfloor-tablet](https://user-images.githubusercontent.com/4861133/33970662-4a8244b2-e018-11e7-92ab-5a379e3de461.PNG)
