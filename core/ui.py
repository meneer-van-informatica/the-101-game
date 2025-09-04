import pygame

def gradient_bg(screen, top=(18,22,30), bottom=(6,8,12)):
    w, h = screen.get_size()
    for i in range(h):
        t = i / max(1, h-1)
        c = (
            int(top[0]*(1-t) + bottom[0]*t),
            int(top[1]*(1-t) + bottom[1]*t),
            int(top[2]*(1-t) + bottom[2]*t),
        )
        pygame.draw.line(screen, c, (0,i), (w,i))

def rounded_rect(surf, rect, color, radius=8, width=0):
    pygame.draw.rect(surf, color, rect, width=width, border_radius=radius)

def panel(surf, rect, fill=(28,32,44), border=(60,66,84), shadow=(0,0,0,120), radius=10):
    # soft shadow
    shadow_surf = pygame.Surface((rect.w+20, rect.h+20), pygame.SRCALPHA)
    pygame.draw.rect(shadow_surf, shadow, shadow_surf.get_rect(), border_radius=radius+6)
    surf.blit(shadow_surf, (rect.x-10, rect.y-6))
    # fill + border
    rounded_rect(surf, rect, fill, radius=radius)
    rounded_rect(surf, rect, border, radius=radius, width=2)

def glow_rect(surf, rect, color=(140,200,255), strength=4, radius=8):
    g = pygame.Surface((rect.w, rect.h), pygame.SRCALPHA)
    rounded_rect(g, g.get_rect(), (*color, 60), radius=radius)
    for i in range(strength):
        surf.blit(g, rect.topleft)

def center_text(surf, font, text, color, y):
    t = font.render(text, True, color)
    surf.blit(t, (surf.get_width()//2 - t.get_width()//2, y))
    return t.get_width(), t.get_height()

def label(surf, font, text, color, pos):
    t = font.render(text, True, color)
    surf.blit(t, pos)
    return t.get_size()
