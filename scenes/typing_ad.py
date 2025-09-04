import pygame


class TypingAD:
    def __init__(self, services):
        self.services = services
        self.audio = services.get('audio')
        self.progress = services.get('progress')
        self.settings = services.get('settings', {})
        self.font = pygame.font.SysFont(self.settings.get('font_name', None) or pygame.font.get_default_font(), 32)
        self.count = 0
        self.target = 10
        self.next_scene = None
        self.done = False
        if self.audio:
            self.audio.play_for('typing_ad')

    def handle_event(self, e):
        if e.type == pygame.KEYDOWN:
            if e.key in (pygame.K_a, pygame.K_d):
                self.count += 1
            elif e.key in (pygame.K_RETURN, pygame.K_SPACE) and self.count >= self.target:
                self.next_scene = 'scene_picker'
                self.progress.mark_complete('typing_ad')

    def update(self, dt):
        pass

    def draw(self, screen):
        screen.fill((20, 20, 40))
        lines = [
            'Typing AD',
            f'Press A or D: {self.count}/{self.target}',
            'Enter when done.'
        ]
        y = 200
        for line in lines:
            surf = self.font.render(line, True, (255, 255, 255))
            screen.blit(surf, (100, y))
            y += 40
