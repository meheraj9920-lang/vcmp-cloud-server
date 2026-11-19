#!/bin/bash
cd /workspaces/vcmp-cloud-server
export WINEPREFIX=/home/codespace/.wine64
export WINEARCH=win64
xvfb-run -a wine64 server64.exe >> /workspaces/vcmp-cloud-server/server.log 2>&1
