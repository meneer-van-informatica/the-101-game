import pygame

class TypingAD:
    wants_beat = True  # laat de metronoom lopen voor ritmegevoel

    def __init__(self, services):
        self.services = services
        self.audio = services.get("audio")
        self.progress = services.get("progress")
        self.settings = services.get("settings", {})
        self.font = pygame.font.SysFont(self.settings.get("font_name", None) or pygame.font.get_default_font(), 32)
        self.count = 0
        self.target = 10
        self.next_scene = None
        self.done = False
        if self.audio:
            self.audio.play_for("typing_ad")

    def handle_event(self, e):
        if e.type == pygame.KEYDOWN:
            if e.key in (pygame.K_a,):
                self.count += 1
                # speel hat/kick als aanwezig
                try:
                    if self.audio: self.audio.play_sfx("hat")
                except Exception:
                    pass
            elif e.key in (pygame.K_d,):
                self.count += 1
                try:
                    if self.audio: self.audio.play_sfx("snare")
                except Exception:
                    pass
            elif e.key in (pygame.K_RETURN, pygame.K_SPACE) and self.count >= self.target:
                self.progress.mark_complete("typing_ad")
                self.next_scene = "scene_picker"
            elif e.key == pygame.K_ESCAPE:
                # direct terug naar hoofdscherm, zonder te voltooien
                self.next_scene = "scene_picker"

    def update(self, dt):
        pass

    def draw(self, screen):
        screen.fill((20, 20, 40))
        lines = [
            "W1 • Type Tempo",
            f"Tap A or D: {self.count}/{self.target}",
            "Enter when ready • Esc to menu"
        ]
        y = 200
        for line in lines:
            surf = self.font.render(line, True, (255, 255, 255))
            screen.blit(surf, (100, y))
            y += 40
