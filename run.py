import sys
import os

# Voeg de root directory toe aan sys.path zodat de modules in 'scenes' en 'frames' kunnen worden geïmporteerd
sys.path.append(os.path.abspath(os.path.dirname(__file__)))

# Nu kunnen we de modules importeren
import scenes.scene0

if __name__ == "__main__":
    scenes.scene0.start()
