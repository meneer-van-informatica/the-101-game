import time
from PIL import Image
import hue
import os

def show_frame():
    # Toon de PNG-beelden (importeren)
    img_path = os.path.join('scenes', 'scene0.png')  # Verwijst naar de scene0.png
    img = Image.open(img_path)
    img.show()

    # Zet de HUE-lampen in het huis naar rood
    hue.set_all_lights_color('red')

    print('This is frame 0: "Hallo mama"')

    # Wacht op Enter om verder te gaan naar frame 1
    input('Press Enter to go to frame 1...')
    go_to_frame_1()

def go_to_frame_1():
    # Laad frame 1 automatisch
    import frame1
    frame1.show_frame()