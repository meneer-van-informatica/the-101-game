import pygame


class Level7SpectroMix:
    def __init__(self, services):
        self.services = services
        self.audio = services.get('audio')
        self.progress = services.get('progress')
        self.settings = services.get('settings', {})
        self.font = pygame.font.SysFont(self.settings.get('font_name', None) or pygame.font.get_default_font(), 32)
        self.palette = 0
        self.gain = 0.5
        self.speed = 0.5
        self.next_scene = None
        self.done = False
        if self.audio:
            self.audio.play_for('level7_spectro_mix')

    def handle_event(self, e):
        if e.type == pygame.KEYDOWN:
            if e.key in (pygame.K_LEFT, pygame.K_a):
                self.palette = (self.palette - 1) % 3
            elif e.key in (pygame.K_RIGHT, pygame.K_d):
                self.palette = (self.palette + 1) % 3
            elif e.key in (pygame.K_UP, pygame.K_w):
                self.gain = min(1.0, self.gain + 0.1)
            elif e.key in (pygame.K_DOWN, pygame.K_s):
                self.gain = max(0.0, self.gain - 0.1)
            elif e.key in (pygame.K_RETURN, pygame.K_SPACE):
                self.next_scene = 'scene_picker'
                self.progress.mark_complete('level7_spectro_mix')

    def update(self, dt):
        pass

    def draw(self, screen):
        screen.fill((10, 30, 30))
        lines = [
            'Level 7 Spectro Mix',
            f'Palette: {self.palette}',
            f'Gain: {self.gain:.1f}',
            f'Speed: {self.speed:.1f}',
            'Use arrows/AWSD. Enter to return.'
        ]
        y = 180
        for line in lines:
            surf = self.font.render(line, True, (200, 255, 200))
            screen.blit(surf, (80, y))
            y += 40
