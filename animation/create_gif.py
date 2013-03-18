#!/usr/bin/env

from PIL import Image
from PIL import ImageDraw

count = 32
interval = 80. / count
for i in range(count):
    mask = Image.open("/Users/dan/Desktop/mask.bmp").convert('L')

    im = Image.new("L", (80, 79))

    draw = ImageDraw.Draw(im)
    draw.rectangle([(0, 0), (80, interval * i)], fill=255)

    im.putalpha(mask)
    im.save("image{0:02d}.png".format(count - i))

