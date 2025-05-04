#!/bin/bash

cd ~/void-packages
git pull origin master
./xbps-src pkg google-chrome
sudo xbps-install --repository=hostdir/binpkgs/nonfree google-chrome