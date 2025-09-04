import pygame


class WorldW3Machines:
    def __init__(self, services):
        self.services = services
        self.audio = services.get('audio')
        self.progress = services.get('progress')
        self.settings = services.get('settings', {})
        self.font = pygame.font.SysFont(self.settings.get('font_name', None) or pygame.font.get_default_font(), 32)
        self.state = 'q0'
        self.next_scene = None
        self.done = False
        if self.audio:
            self.audio.play_for('world_w3_machines')

    def handle_event(self, e):
        if e.type == pygame.KEYDOWN:
            if e.key == pygame.K_a and self.state == 'q0':
                self.state = 'q1'
            elif e.key == pygame.K_b and self.state == 'q1':
                self.state = 'q2'
            elif e.key in (pygame.K_RETURN, pygame.K_SPACE) and self.state == 'q2':
                self.next_scene = 'scene_picker'
                self.progress.mark_complete('world_w3_machines')

    def update(self, dt):
        pass

    def draw(self, screen):
        screen.fill((30, 10, 40))
        lines = [
            'World W3 Machines',
            f'State: {self.state}',
            'A: q0q1, B: q1q2, Enter: back in q2'
        ]
        y = 200
        for line in lines:
            surf = self.font.render(line, True, (255, 200, 255))
            screen.blit(surf, (80, y))
            y += 40
