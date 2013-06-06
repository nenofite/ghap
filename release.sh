#!/bin/sh

rm -r dist/
rsync -t ghap.html ghap.js ghap.css *.png dist/
rsync -t achv/*.png dist/achv/
