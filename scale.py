# Script to easily scale image textures

import sys
import os
from PIL import Image

path = sys.argv[1]

images = os.listdir(path)

for image in images:
    if image.split(".",1)[1] != "png":
        images.remove(image)

size = 128, 128

for image in images:
    im = Image.open(f"{path}/{image}")
    im.thumbnail(size)
    im.save(f"{path}/{image}")