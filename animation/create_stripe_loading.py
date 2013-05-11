#!/usr/bin/env python

from PIL import Image
from PIL import ImageDraw
import operator

# Loading animation
count = 20
interval = 80 / count
for i in range(count):
    mask = Image.open("mask.bmp").convert('L')

    im = Image.new("L", (40, 40))

    box = (0, i - 15, 40, 30 + i)
    im.paste(Image.open("stripes.bmp"), box)

    im.putalpha(mask)
    im.save("../Assets/PullToRefreshAnimating/loading_{0:02d}.png".format(count - i))

    mask = Image.open("mask@2x.bmp").convert('L')

    im = Image.new("L", (80, 80))

    box = (0, i - 10, 80, 80 + i)
    im.paste(Image.open("stripes@2x.bmp"), box)
    im.putalpha(mask)
    im.save("../Assets/PullToRefreshAnimating/loading_{0:02d}@2x.png".format(count - i))

