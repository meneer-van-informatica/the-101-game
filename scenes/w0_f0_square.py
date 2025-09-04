import os, math
import pygame
from array import array


class W0F0Square:
    def __init__(self, services: dict):
        self.services = services
        self.done = False
        self.next_scene = None
        self._side = 240
        self.inverted = False
        self._rate = 44100
        self.flips = 0
        self.goal  = 30
        self._sfx_cache: dict[tuple[int,int], pygame.mixer.Sound] = {}
        if os.getenv("KM_SHOT","").strip() == "1":
            self.done = True

    def _rect(self, screen: pygame.Surface) -> pygame.Rect:
        w, h = screen.get_width(), screen.get_height()
        s = self._side
        return pygame.Rect((w - s)//2, (h - s)//2, s, s)

    # ---------- audio ----------
    def _tone(self, freq: int, ms: int = 120):
        try:
            if not pygame.mixer.get_init():
                return None
        except Exception:
            return None
        key = (int(freq), int(ms))
        snd = self._sfx_cache.get(key)
        if snd: return snd
        rate = self._rate
        length = int(rate * (ms/1000.0))
        amp = 16000
        buf = array("h")
        two_pi_f = 2.0 * math.pi * freq
        for n in range(length):
            buf.append(int(amp * math.sin(two_pi_f * (n / rate))))
        try:
            snd = pygame.mixer.Sound(buffer=buf.tobytes())
        except TypeError:
            snd = pygame.mixer.Sound(buffer=bytes(buf))
        self._sfx_cache[key] = snd
        return snd

    def _bleep(self, kind: str):
        a = self.services.get("audio") if isinstance(self.services, dict) else None
        if a and hasattr(a, "play_sfx"):
            try:
                a.play_sfx(kind)
                return
            except Exception:
                pass
        if kind == "click":   f, d = 660, 110
        elif kind == "key":   f, d = 880, 120
        else:                 f, d = 330, 150
        s = self._tone(f, d)
        if s:
            try: s.play()
            except Exception: pass

    # ---------- logic ----------
    def _toggle(self):
        self.inverted = not self.inverted
        self.flips += 1
        if self.flips >= self.goal:
            self.done = True
            self.next_scene = 'w0_f1'


    def handle_event(self, e: pygame.event.Event):
        if e.type == pygame.KEYDOWN:
            # Space, Enter (hoofdtoets) en numpad Enter
            if e.key in (pygame.K_SPACE, pygame.K_RETURN, pygame.K_KP_ENTER):
                self._toggle()
                self._bleep("key")
            # Esc of Backspace = exit
            elif e.key in (pygame.K_ESCAPE, pygame.K_BACKSPACE):
                self._bleep("exit")
                self.done = True
                self.next_scene = 'scene_picker'

        elif e.type == pygame.MOUSEBUTTONDOWN:
            rect = self._rect(pygame.display.get_surface())
            inside = rect.collidepoint(e.pos)
            if e.button == 1 and inside:      # left click → flip
                self._toggle()
                self._bleep("click")
            elif e.button == 3 and inside:    # right click → exit
                self._bleep("exit")
                self.done = True
                self.next_scene = 'scene_picker'

    def update(self, dt: float):
        pass

    def draw(self, screen: pygame.Surface):
        if self.inverted:
            bg, fg = (0,0,0), (255,255,255)
        else:
            bg, fg = (255,255,255), (0,0,0)
        screen.fill(bg)
        pygame.draw.rect(screen, fg, self._rect(screen))
        try:
            font = pygame.font.SysFont('consolas', 26)
        except Exception:
            font = pygame.font.Font(None, 26)
        hint = "L-click/Space/Enter: flip • R-click/ESC/Bksp: exit"
        cap_col = (160,160,160) if self.inverted else (60,60,60)
        screen.blit(font.render(f'W0 • F0 — {hint}', True, cap_col), (40, screen.get_height()-60))
        try: font2 = pygame.font.SysFont('consolas', 32)
        except: font2 = pygame.font.Font(None, 32)
        counter = font2.render(f"{self.flips}/{self.goal}", True, (120,120,200))
        screen.blit(counter, (20, 20))


    def on_snapshot(self, screen: pygame.Surface, when='final'):
        self.draw(screen)

    
