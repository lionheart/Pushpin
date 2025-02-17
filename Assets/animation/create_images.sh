#!/bin/bash

python create_images.py
convert -delay 0 -loop 0 ptr_*.png ptr.gif
convert -delay 0 -loop 0 loading_*.png loading.gif

