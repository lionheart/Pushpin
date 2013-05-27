#!/usr/bin/env python

from PIL import Image
from PIL import ImageDraw
import operator

color_top = (254, 254, 254)
color_bottom = (76, 88, 106)
color_difference = map(operator.sub, color_top, color_bottom)
color_difference = (178, 166, 148)
def color_for_ratio(ratio):
    return "rgb({}, {}, {})".format(*map(operator.sub, color_top, map(lambda k: int(k*ratio), color_difference)))

# PTR Animation
count = 32
interval = 80. / count
for i in range(1, count + 1):
    mask = Image.open("mask.bmp").convert('L')

    im = Image.new("RGB", (40, 40))

    draw = ImageDraw.Draw(im)
    # draw.rectangle([(0, 40 - interval * i), (40, 40)], fill=255)
    draw.rectangle([(0, 0), (40, 40)], fill=color_for_ratio(i / 32.))

    im.putalpha(mask)
    im.save("../Assets/PullToRefresh/ptr_{0:02d}.png".format(count - i))

    # Retina Images
    mask = Image.open("mask@2x.bmp").convert('L')

    im = Image.new("RGB", (80, 80))

    draw = ImageDraw.Draw(im)
    # draw.rectangle([(0, 80 - interval * i), (80, 80)], fill=255)
    # draw.rectangle([(0, 0), (80, interval * i)], fill=color_for_ratio(i / 32.))

    # change pin color based on index
    draw.rectangle([(0, 0), (80, 80)], fill=color_for_ratio(i / 32.))

    im.putalpha(mask)
    im.save("../Assets/PullToRefresh/ptr_{0:02d}@2x.png".format(count - i))

# Loading animation
count = 20
interval = 80 / count
for i in range(count):
    mask = Image.open("mask.bmp").convert('L')

    im = Image.new("L", (40, 40))

    box = (0, i - 15, 40, 30 + i)

    draw = ImageDraw.Draw(im)
    draw.rectangle([(0, 40 - interval * i), (40, 40)], fill=255)
    draw.rectangle([(0, 0), (40, interval * i)], fill=0)

    im.putalpha(mask)
    im.save("../Assets/PullToRefreshAnimating/loading_{0:02d}.png".format(count - i))

    mask = Image.open("mask@2x.bmp").convert('L')

    im = Image.new("L", (80, 80))

    draw = ImageDraw.Draw(im)
    draw.rectangle([(0, 80 - interval * i), (80, 80)], fill=255)
    draw.rectangle([(0, 0), (80, interval * i)], fill=0)

    box = (0, i - 10, 80, 80 + i)
    im.putalpha(mask)
    im.save("../Assets/PullToRefreshAnimating/loading_{0:02d}@2x.png".format(count - i))

