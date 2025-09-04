import os
import json
import pygame


# Lage latency; valt terug als 256 te agressief is
def pre_init():
    try:
        pygame.mixer.pre_init(44100, -16, 2, 256)
    except Exception:
        pass


def init():
    try:
        pygame.mixer.init()
    except Exception:
        pass  # silent of geen audio-device


class Audio:
    """
    Background music via pygame.mixer.music (streaming, fade), SFX via Sound-kanalen.
    Scene-mapping komt uit data/scene_music.json. No-op safe bij ontbrekende assets.
    """
    def __init__(self, bpm: int = 90):
        self.sfx_map = {'beat': 'beat'}   # event 'beat' → data/sfx/beat.wav
        self.bpm = bpm
        self.music_on = True
        self.music_vol = 0.8
        self.sfx_vol = 0.9

        # Muziek: we bewaren paden (streaming), geen Sound-objecten
        self.tracks = {}          # name -> file path
        self.scene_map = {}       # scene_key -> track name
        self.current_track = None

        # SFX: in geheugen
        self.sfx = {}             # name -> Sound
        self.sfx_map = {}         # event -> sfx-name

        self.enabled = pygame.mixer.get_init() is not None
        self.beat_ms = 60000.0 / max(1, self.bpm)
        self._acc_ms = 0.0

        # SFX-kanalen
        self._sfx_channels = []
        if self.enabled:
            try:
                self._sfx_channels = [pygame.mixer.Channel(i) for i in range(1, 8)]
                for ch in self._sfx_channels:
                    ch.set_volume(self.sfx_vol)
                pygame.mixer.music.set_volume(self.music_vol)
            except Exception:
                self._sfx_channels = []

    # ---------- asset discovery ----------

    def build(self):
        if not self.enabled:
            return

        mus_dir = os.path.join('data', 'music')
        if os.path.isdir(mus_dir):
            for fn in os.listdir(mus_dir):
                low = fn.lower()
                if low.endswith(('.ogg', '.wav', '.mp3')):
                    name = os.path.splitext(fn)[0]
                    self.tracks[name] = os.path.join(mus_dir, fn)

        sfx_dir = os.path.join('data', 'sfx')
        if os.path.isdir(sfx_dir):
            for fn in os.listdir(sfx_dir):
                if fn.lower().endswith(('.wav', '.ogg')):
                    name = os.path.splitext(fn)[0]
                    try:
                        snd = pygame.mixer.Sound(os.path.join(sfx_dir, fn))
                        snd.set_volume(self.sfx_vol)
                        self.sfx[name] = snd
                    except Exception:
                        pass

    def load_scene_map(self, mapping: dict):
        self.scene_map = dict(mapping or {})

    # ---------- music control ----------

    def _load_and_play(self, path: str, fade_ms: int = 500):
        try:
            if pygame.mixer.music.get_busy():
                pygame.mixer.music.fadeout(fade_ms)
            pygame.mixer.music.load(path)
            pygame.mixer.music.play(-1, fade_ms=fade_ms)
            self.current_track = path
        except Exception:
            self.current_track = None

    def play_for(self, scene_key: str, fade_ms: int = 500):
        if not (self.enabled and self.music_on):
            return
        name = self.scene_map.get(scene_key)
        if not name:
            return
        path = self._resolve_track(name)
        if not path:
            return
        if self.current_track != path:
            self._load_and_play(path, fade_ms=fade_ms)

    def play(self, track_name: str, fade_ms: int = 500):
        if not (self.enabled and self.music_on):
            return
        path = self._resolve_track(track_name)
        if path:
            self._load_and_play(path, fade_ms=fade_ms)

    def _resolve_track(self, name: str):
        # accepteert 'theme' of 'theme.ogg'
        base = os.path.splitext(name)[0]
        if base in self.tracks:
            return self.tracks[base]
        # brute search op exacte bestandsnaam
        for k, v in self.tracks.items():
            if os.path.basename(v).lower() == name.lower():
                return v
        return None

    def stop_music(self, fade_ms: int = 300):
        try:
            if pygame.mixer.music.get_busy():
                pygame.mixer.music.fadeout(fade_ms)
        except Exception:
            pass
        self.current_track = None

    def toggle_music(self):
        self.music_on = not self.music_on
        if not self.music_on:
            self.stop_music()
        else:
            # herstart laatste mapping als die bekend is: engine/scene roept normaliter play_for() aan
            pass

    def set_music_volume(self, vol: float):
        self.music_vol = max(0.0, min(1.0, vol))
        try:
            pygame.mixer.music.set_volume(self.music_vol)
        except Exception:
            pass

    # ---------- beat & sfx ----------

    def music_tick(self, dt_ms: int):
        """
        Optioneel ritme-hook: call elke frame met delta-ms (engine kan dit aanroepen).
        Wanneer bpm gezet is en er bestaat een sfx voor event 'beat', speel die op de tel.
        """
        if not (self.enabled and self.music_on and self.beat_ms > 0):
            return
        self._acc_ms += dt_ms
        while self._acc_ms >= self.beat_ms:
            self._acc_ms -= self.beat_ms
            b = self.sfx_for_event('beat')
            if b:
                self.play_sfx(b)

    def play_sfx(self, name: str):
        if not self.enabled:
            return
        snd = self.sfx.get(name)
        if not snd or not self._sfx_channels:
            return
        ch = self._sfx_channels.pop(0)
        try:
            ch.set_volume(self.sfx_vol)
            ch.play(snd)
        except Exception:
            pass
        self._sfx_channels.append(ch)

    def sfx_for_event(self, name: str):
        return self.sfx_map.get(name)

    # ---------- prefs ----------

    def save_prefs(self):
        cfg = {
            'music_on': self.music_on,
            'music_vol': round(self.music_vol, 3),
            'sfx_vol': round(self.sfx_vol, 3),
            'bpm': self.bpm,
            'map': self.sfx_map
        }
        try:
            os.makedirs('data', exist_ok=True)
            with open(os.path.join('data', 'sound_prefs.json'), 'w', encoding='utf-8') as f:
                json.dump(cfg, f, indent=2, ensure_ascii=False)
        except Exception:
            pass
