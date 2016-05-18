#!/bin/bash
echo "deb http://packages.bw-fla.uni-freiburg.de/ trusty bwfla" > /etc/apt/sources.list.d/bwfla.list
echo -e "Package: *\nPin: release c=bwfla\nPin-Priority: 1001" > /etc/apt/preferences.d/pin-bwfla.pref


