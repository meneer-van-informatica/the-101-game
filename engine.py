ABOUT = "the-101-game — Alchemist build v0.1.1\nPull → play.bat → Play.\n(Volg Mij en het Komt Goed, lul. - LMW)"

# engine.py — frames + shots + autodiscovery
import os, sys, json, argparse, importlib, pkgutil, inspect
import pygame
pygame.display.set_caption("the-101-game — Alchemist v0.1.1")

from core import audio as audio_mod
from core.tts import Voice
from core.progress import Progress

def load_json(path, default):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return default

def ensure_data_dirs():
    os.makedirs("data", exist_ok=True)
    os.makedirs(os.path.join("data","music"), exist_ok=True)
    os.makedirs(os.path.join("data","sfx"), exist_ok=True)
    os.makedirs("screenshots", exist_ok=True)

# ---------- registry ----------
def import_scenes():
    # vaste scenes (pas aan als jouw project anders is)
    from scenes.scene_picker import ScenePicker
    from scenes.dev_settings import DevSettings
    from scenes.level_story_one import LevelStoryOne
    from scenes.typing_ad import TypingAD
    from scenes.level7_spectro_mix import Level7SpectroMix
    from scenes.world_w3_machines import WorldW3Machines
    from scenes.w0_f0_square import W0F0Square
    from scenes.w0_f1 import W0F1Life
    from scenes.w0_f2 import W0F2Still
    from scenes.w0_f3 import W0F3Outro


    registry = {
        "scene_picker":      ScenePicker,
        "dev_settings":      DevSettings,
        "level_story_one":   LevelStoryOne,
        "typing_ad":         TypingAD,
        "level7_spectro_mix":Level7SpectroMix,
        "world_w3_machines": WorldW3Machines,
        'w0_f0_square': W0F0Square,
        'f0': W0F0Square,
        'w0_f1': W0F1Life,
        'w0_f2': W0F2Still,
        'w0_f3': W0F3Outro,


    }

    # --- auto-discover frames: scenes/frame_*.py   key = module name, alias fN ---
    try:
        scenes_path = os.path.join(os.path.dirname(__file__), "scenes")
        for m in pkgutil.iter_modules([scenes_path]):
            name = m.name
            if not name.startswith("frame_"): 
                continue
            mod = importlib.import_module(f"scenes.{name}")
            # kies eerste klasse die in dit module gedefinieerd is
            cls = None
            for nm, obj in inspect.getmembers(mod, inspect.isclass):
                if obj.__module__ == mod.__name__:
                    cls = obj; break
            if cls:
                registry[name] = cls
                suffix = name.replace("frame_","")
                if suffix.isdigit():
                    registry[f"f{suffix}"] = cls
    except Exception as ex:
        print("[autodiscover frames error]", ex)

    # convenience: bekende demo-frame er sowieso in (als module bestaat)
    try:
        from scenes.frame_square import FrameSquare
        registry.setdefault("frame_square", FrameSquare)
        registry.setdefault("f1", FrameSquare)
    except Exception:
        pass

    return registry

def resolve_default_start(scene_classes: dict) -> str:
    worlds = load_json(os.path.join("data","worlds.json"), [])
    if worlds:
        first = worlds[0]
        if isinstance(first, str) and first in scene_classes:
            return first
    for candidate in ["level_story_one","typing_ad","world_w3_machines"]:
        if candidate in scene_classes:
            return candidate
    for k in scene_classes.keys():
        if k not in ("scene_picker","dev_settings"):
            return k
    return "scene_picker"

def resolve_cli_scene(cli: str, scene_classes: dict) -> str | None:
    if not cli: return None
    cli = cli.strip().lower()
    if cli in ("w0","default","enter"):
        return resolve_default_start(scene_classes)
    if len(cli) >= 2 and cli[0] == "w" and cli[1:].isdigit():
        worlds = load_json(os.path.join("data","worlds.json"), [])
        idx = int(cli[1:])
        if 0 <= idx < len(worlds):
            key = worlds[idx]
            return key if key in scene_classes else None
        return None
    if cli.isdigit():
        worlds = load_json(os.path.join("data","worlds.json"), [])
        idx = int(cli)
        if 0 <= idx < len(worlds):
            key = worlds[idx]
            return key if key in scene_classes else None
        return None
    if cli in scene_classes: return cli
    return None

# ---------- snapshot helpers ----------
def _final_frame_shot(game, max_seconds=180.0):
    sim_dt, elapsed = 1.0/60.0, 0.0
    next_key = getattr(game.scene, "next_scene", None)
    done = getattr(game.scene, "done", False)
    while elapsed < max_seconds and not (next_key or done):
        try:
            if hasattr(game.scene, "update"):
                game.scene.update(sim_dt)
        except Exception as ex:
            print("[scene update error during shot]", ex)
            break
        if game.audio and getattr(game.scene, "wants_beat", False):
            try: game.audio.music_tick(int(sim_dt*1000))
            except Exception: pass
        next_key = getattr(game.scene, "next_scene", None)
        done = getattr(game.scene, "done", False)
        if callable(getattr(game.scene, "next", None)):
            try:
                nk = game.scene.next()
                if nk: next_key = nk
            except Exception: pass
        elapsed += sim_dt
    try:
        if hasattr(game.scene, "on_snapshot"):
            game.scene.on_snapshot(game.screen, when="final")
        elif hasattr(game.scene, "draw"):
            game.scene.draw(game.screen)
        else:
            game.draw_fallback("scene has no draw()")
    except Exception as ex:
        game.draw_fallback(ex)
    pygame.display.flip()

def _save_shot(game, label=None):
    shotdir = getattr(game.args, "shotdir", "screenshots") or "screenshots"
    os.makedirs(shotdir, exist_ok=True)
    import time
    tag = label or game.scene_key
    path = os.path.join(shotdir, f"{tag}_{int(time.time())}.png")
    pygame.image.save(game.screen, path)
    print("[SHOT]", path)
    return path

# ---------- game ----------
class Game:
    def __init__(self, args: argparse.Namespace):
        self.args = args
        ensure_data_dirs()

        defaults = {
            "fullscreen": True, "music_bpm": 90, "target_fps": 60,
            "font_name": "consolas", "music_volume": 0.5, "sfx_volume": 0.5,
        }
        self.settings = load_json("data/settings.json", defaults)
        if getattr(args, "windowed", False): self.settings["fullscreen"] = False

        self.silent = bool(args.silent)
        if not self.silent: audio_mod.pre_init()
        pygame.init()

        self.apply_display_mode()
        pygame.display.set_caption("The 101 Game  PyGame × Audio")

        self.progress = Progress()
        self.voice    = Voice(silent=self.silent)

        self.audio = None
        if not self.silent:
            try: audio_mod.init()
            except Exception: pass
            self.audio = audio_mod.Audio(bpm=int(self.settings.get("music_bpm", 90)))
            self.audio.build()
            self.audio.load_scene_map(load_json("data/scene_music.json", {}))
            self.audio.set_music_volume(float(self.settings.get("music_volume", 0.5)))
            self.audio.sfx_vol = float(self.settings.get("sfx_volume", 0.5))

        self.services = {
            "audio": self.audio, "tts": self.voice, "settings": self.settings,
            "progress": self.progress, "silent": self.silent,
        }

        self.scene_classes = import_scenes()

        requested = (getattr(args, "scene", "") or "").strip().lower()
        start_key = resolve_cli_scene(requested, self.scene_classes) or "scene_picker"
        self.scene_key, self.scene = self.make_scene(start_key)

        self.clock = pygame.time.Clock()
        self.target_fps = int(self.settings.get("target_fps", 60))
        self.running = True

        if self.audio:
            try: self.audio.play_for(self.scene_key)
            except Exception: pass

    def make_scene(self, key):
        cls = self.scene_classes.get(key) or self.scene_classes["scene_picker"]
        return key, cls(self.services)

    def apply_display_mode(self):
        if bool(self.settings.get("fullscreen")):
            info = pygame.display.Info()
            self.screen = pygame.display.set_mode((info.current_w, info.current_h), pygame.FULLSCREEN)
        else:
            self.screen = pygame.display.set_mode((1280, 720), pygame.SCALED | pygame.RESIZABLE)

    def toggle_fullscreen(self):
        self.settings["fullscreen"] = not bool(self.settings.get("fullscreen"))
        self.apply_display_mode()

    def run(self):
        while self.running:
            dt_ms = self.clock.tick(self.target_fps); dt = dt_ms/1000.0

            # --- snapshot path ---
            if getattr(self.args, "snapshot", False):
                if getattr(self.args, "start", ""):
                    _final_frame_shot(self, max_seconds=180.0); _save_shot(self, label=self.args.start)
                    self.quit(); continue
                # single-frame for --scene
                drew = False
                if hasattr(self.scene, "on_snapshot"):
                    try: self.scene.on_snapshot(self.screen, when="final"); drew=True
                    except Exception as ex: print("[snapshot hook error]", ex)
                if not drew:
                    try:
                        for _ in range(60):
                            if hasattr(self.scene, "update"): self.scene.update(1/60)
                    except Exception: pass
                    try:
                        if hasattr(self.scene, "draw"): self.scene.draw(self.screen)
                        else: self.draw_fallback("scene has no draw()")
                    except Exception as ex: self.draw_fallback(ex)
                pygame.display.flip(); _save_shot(self); self.quit(); continue

            for e in pygame.event.get():
                if e.type == pygame.QUIT: self.quit(); continue
                if e.type == pygame.KEYDOWN:
                    if e.key == pygame.K_ESCAPE: self.switch_scene("dev_settings"); continue
                    if e.key == pygame.K_F12:
                        shotdir = getattr(self.args, "shotdir", "screenshots") or "screenshots"
                        os.makedirs(shotdir, exist_ok=True)
                        path = os.path.join(shotdir, f"{self.scene_key}_{pygame.time.get_ticks()}.png")
                        pygame.image.save(self.screen, path); print("[SHOT]", path); continue
                    if e.key == pygame.K_q: self.quit(); continue
                    if e.key == pygame.K_F11 or (e.key == pygame.K_RETURN and (e.mod & pygame.KMOD_ALT)):
                        self.toggle_fullscreen(); continue
                    if e.key == pygame.K_F9 and self.audio:
                        self.audio.load_scene_map(load_json("data/scene_music.json", {})); continue
                try:
                    if hasattr(self.scene, "handle_event"): self.scene.handle_event(e)
                except Exception as ex: print("[scene handle_event error]", ex)

            try:
                if hasattr(self.scene, "update"): self.scene.update(dt)
            except Exception as ex: print("[scene update error]", ex)

            if self.audio and getattr(self.scene, "wants_beat", False):
                try: self.audio.music_tick(dt_ms)
                except Exception: pass

            next_key = getattr(self.scene, "next_scene", None)
            done = getattr(self.scene, "done", False)
            if callable(getattr(self.scene, "next", None)):
                try:
                    nk = self.scene.next()
                    if nk: next_key = nk
                except Exception: pass

            if next_key == "QUIT": self.quit()
            elif next_key or done: self.switch_scene(next_key or "scene_picker")

            try:
                if hasattr(self.scene, "draw"): self.scene.draw(self.screen)
                else: self.draw_fallback("scene has no draw()")
            except Exception as ex: self.draw_fallback(ex)

            pygame.display.flip()

        self.progress.save(); pygame.quit()

    def switch_scene(self, new_key):
        if new_key not in self.scene_classes: new_key = "scene_picker"
        self.scene_key, self.scene = self.make_scene(new_key)
        self.progress.data["last_scene"] = new_key; self.progress.save()
        if self.audio:
            try: self.audio.play_for(new_key)
            except Exception: pass

    def quit(self): self.running = False

    def draw_fallback(self, ex):
        self.screen.fill((0,0,0))
        font = pygame.font.SysFont(self.settings.get("font_name") or pygame.font.get_default_font(), 22)
        y = 120
        for line in [f"Error while drawing scene {self.scene_key}", f"{ex}", "Press Q to quit"]:
            self.screen.blit(font.render(line, True, (255,100,100)), (60,y)); y += 32

# ---------- argparse ----------
def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="The 101 Game")
    p.add_argument("--start", type=str, default="", help="menu|w0|w1|<scene-key>")
    p.add_argument("--scene", type=str, default="", help="scene-key (bv. frame_square, f1, typing_ad)")
    p.add_argument("--silent", action="store_true", help="skip audio init")
    p.add_argument("--windowed", action="store_true", help="force windowed")
    p.add_argument("--shotdir", type=str, default="screenshots", help="PNG output folder")
    p.add_argument("--snapshot", action="store_true", help="render laatste frame en exit")
    args, _ = p.parse_known_args()  # negeer onbekende tokens
    return args

def main():
    args = parse_args()
    # START via env of positioneel compat (km/w0/shot) blijft beschikbaar:
    start_env = os.getenv("KM_START", "").strip()
    if start_env and not args.start:
        args.start = start_env; args.scene = start_env

    # dispatch: --scene voor frames, --start voor flows
    if args.scene:
        game = Game(args)
        if args.snapshot:
            _final_frame_shot(game, max_seconds=0.0); _save_shot(game, label=args.scene); return
        return game.run()

    if args.start in ("menu","level0","l0","km"):
        game = Game(argparse.Namespace(**{**vars(args), "scene": "scene_picker"}))
        if args.snapshot:
            _final_frame_shot(game, max_seconds=0.0); _save_shot(game, label="menu"); return
        return game.run()

    if args.start:
        game = Game(args)
        if args.snapshot:
            _final_frame_shot(game, max_seconds=180.0); _save_shot(game, label=args.start); return
        return game.run()

    # fallback -> menu
    game = Game(argparse.Namespace(**{**vars(args), "scene": "scene_picker"}))
    return game.run()

if __name__ == "__main__":
    main()


