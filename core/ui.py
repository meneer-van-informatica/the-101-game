import pygame

def shadowed_text(font, text, color=(255, 255, 255), shadow=(0, 0, 0), offset=(2, 2)):
    base = font.render(text, True, color)
    sh = font.render(text, True, shadow)
    surf = pygame.Surface((base.get_width() + abs(offset[0]), base.get_height() + abs(offset[1])), pygame.SRCALPHA)
    surf.blit(sh, (max(0, offset[0]), max(0, offset[1])))
    surf.blit(base, (0, 0))
    return surf

def center(surface, child, y):
    x = surface.get_width() // 2 - child.get_width() // 2
    surface.blit(child, (x, y))

def soft_bg(screen, top=(14, 18, 28), bottom=(6, 8, 12)):
    w, h = screen.get_size()
    for i in range(h):
        t = i / max(1, h - 1)
        r = int(top[0] * (1 - t) + bottom[0] * t)
        g = int(top[1] * (1 - t) + bottom[1] * t)
        b = int(top[2] * (1 - t) + bottom[2] * t)
        pygame.draw.line(screen, (r, g, b), (0, i), (w, i))
