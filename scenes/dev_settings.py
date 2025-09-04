import pygame
import math
from core.ui import gradient_bg, panel, rounded_rect, glow_rect, center_text, label

class DevSettings:
    """
    Mixer (ESC):
      A/D instrument • ←/→ step • Space toggle • Enter audition
      W/S vol per instrument • P play/pause • R reset
      M music on/off • Esc menu
    """
    wants_beat = False  # eigen clock

    def __init__(self, services):
        self.services = services
        self.audio = services.get('audio')
        self.settings = services.get('settings', {})
        name = self.settings.get("font_name") or pygame.font.get_default_font()
        self.font   = pygame.font.SysFont(name, 22)
        self.fontH  = pygame.font.SysFont(name, 28, bold=True)
        self.fontM  = pygame.font.SysFont(name, 18)

        # Sequencer
        self.bpm = float(self.settings.get("music_bpm", 90))
        self.sec_per_beat = 60.0 / max(1.0, self.bpm)
        self.steps = 16
        self.step = 0
        self.playing = True
        self.time_acc = 0.0

        # Tracks
        self.tracks = [
            {"name": "KICK",  "sfx": "kick",  "vol": 0.9},
            {"name": "SNARE", "sfx": "snare", "vol": 0.8},
            {"name": "HAT",   "sfx": "hat",   "vol": 0.6},
            {"name": "CLAP",  "sfx": "clap",  "vol": 0.7},
        ]
        self.track_i = 0
        self.pat = [[False]*self.steps for _ in self.tracks]

        # UI
        self.margin = 48
        self.cell_w, self.cell_h, self.gap = 38, 30, 10
        self.next_scene = None
        self.done = False

        if self.audio:
            for tr in self.tracks:
                snd = self.audio.sfx.get(tr["sfx"]) if hasattr(self.audio, "sfx") else None
                try:
                    if snd: snd.set_volume(tr["vol"])
                except Exception:
                    pass

    # ---------- input ----------
    def handle_event(self, e):
        if e.type != pygame.KEYDOWN:
            return
        k = e.key
        if k == pygame.K_ESCAPE:
            self.next_scene = "scene_picker"; return

        if k in (pygame.K_a, pygame.K_LEFTBRACKET):   self.track_i = (self.track_i - 1) % len(self.tracks)
        elif k in (pygame.K_d, pygame.K_RIGHTBRACKET):self.track_i = (self.track_i + 1) % len(self.tracks)
        elif k == pygame.K_RIGHT:                     self.step = (self.step + 1) % self.steps
        elif k == pygame.K_LEFT:                      self.step = (self.step - 1) % self.steps
        elif k == pygame.K_SPACE:                     self.pat[self.track_i][self.step] = not self.pat[self.track_i][self.step]
        elif k in (pygame.K_RETURN, pygame.K_KP_ENTER): self._play(self.track_i)
        elif k == pygame.K_p:                         self.playing = not self.playing
        elif k == pygame.K_r:                         [r.__setitem__(slice(None), [False]*self.steps) for r in self.pat]; self.step = 0
        elif k == pygame.K_w:                         self._vol(self.track_i, +0.05)
        elif k == pygame.K_s:                         self._vol(self.track_i, -0.05)
        elif k == pygame.K_m and self.audio:          self.audio.toggle_music()

        # live BPM: Z/X
        elif k == pygame.K_z:
            self.bpm = max(40.0, self.bpm - 2); self.sec_per_beat = 60.0 / self.bpm
        elif k == pygame.K_x:
            self.bpm = min(200.0, self.bpm + 2); self.sec_per_beat = 60.0 / self.bpm

    # ---------- logic ----------
    def update(self, dt):
        if not self.playing: return
        self.time_acc += dt
        while self.time_acc >= self.sec_per_beat:
            self.time_acc -= self.sec_per_beat
            self.step = (self.step + 1) % self.steps
            for i,tr in enumerate(self.tracks):
                if self.pat[i][self.step]:
                    self._play(i)

    def _vol(self, i, d):
        tr = self.tracks[i]; tr["vol"] = max(0.0, min(1.0, tr["vol"] + d))
        if self.audio:
            snd = self.audio.sfx.get(tr["sfx"]) if hasattr(self.audio,"sfx") else None
            try:
                if snd: snd.set_volume(tr["vol"])
            except Exception: pass

    def _play(self, i):
        if not self.audio: return
        tr = self.tracks[i]
        snd = self.audio.sfx.get(tr["sfx"]) if hasattr(self.audio,"sfx") else None
        try:
            if snd: snd.set_volume(tr["vol"])
        except Exception: pass
        try:
            self.audio.play_sfx(tr["sfx"])
        except Exception: pass

    # ---------- draw ----------
    def draw(self, screen):
        gradient_bg(screen)
        w,h = screen.get_size()

        # Header
        center_text(screen, self.fontH, "Mixer — 16-Step Sequencer", (235,240,255), 18)
        center_text(screen, self.fontM,
            "A/D instrument • ←/→ step • Space toggle • Enter audition • W/S vol • Z/X BPM • P play • R reset • M music • Esc menu",
            (185,195,205), 50)

        # Panels
        grid_rect = pygame.Rect(self.margin, 100, w - self.margin*2, 240)
        info_rect = pygame.Rect(self.margin, grid_rect.bottom + 16, w - self.margin*2, 120)
        panel(screen, grid_rect)
        panel(screen, info_rect)

        # Grid
        top = grid_rect.y + 36
        left = grid_rect.x + 16
        for ti,tr in enumerate(self.tracks):
            y = top + ti*(self.cell_h + self.gap)
            # instrument label
            sel = (ti == self.track_i)
            c = (255,180,90) if sel else (200,210,220)
            label(screen, self.font, f"{tr['name']}  vol {tr['vol']:.2f}", c, (grid_rect.x+12, y-26))
            # steps
            for si in range(self.steps):
                x = left + si*(self.cell_w + self.gap)
                r = pygame.Rect(x, y, self.cell_w, self.cell_h)
                base = (58,64,84); on=(130,205,255); off=(86,92,112)
                rounded_rect(screen, r, base, radius=8)
                inner = r.inflate(-6,-6)
                rounded_rect(screen, inner, on if self.pat[ti][si] else off, radius=6)
                # playhead glow
                if si == self.step:
                    glow_rect(screen, r.inflate(6,6), (240,250,255), strength=2, radius=10)

        # Play/tempo status
        status = f"BPM {int(self.bpm)}  •  {'PLAYING' if self.playing else 'PAUSED'}"
        center_text(screen, self.fontH, status, (235,240,255), info_rect.y + 20)

        # Tiny progress bar synced to beat
        prog_w = info_rect.w - 40
        prog_x = info_rect.x + 20
        prog_y = info_rect.y + 70
        t = (self.step % self.steps) / (self.steps - 1)
        bar_bg = pygame.Rect(prog_x, prog_y, prog_w, 12)
        rounded_rect(screen, bar_bg, (60,66,84), radius=6)
        knob = pygame.Rect(prog_x + int(t*prog_w) - 6, prog_y-4, 12, 20)
        rounded_rect(screen, knob, (140,200,255), radius=6)
