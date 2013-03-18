#!/usr/bin/env

"""
After running this, run

    convert -delay 10 -loop 0 image*.png animated.gif

to generate the images
"""

from PIL import Image
from PIL import ImageDraw

# PTR Animation
count = 32
interval = 80. / count
for i in range(count):
    mask = Image.open("/Users/dan/Desktop/mask.bmp").convert('L')

    im = Image.new("L", (80, 79))

    draw = ImageDraw.Draw(im)
    draw.rectangle([(0, 0), (80, interval * i)], fill=255)

    im.putalpha(mask)
    im.save("ptr_{0:02d}.png".format(count - i))

# Loading animation
count = 20
for i in range(count):
    mask = Image.open("/Users/dan/Desktop/mask.bmp").convert('L')

    im = Image.new("L", (80, 79))

    box = (0, i - 10, 80, 79 + i)
    im.paste(Image.open("/Users/dan/Desktop/stripes.png"), box)
    im.putalpha(mask)
    im.save("loading_{0:02d}.png".format(count - i))

