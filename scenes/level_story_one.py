import math
import time
import pygame


# ---------- helpers ----------

def _soft_bg(screen, top=(20, 24, 32), bottom=(8, 10, 14)):
    w, h = screen.get_size()
    for i in range(h):
        t = i / max(1, h - 1)
        r = int(top[0] * (1 - t) + bottom[0] * t)
        g = int(top[1] * (1 - t) + bottom[1] * t)
        b = int(top[2] * (1 - t) + bottom[2] * t)
        pygame.draw.line(screen, (r, g, b), (0, i), (w, i))


def _draw_dog(surface, center, t, blink_phase=False):
    """Eenvoudige cartoondog met kwispelstaart en knipperogen (geen assets nodig)."""
    cx, cy = center
    # Kleuren
    fur = (198, 162, 110)
    ear = (168, 132, 90)
    nose = (40, 40, 40)
    collar = (220, 60, 60)
    white = (245, 245, 245)
    black = (20, 20, 20)

    s = 1.0
    body_w, body_h = int(280*s), int(150*s)
    head_r = int(70*s)
    leg_w, leg_h = int(28*s), int(70*s)

    # Body
    body_rect = pygame.Rect(0, 0, body_w, body_h)
    body_rect.center = (cx, cy + 40)
    pygame.draw.ellipse(surface, fur, body_rect)

    # Staart (wag)
    wag = math.radians(18) * math.sin(t * 6.0)
    tail_len = int(120*s)
    tail_base = (body_rect.right - int(20*s), body_rect.centery - int(20*s))
    tail_end = (
        int(tail_base[0] + tail_len * math.cos(wag)),
        int(tail_base[1] + tail_len * math.sin(wag)),
    )
    pygame.draw.line(surface, fur, tail_base, tail_end, int(14*s))
    tip = (int(tail_end[0] + 12 * math.cos(wag)), int(tail_end[1] + 12 * math.sin(wag)))
    pygame.draw.circle(surface, fur, tip, int(10*s))

    # Poten
    for dx in (-body_w//4, -body_w//8, body_w//8, body_w//4):
        leg = pygame.Rect(0, 0, leg_w, leg_h)
        leg.midtop = (body_rect.centerx + dx, body_rect.bottom - int(10*s))
        pygame.draw.rect(surface, fur, leg, border_radius=int(8*s))

    # Hoofd
    head_center = (body_rect.left + int(60*s), body_rect.top - int(10*s))
    pygame.draw.circle(surface, fur, head_center, head_r)

    # Oren
    left_ear = [(head_center[0] - int(30*s), head_center[1] - int(50*s)),
                (head_center[0] - int(10*s), head_center[1] - int(10*s)),
                (head_center[0] - int(60*s), head_center[1] - int(10*s))]
    right_ear = [(head_center[0] + int(30*s), head_center[1] - int(50*s)),
                 (head_center[0] + int(10*s), head_center[1] - int(10*s)),
                 (head_center[0] + int(60*s), head_center[1] - int(10*s))]
    pygame.draw.polygon(surface, ear, left_ear)
    pygame.draw.polygon(surface, ear, right_ear)

    # Snuit
    muzzle = pygame.Rect(0, 0, int(80*s), int(46*s))
    muzzle.midleft = (head_center[0] + int(10*s), head_center[1] + int(10*s))
    pygame.draw.ellipse(surface, white, muzzle)

    # Neus
    nose_pos = (muzzle.right - int(12*s), muzzle.centery)
    pygame.draw.circle(surface, nose, nose_pos, int(6*s))

    # Ogen
    eye_y = head_center[1] - int(10*s)
    eye_dx = int(22*s)
    if blink_phase:
        pygame.draw.line(surface, black, (head_center[0]-eye_dx-8, eye_y), (head_center[0]-eye_dx+8, eye_y), 2)
        pygame.draw.line(surface, black, (head_center[0]+eye_dx-8, eye_y), (head_center[0]+eye_dx+8, eye_y), 2)
    else:
        pygame.draw.circle(surface, black, (head_center[0] - eye_dx, eye_y), int(5*s))
        pygame.draw.circle(surface, black, (head_center[0] + eye_dx, eye_y), int(5*s))

    # Halsband
    band = pygame.Rect(0, 0, int(140*s), int(14*s))
    band.center = (head_center[0], head_center[1] + int(30*s))
    pygame.draw.rect(surface, collar, band, border_radius=6)


# ---------- scene ----------

class LevelStoryOne:
    """
    W0 • Distance Zero
    Intro: hond, Enter start
    Film: 5x knipper — zwart/witte '0' ↔ wit/zwarte '1'
    """
    wants_beat = True  # metronoom aan voor de intro

    def __init__(self, services):
        self.services = services
        self.audio = services.get('audio')
        self.progress = services.get('progress')
        self.settings = services.get('settings', {})
        self.silent = services.get('silent', False)

        pygame.font.init()
        name = self.settings.get('font_name') or pygame.font.get_default_font()
        self.font_title = pygame.font.SysFont(name, 48)
        self.font_sub   = pygame.font.SysFont(name, 24)
        self.font_hint  = pygame.font.SysFont(name, 20)
        self.font_big   = pygame.font.SysFont(name, 220, bold=True)

        # state
        self.mode = 'intro'     # 'intro' -> 'film' -> 'done'
        self.t = 0.0
        self.next_scene = None
        self.done = False

        # film parameters
        self.blinks_total = 5
        self.blinks_done = 0
        self.phase = 'zero'     # 'zero' (zwart/0) of 'one' (wit/1)
        self.timer = 0.0
        self.dur_zero = 0.35    # seconden per fase
        self.dur_one  = 0.15
        self.hold_end = 0.75    # houd de laatste 'one' nog even in beeld

        if self.audio:
            self.audio.play_for('level_story_one')

        self._sfx_click = 'click'  # optioneel

    # ---- event ----

    def handle_event(self, e):
        if e.type == pygame.KEYDOWN:
            if self.mode == 'intro':
                if e.key in (pygame.K_RETURN, pygame.K_SPACE):
                    # start film
                    self.mode = 'film'
                    self.t = 0.0
                    self.timer = 0.0
                    self.blinks_done = 0
                    # beat ook in film
                    self.__class__.wants_beat = True
                    if self.audio:
                        try:
                            self.audio.play_sfx(self._sfx_click)
                        except Exception:
                            pass
                elif e.key == pygame.K_ESCAPE:
                    self.next_scene = 'scene_picker'
            elif self.mode == 'film':
                if e.key == pygame.K_ESCAPE:
                    # overslaan
                    self.finish()

    # ---- update/draw ----

    def update(self, dt):
        self.t += dt
        if self.mode == 'film':
            self.timer += dt
            if self.phase == 'zero' and self.timer >= self.dur_zero:
                # knippermoment: ga naar ONE en tel één blink
                self.phase = 'one'
                self.timer = 0.0
                self.blinks_done += 1
            elif self.phase == 'one' and self.timer >= self.dur_one:
                # terug naar ZERO, tenzij we klaar zijn
                if self.blinks_done >= self.blinks_total:
                    # houd eindframe nog even vast en eindig
                    if self.timer >= self.dur_one + self.hold_end:
                        self.finish()
                    # anders niets; blijf 'one' tonen
                else:
                    self.phase = 'zero'
                    self.timer = 0.0

    def draw(self, screen):
        w, h = screen.get_size()

        if self.mode == 'intro':
            _soft_bg(screen)
            # titel
            title = self.font_title.render('W0 • Distance Zero', True, (230, 240, 255))
            screen.blit(title, (w//2 - title.get_width()//2, 48))
            sub = self.font_sub.render('why indexing starts at 0 — feel the beat', True, (190, 200, 210))
            screen.blit(sub, (w//2 - sub.get_width()//2, 48 + 44))

            # hond
            blink = (int(self.t * 2.5) % 6 == 0) and (self.t % 1.0 < 0.12)
            _draw_dog(screen, (w//2, h//2 + 30), self.t, blink_phase=blink)

            # hint
            pulse = 0.5 + 0.5 * math.sin(self.t * 3.0)
            c = int(180 + 60 * pulse)
            hint = self.font_hint.render('Press Enter to play • Esc to menu', True, (c, c, c))
            screen.blit(hint, (w//2 - hint.get_width()//2, h - 64))

        elif self.mode == 'film':
            if self.phase == 'zero':
                screen.fill((0, 0, 0))
                text = self.font_big.render('0', True, (255, 255, 255))
            else:
                screen.fill((255, 255, 255))
                text = self.font_big.render('1', True, (0, 0, 0))
            screen.blit(text, (w//2 - text.get_width()//2, h//2 - text.get_height()//2))

        else:
            # done-state (zou kort zijn)
            screen.fill((0, 0, 0))

    # ---- helpers ----

    def finish(self):
        # markeer voltooid, terug naar menu
        self.progress.mark_complete('level_story_one')
        self.next_scene = 'scene_picker'
        self.done = True
