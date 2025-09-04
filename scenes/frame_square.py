# scenes/frame_square.py
import pygame

class FrameSquare:
    """
    Witte achtergrond met een zwart vierkant in het midden.
    Klik (links) op het vierkant => markeer als 'done'.
    Snapshot werkt zonder input.
    """
    def __init__(self, services: dict):
        self.services = services
        self.done = False
        self.next_scene = None
        self._square_px = 240

    def _square_rect(self):
        surf = pygame.display.get_surface()
        w, h = surf.get_size() if surf else (1280, 720)
        s = self._square_px
        return pygame.Rect((w - s)//2, (h - s)//2, s, s)

    def handle_event(self, e: pygame.event.Event):
        if e.type == pygame.MOUSEBUTTONDOWN and e.button == 1:
            if self._square_rect().collidepoint(e.pos):
                self.done = True
                self.next_scene = 'scene_picker'

    def update(self, dt: float):
        pass

    def draw(self, screen: pygame.Surface):
        screen.fill((255, 255, 255))
        pygame.draw.rect(screen, (0,0,0), self._square_rect())
        try:
            font = pygame.font.SysFont("consolas", 26)
        except Exception:
            font = pygame.font.Font(None, 26)
        txt = font.render("FrameSquare: click the black square", True, (60,60,60))
        screen.blit(txt, (40, screen.get_height() - 60))

    def on_snapshot(self, screen: pygame.Surface, when="final"):
        self.draw(screen)
