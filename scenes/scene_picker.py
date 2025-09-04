import json
import os
import pygame

# probeer de mooie UI; val anders terug op simpele functies
try:
    from core.ui import shadowed_text, center, soft_bg
except Exception:
    def shadowed_text(font, text, color=(255, 255, 255), shadow=(0, 0, 0), offset=(2, 2)):
        return font.render(text, True, color)
    def center(surface, child, y):
        x = surface.get_width() // 2 - child.get_width() // 2
        surface.blit(child, (x, y))
    def soft_bg(screen, top=(12, 14, 18), bottom=None):
        screen.fill(top)

def _load_titles():
    try:
        with open(os.path.join('data', 'titles.json'), 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception:
        return {
            'level_story_one':   { 'title': 'W0 • Distance Zero',     'subtitle': 'why indexing starts at 0, feel the beat' },
            'typing_ad':         { 'title': 'W1 • Type Tempo',        'subtitle': 'tap A/D in rhythm, build combos' },
            'level7_spectro_mix':{ 'title': 'W2 • Spectro Mix',       'subtitle': 'palettes, gain and speed' },
            'world_w3_machines': { 'title': 'W3 • Machine Cathedral', 'subtitle': 'finite states as music' }
        }

class ScenePicker:
    def __init__(self, services):
        self.services = services
        self.audio = services.get('audio')
        self.progress = services.get('progress')
        self.settings = services.get('settings', {})
        self.silent = services.get('silent', False)

        try:
            with open(os.path.join('data', 'worlds.json'), 'r', encoding='utf-8') as f:
                self.worlds = json.load(f) or []
        except Exception:
            self.worlds = []
        if not self.worlds:
            self.worlds = ['level_story_one', 'typing_ad', 'level7_spectro_mix', 'world_w3_machines']

        self.titles = _load_titles()
        self.index = 0
        self.next_scene = None
        self.done = False

        pygame.font.init()
        name = self.settings.get('font_name') or pygame.font.get_default_font()
        self.font_title = pygame.font.SysFont(name, 48)
        self.font_item  = pygame.font.SysFont(name, 34)
        self.font_sub   = pygame.font.SysFont(name, 22)
        self.font_hint  = pygame.font.SysFont(name, 20)

        if self.audio:
            self.audio.play_for('scene_picker')

    def _is_unlocked(self, idx: int) -> bool:
        if idx == 0:
            return True
        prev = self.worlds[idx - 1]
        return prev in self.progress.data.get('completed', [])

    def _label(self, key: str, unlocked: bool):
        meta = self.titles.get(key, {})
        title = meta.get('title', key)
        sub   = meta.get('subtitle', '')
        if not unlocked:
            title, sub = '???', ''
        return title, sub

    def handle_event(self, e):
        if e.type != pygame.KEYDOWN or not self.worlds:
            return
        if e.key in (pygame.K_RIGHT, pygame.K_d):
            self.index = (self.index + 1) % len(self.worlds)
        elif e.key in (pygame.K_LEFT, pygame.K_a):
            self.index = (self.index - 1) % len(self.worlds)
        elif e.key in (pygame.K_RETURN, pygame.K_KP_ENTER, pygame.K_SPACE):
            wid = self.worlds[self.index]
            if self._is_unlocked(self.index) or wid in self.progress.data.get('completed', []):
                self.next_scene = wid
                self.progress.data['last_scene'] = wid
        elif e.key == pygame.K_ESCAPE:
            self.next_scene = 'dev_settings'
        elif e.key == pygame.K_q:
            self.next_scene = 'QUIT'

    def update(self, dt):
        pass

    def draw(self, screen):
        soft_bg(screen)
        w, h = screen.get_size()

        title = shadowed_text(self.font_title, 'World Select (W0–W3)', (230, 240, 255))
        center(screen, title, 36)

        y = 160
        for i, key in enumerate(self.worlds):
            unlocked = self._is_unlocked(i) or key in self.progress.data.get('completed', [])
            main, sub = self._label(key, unlocked)
            col = (140, 200, 255) if i == self.index else (200, 200, 200)
            if not unlocked and i != self.index:
                col = (120, 120, 120)
            line = shadowed_text(self.font_item, main, col)
            center(screen, line, y)
            y += 40
            if sub:
                info = shadowed_text(self.font_sub, sub, (175, 185, 195))
                center(screen, info, y)
                y += 28
            y += 6

        hint = shadowed_text(self.font_hint, '←/→ or A/D select • Enter start • Esc settings • Q quit • F11 fullscreen', (210, 220, 230))
        center(screen, hint, h - 54)
