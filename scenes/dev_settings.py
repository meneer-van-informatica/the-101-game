import pygame
import math

class DevSettings:
    """
    ESC-screen Mixer:
      - A/D: vorige/volgende instrument
      - Left/Right: verplaats step
      - Space: toggle note op huidige step voor huidig instrument
      - W/S: volume +/-
      - Enter: audition (speel losse hit van instrument)
      - P: play/pause sequencer
      - R: reset alle steps
      - M: toggle muziek (BGM)
      - Esc: terug naar menu
    """
    wants_beat = False  # we gebruiken eigen sequencer timing

    def __init__(self, services):
        self.services = services
        self.audio = services.get('audio')
        self.settings = services.get('settings', {})
        self.font = pygame.font.SysFont(self.settings.get("font_name") or pygame.font.get_default_font(), 24)

        # Sequencer state
        self.bpm = float(self.settings.get("music_bpm", 90))
        self.sec_per_beat = 60.0 / max(1.0, self.bpm)
        self.steps = 16
        self.step = 0
        self.playing = True
        self.time_acc = 0.0

        # Tracks: naam -> sfx naam -> volume
        self.tracks = [
            {"name": "KICK",  "sfx": "kick",  "vol": 0.9},
            {"name": "SNARE", "sfx": "snare", "vol": 0.8},
            {"name": "HAT",   "sfx": "hat",   "vol": 0.6},
            {"name": "CLAP",  "sfx": "clap",  "vol": 0.7},
        ]
        self.track_i = 0
        # Pattern: tracks x steps (bool)
        self.pat = [[False]*self.steps for _ in self.tracks]

        # UI layout
        self.margin = 60
        self.cell_w = 36
        self.cell_h = 28
        self.cell_gap = 8

        # colors
        self.c_bg    = (16, 18, 26)
        self.c_grid  = (44, 48, 62)
        self.c_on    = (120, 200, 255)
        self.c_off   = (70, 78, 96)
        self.c_sel   = (240, 250, 255)
        self.c_text  = (220, 230, 240)
        self.c_dim   = (150, 160, 172)
        self.c_accent= (255, 170, 80)

        # ensure sfx volumes once
        if self.audio:
            for tr in self.tracks:
                snd = self.audio.sfx.get(tr["sfx"]) if hasattr(self.audio, "sfx") else None
                try:
                    if snd: snd.set_volume(tr["vol"])
                except Exception:
                    pass

    # -------- input --------

    def handle_event(self, e):
        if e.type != pygame.KEYDOWN:
            return
        k = e.key

        if k == pygame.K_ESCAPE:
            self.next_scene = "scene_picker"
            return

        # instrument wisselen
        if k in (pygame.K_a, pygame.K_LEFTBRACKET):  # A of [
            self.track_i = (self.track_i - 1) % len(self.tracks)
        elif k in (pygame.K_d, pygame.K_RIGHTBRACKET):  # D of ]
            self.track_i = (self.track_i + 1) % len(self.tracks)

        # step verplaatsen
        elif k == pygame.K_RIGHT:
            self.step = (self.step + 1) % self.steps
        elif k == pygame.K_LEFT:
            self.step = (self.step - 1) % self.steps

        # toggle note
        elif k == pygame.K_SPACE:
            cur = self.pat[self.track_i][self.step]
            self.pat[self.track_i][self.step] = not cur

        # audition huidige instrument
        elif k in (pygame.K_RETURN, pygame.K_KP_ENTER):
            self._play_track_hit(self.track_i)

        # play/pause
        elif k == pygame.K_p:
            self.playing = not self.playing

        # reset pattern
        elif k == pygame.K_r:
            for r in self.pat:
                for i in range(self.steps):
                    r[i] = False
            self.step = 0

        # volume
        elif k == pygame.K_w:
            self._adjust_vol(self.track_i, +0.05)
        elif k == pygame.K_s:
            self._adjust_vol(self.track_i, -0.05)

        # muziek toggle
        elif k == pygame.K_m and self.audio:
            self.audio.toggle_music()

    # -------- logic --------

    def update(self, dt):
        if not self.playing:
            return
        self.time_acc += dt
        while self.time_acc >= self.sec_per_beat:
            self.time_acc -= self.sec_per_beat
            # advance step
            self.step = (self.step + 1) % self.steps
            # play active notes on this step
            for ti, tr in enumerate(self.tracks):
                if self.pat[ti][self.step]:
                    self._play_track_hit(ti)

    def _adjust_vol(self, idx, delta):
        if not (0 <= idx < len(self.tracks)):
            return
        self.tracks[idx]["vol"] = max(0.0, min(1.0, self.tracks[idx]["vol"] + delta))
        if self.audio:
            snd = self.audio.sfx.get(self.tracks[idx]["sfx"]) if hasattr(self.audio, "sfx") else None
            try:
                if snd: snd.set_volume(self.tracks[idx]["vol"])
            except Exception:
                pass

    def _play_track_hit(self, idx):
        if not self.audio:
            return
        name = self.tracks[idx]["sfx"]
        # probeer volume per hit nogmaals toe te passen
        snd = self.audio.sfx.get(name) if hasattr(self.audio, "sfx") else None
        try:
            if snd: snd.set_volume(self.tracks[idx]["vol"])
        except Exception:
            pass
        try:
            self.audio.play_sfx(name)
        except Exception:
            pass

    # -------- render --------

    def draw(self, screen):
        screen.fill(self.c_bg)
        w, h = screen.get_size()

        # Titel
        title = self.font.render("Mixer — 16-Step Sequencer (BPM {})".format(int(self.bpm)), True, self.c_text)
        screen.blit(title, (self.margin, 24))

        # Controls
        controls = [
            "A/D: instrument • ←/→: step • Space: toggle • Enter: audition • W/S: vol • P: play/pause • R: reset • M: music • Esc: menu"
        ]
        yctrl = h - 36
        for line in controls:
            surf = self.font.render(line, True, self.c_dim)
            screen.blit(surf, (self.margin, yctrl))
            yctrl += 28

        # Grid
        grid_x = self.margin
        grid_y = 70
        for ti, tr in enumerate(self.tracks):
            # instrument label
            sel = (ti == self.track_i)
            label = f"{tr['name']}  vol {tr['vol']:.2f}"
            col = self.c_accent if sel else self.c_dim
            lab = self.font.render(label, True, col)
            screen.blit(lab, (grid_x, grid_y + ti*(self.cell_h + self.cell_gap) - 28))

            y = grid_y + ti*(self.cell_h + self.cell_gap)
            for si in range(self.steps):
                x = grid_x + si*(self.cell_w + self.cell_gap)
                rect = pygame.Rect(x, y, self.cell_w, self.cell_h)
                # achtergrond
                pygame.draw.rect(screen, self.c_grid, rect, border_radius=6)
                # aan/uit
                on = self.pat[ti][si]
                if on:
                    pygame.draw.rect(screen, self.c_on, rect.inflate(-6, -6), border_radius=6)
                else:
                    pygame.draw.rect(screen, self.c_off, rect.inflate(-6, -6), border_radius=6)
                # step-indicator
                if si == self.step:
                    pulse = 0.6 + 0.4*math.sin(pygame.time.get_ticks()/120.0)
                    br = max(2, int(3*pulse))
                    pygame.draw.rect(screen, self.c_sel, rect, br, border_radius=6)
