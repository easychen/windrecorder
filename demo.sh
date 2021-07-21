#! /bin/bash

# change dd.ftqq.com to internal IP

docker run --rm -p 80:80 -p 5900:5900 -v "$(pwd):/data" easychen/windrec:latest  'http://dd.ftqq.com:3000/'