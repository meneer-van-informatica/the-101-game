# scenes/w0_f3.py
import pygame

class W0F3Outro:
    """
    Simpele outro/overgang. ENTER → terug naar menu (of pas 'next_scene' aan).
    """
    def __init__(self, services: dict):
        self.services = services
        self.done = False
        self.next_scene = None
        self.t = 0.0

    def handle_event(self, e):
        if e.type == pygame.KEYDOWN:
            if e.key in (pygame.K_RETURN, pygame.K_SPACE):
                self.done = True; self.next_scene = 'scene_picker'
            elif e.key == pygame.K_ESCAPE:
                self.done = True; self.next_scene = 'scene_picker'

    def update(self, dt): self.t += dt

    def draw(self, screen):
        w,h = screen.get_size()
        screen.fill((0,0,0))
        try: big = pygame.font.SysFont('consolas', 68); small = pygame.font.SysFont('consolas', 28)
        except: big = pygame.font.Font(None, 68); small = pygame.font.Font(None, 28)
        msg = big.render("W0 — Nice!", True, (235,235,250))
        sub = small.render("Press Enter to continue", True, (180,180,190))
        screen.blit(msg,  (w//2 - msg.get_width()//2,  h//2 - 40))
        screen.blit(sub,  (w//2 - sub.get_width()//2,  h//2 + 30))

    def on_snapshot(self, screen, when='final'):
        self.draw(screen)
