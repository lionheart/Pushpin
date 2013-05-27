#!/usr/bin/env python

from PIL import Image
from PIL import ImageDraw
import math

# Loading animation
count = 80
interval = (2 * math.pi) / count
for i in range(count):
    mask = Image.open("mask.bmp").convert('L')

    im = Image.new("RGB", (40, 40))

    box = (0, i - 15, 40, 30 + i)
    math.cos(i)

    draw = ImageDraw.Draw(im)
    draw.rectangle([(0, 0), (40, 20 + 20 * math.cos(interval * i))], fill="rgb(76, 88, 106)")
    draw.rectangle([(0, 40), (40, 20 + 20 * math.cos(interval * i))], fill="rgb(217, 224, 233)")

    im.putalpha(mask)
    im.save("../Assets/PullToRefreshAnimating/loading_{0:02d}.png".format(count - i))

    mask = Image.open("mask@2x.bmp").convert('L')

    im = Image.new("RGB", (80, 80))

    draw = ImageDraw.Draw(im)
    draw.rectangle([(0, 0), (80, 40 + 40 * math.cos(interval * i))], fill="rgb(76, 88, 106)")
    draw.rectangle([(0, 80), (80, 40 + 40 * math.cos(interval * i))], fill="rgb(217, 224, 233)")

    box = (0, i - 10, 80, 80 + i)
    im.putalpha(mask)
    im.save("../Assets/PullToRefreshAnimating/loading_{0:02d}@2x.png".format(count - i))

