import pygame, os

class W0F0Square:
    """
    W0 • F0: wit ↔ zwart toggle.
    - Linker muisklik (of SPATIE/ENTER) binnen het vierkant: kleuren flippen
    - Rechter muisklik (of ESC): frame verlaten (naar scene_picker)
    Snapshot rendert gewoon de huidige toestand.
    """
    def __init__(self, services: dict):
        self.services = services
        self.done = False
        self.next_scene = None
        self._side = 240
        self.inverted = False  # False = wit bg / zwart vierkant; True = zwart bg / wit vierkant

        # Fast-forward shots via --start ondersteunen (optioneel)
        if os.getenv("KM_SHOT","").strip() == "1":
            self.done = True  # dan is de “laatste frame” meteen de getekende toestand

    def _rect(self, screen: pygame.Surface) -> pygame.Rect:
        w, h = screen.get_width(), screen.get_height()
        s = self._side
        return pygame.Rect((w - s)//2, (h - s)//2, s, s)

    def _toggle(self):
        self.inverted = not self.inverted

    def handle_event(self, e: pygame.event.Event):
        if e.type == pygame.KEYDOWN:
            if e.key in (pygame.K_SPACE, pygame.K_RETURN):
                self._toggle()
            elif e.key == pygame.K_ESCAPE:
                self.done = True
                self.next_scene = 'scene_picker'

        elif e.type == pygame.MOUSEBUTTONDOWN:
            rect = self._rect(pygame.display.get_surface())
            if e.button == 1 and rect.collidepoint(e.pos):  # links: toggle
                self._toggle()
            elif e.button == 3 and rect.collidepoint(e.pos):  # rechts: exit
                self.done = True
                self.next_scene = 'scene_picker'

    def update(self, dt: float):
        pass

    def draw(self, screen: pygame.Surface):
        if self.inverted:
            bg, fg = (0, 0, 0), (255, 255, 255)
        else:
            bg, fg = (255, 255, 255), (0, 0, 0)

        screen.fill(bg)
        pygame.draw.rect(screen, fg, self._rect(screen))

        try:
            font = pygame.font.SysFont('consolas', 26)
        except Exception:
            font = pygame.font.Font(None, 26)

        hint = "L-click/Space/Enter: flip • R-click/ESC: exit"
        cap = font.render(f'W0 • F0 — {hint}', True, (160,160,160) if self.inverted else (60,60,60))
        screen.blit(cap, (40, screen.get_height()-60))

    def on_snapshot(self, screen: pygame.Surface, when='final'):
        self.draw(screen)
