#!/usr/bin/env python

from PIL import Image
from PIL import ImageDraw

# PTR Animation
count = 32
interval = 80. / count
for i in range(count):
    mask = Image.open("mask.bmp").convert('L')

    im = Image.new("L", (40, 40))

    draw = ImageDraw.Draw(im)
    # draw.rectangle([(0, 40 - interval * i), (40, 40)], fill=255)
    draw.rectangle([(0, 0), (40, interval * i)], fill=255)

    im.putalpha(mask)
    im.save("../Assets/PullToRefresh/ptr_{0:02d}.png".format(count - i))

    # Retina Images
    mask = Image.open("mask@2x.bmp").convert('L')

    im = Image.new("L", (80, 80))

    draw = ImageDraw.Draw(im)
    # draw.rectangle([(0, 80 - interval * i), (80, 80)], fill=255)
    draw.rectangle([(0, 0), (80, interval * i)], fill=255)

    im.putalpha(mask)
    im.save("../Assets/PullToRefresh/ptr_{0:02d}@2x.png".format(count - i))

"""
# Loading animation
count = 20
for i in range(count):
    mask = Image.open("mask.bmp").convert('L')

    im = Image.new("L", (80, 79))

    box = (0, i - 10, 80, 79 + i)
    im.paste(Image.open("stripes.bmp"), box)
    im.putalpha(mask)
    im.save("loading_{0:02d}.png".format(count - i))

"""
