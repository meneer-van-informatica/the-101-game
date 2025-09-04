import pygame


class DevSettings:
    def __init__(self, services):
        self.services = services
        self.audio = services.get('audio')
        self.font = pygame.font.SysFont(services.get('settings', {}).get('font_name', None) or pygame.font.get_default_font(), 32)
        self.next_scene = None
        self.done = False

    def handle_event(self, e):
        if e.type == pygame.KEYDOWN:
            if e.key in (pygame.K_m, pygame.K_SPACE):
                if self.audio:
                    self.audio.toggle_music()
            elif e.key in (pygame.K_ESCAPE, pygame.K_RETURN):
                self.next_scene = 'scene_picker'

    def update(self, dt):
        pass

    def draw(self, screen):
        screen.fill((20, 20, 20))
        lines = [
            'Developer Settings',
            '',
            'M/Space: toggle music',
            'Esc/Enter: back to menu'
        ]
        y = 100
        for line in lines:
            surf = self.font.render(line, True, (255, 255, 255))
            screen.blit(surf, (50, y))
            y += 40
