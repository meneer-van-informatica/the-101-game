# engine.py
import os
import sys
import json
import argparse
import importlib

# pygame pas importeren nadat we weten dat we gaan runnen
import pygame

# core services
from core import audio as audio_mod
from core.tts import Voice
from core.progress import Progress


# ---------- cli bootstrap: --start vlag en/of env ----------
def _start_arg() -> str:
    if '--start' in sys.argv:
        i = sys.argv.index('--start')
        if i + 1 < len(sys.argv):
            return sys.argv[i + 1].strip()
    return os.getenv('KM_START', '').strip()

START = _start_arg()  # 'menu', 'w0', 'w1', ...


# ---------- utils ----------
def load_json(path, default):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception:
        return default


def ensure_data_dirs():
    os.makedirs('data', exist_ok=True)
    os.makedirs(os.path.join('data', 'music'), exist_ok=True)
    os.makedirs(os.path.join('data', 'sfx'), exist_ok=True)
    os.makedirs('screenshots', exist_ok=True)


def import_scenes():
    # import hier je scene-klassen en maak een key→class map
    from scenes.scene_picker import ScenePicker
    from scenes.dev_settings import DevSettings
    from scenes.level_story_one import LevelStoryOne
    from scenes.typing_ad import TypingAD
    from scenes.level7_spectro_mix import Level7SpectroMix
    from scenes.world_w3_machines import WorldW3Machines
    return {
        'scene_picker': ScenePicker,
        'dev_settings': DevSettings,
        'level_story_one': LevelStoryOne,
        'typing_ad': TypingAD,
        'level7_spectro_mix': Level7SpectroMix,
        'world_w3_machines': WorldW3Machines,
    }


def make_scene(key, classes, services):
    cls = classes.get(key) or classes['scene_picker']
    return key, cls(services)

def resolve_default_start(scene_classes: dict) -> str:
    # 1) worlds.json[0] als die bestaat én in classes zit
    try:
        worlds = load_json(os.path.join('data', 'worlds.json'), [])
    except Exception:
        worlds = []
    if worlds:
        first = worlds[0]
        if isinstance(first, str) and first in scene_classes:
            return first

    # 2) vaste voorkeursvolgorde (pas aan als jouw project anders is)
    for candidate in ['level_story_one', 'typing_ad', 'world_w3_machines']:
        if candidate in scene_classes:
            return candidate

    # 3) eerste beste scene behalve menu/dev
    for k in scene_classes.keys():
        if k not in ('scene_picker', 'dev_settings'):
            return k

    # ultieme fallback
    return 'scene_picker'


def resolve_cli_scene(cli: str, scene_classes: dict) -> str | None:
    if not cli:
        return None
    cli = cli.strip().lower()

    # 'w0' / 'default' / 'enter' → doe wat menu-Enter zou doen
    if cli in ('w0', 'default', 'enter'):
        return resolve_default_start(scene_classes)

    # alias: wN → worlds.json[N]
    if len(cli) >= 2 and cli[0] == 'w' and cli[1:].isdigit():
        try:
            worlds = load_json(os.path.join('data', 'worlds.json'), [])
            idx = int(cli[1:])
            if 0 <= idx < len(worlds):
                key = worlds[idx]
                return key if key in scene_classes else None
        except Exception:
            return None

    # numeriek index → worlds.json[N]
    if cli.isdigit():
        try:
            worlds = load_json(os.path.join('data', 'worlds.json'), [])
            idx = int(cli)
            if 0 <= idx < len(worlds):
                key = worlds[idx]
                return key if key in scene_classes else None
        except Exception:
            return None

    # directe key
    if cli in scene_classes:
        return cli

    return None


# ---------- Game ----------
class Game:
    def __init__(self, args: argparse.Namespace):
        self.args = args
        ensure_data_dirs()

        # defaults
        defaults = {
            'fullscreen': True,
            'music_bpm': 90,
            'target_fps': 60,
            'font_name': 'consolas',
            'music_volume': 0.5,
            'sfx_volume': 0.5,
        }
        self.settings = load_json('data/settings.json', defaults)
        if getattr(args, 'windowed', False):
            self.settings['fullscreen'] = False

        # audio init vóór pygame.init voor juiste mixer (tenzij silent)
        self.silent = bool(args.silent)
        if not self.silent:
            audio_mod.pre_init()
        pygame.init()

        # display
        self.screen = None
        self.size = (1280, 720)
        self.apply_display_mode()
        pygame.display.set_caption('The 101 Game • PyGame × Audio')

        # services
        self.progress = Progress()
        self.voice = Voice(silent=self.silent)
        self.audio = None
        if not self.silent:
            try:
                audio_mod.init()
            except Exception:
                pass
            self.audio = audio_mod.Audio(bpm=int(self.settings.get('music_bpm', 90)))
            self.audio.build()
            scene_map = load_json('data/scene_music.json', {})
            self.audio.load_scene_map(scene_map)
            self.audio.set_music_volume(float(self.settings.get('music_volume', 0.5)))
            self.audio.sfx_vol = float(self.settings.get('sfx_volume', 0.5))

        self.services = {
            'audio': self.audio,
            'tts': self.voice,
            'settings': self.settings,
            'progress': self.progress,
            'silent': self.silent,
        }

        # scenes
        self.scene_classes = import_scenes()

        # startscene bepalen
        requested = (getattr(args, 'scene', '') or '').strip().lower()
        start_key = resolve_cli_scene(requested, self.scene_classes) or 'scene_picker'
        self.scene_key, self.scene = make_scene(start_key, self.scene_classes, self.services)

        # timing
        self.clock = pygame.time.Clock()
        self.target_fps = int(self.settings.get('target_fps', 60))
        self.running = True

        # start muziek voor eerste scene
        if self.audio:
            try:
                self.audio.play_for(self.scene_key)
            except Exception:
                pass

    # ---- display helpers ----
    def apply_display_mode(self):
        if bool(self.settings.get('fullscreen')):
            info = pygame.display.Info()
            w, h = info.current_w, info.current_h
            self.screen = pygame.display.set_mode((w, h), pygame.FULLSCREEN)
        else:
            self.screen = pygame.display.set_mode((1280, 720), pygame.SCALED | pygame.RESIZABLE)

    def toggle_fullscreen(self):
        self.settings['fullscreen'] = not bool(self.settings.get('fullscreen'))
        self.apply_display_mode()

    # ---- main loop ----
    def run(self):
        while self.running:
            dt_ms = self.clock.tick(self.target_fps)
            dt = dt_ms / 1000.0

            # snapshot: teken één frame, sla op, exit
            if getattr(self.args, 'snapshot', False):
                drew = False
                if hasattr(self.scene, 'on_snapshot'):
                    try:
                        self.scene.on_snapshot(self.screen, when='final')
                        drew = True
                    except Exception as ex:
                        print('[snapshot hook error]', ex)
                if not drew:
                    try:
                        for _ in range(180):  # ~3s @60fps
                            self.scene.update(1.0 / 60.0)
                    except Exception:
                        pass
                    try:
                        self.scene.draw(self.screen)
                    except Exception as ex:
                        self.draw_fallback(ex)

                pygame.display.flip()
                shotdir = getattr(self.args, 'shotdir', 'screenshots') or 'screenshots'
                os.makedirs(shotdir, exist_ok=True)
                import time
                path = os.path.join(shotdir, f'{self.scene_key}_{int(time.time())}.png')
                pygame.image.save(self.screen, path)
                print('[SHOT]', path)
                self.quit()
                continue

            # events
            for e in pygame.event.get():
                if e.type == pygame.QUIT:
                    self.quit()
                    continue

                if e.type == pygame.KEYDOWN:
                    if e.key == pygame.K_ESCAPE:
                        self.switch_scene('dev_settings')
                        continue
                    if e.key == pygame.K_F12:
                        shotdir = getattr(self.args, 'shotdir', 'screenshots') or 'screenshots'
                        os.makedirs(shotdir, exist_ok=True)
                        ts = pygame.time.get_ticks()
                        path = os.path.join(shotdir, f'{self.scene_key}_{ts}.png')
                        pygame.image.save(self.screen, path)
                        print('[SHOT]', path)
                        continue
                    if e.key == pygame.K_q:
                        self.quit()
                        continue
                    if e.key == pygame.K_F11 or (e.key == pygame.K_RETURN and (e.mod & pygame.KMOD_ALT)):
                        self.toggle_fullscreen()
                        continue
                    if e.key == pygame.K_F9 and self.audio:
                        # herlaad muziek-mapping live
                        self.audio.load_scene_map(load_json('data/scene_music.json', {}))
                        continue

                try:
                    if hasattr(self.scene, 'handle_event'):
                        self.scene.handle_event(e)
                except Exception as ex:
                    print('[scene handle_event error]', ex)

            # update
            try:
                if hasattr(self.scene, 'update'):
                    self.scene.update(dt)
            except Exception as ex:
                print('[scene update error]', ex)

            # beat/metronoom
            if self.audio and getattr(self.scene, 'wants_beat', False):
                try:
                    self.audio.music_tick(dt_ms)
                except Exception:
                    pass

            # scene switch protocol
            next_key = getattr(self.scene, 'next_scene', None)
            done = getattr(self.scene, 'done', False)
            if callable(getattr(self.scene, 'next', None)):
                try:
                    nk = self.scene.next()
                    if nk:
                        next_key = nk
                except Exception:
                    pass

            if next_key == 'QUIT':
                self.quit()
            elif next_key or done:
                self.switch_scene(next_key or 'scene_picker')

            # draw
            try:
                if hasattr(self.scene, 'draw'):
                    self.scene.draw(self.screen)
                else:
                    self.draw_fallback('scene has no draw()')
            except Exception as ex:
                self.draw_fallback(ex)

            pygame.display.flip()

        # afsluiten
        self.progress.save()
        pygame.quit()

    # ---- helpers ----
    def switch_scene(self, new_key):
        if new_key not in self.scene_classes:
            new_key = 'scene_picker'
        self.scene_key, self.scene = make_scene(new_key, self.scene_classes, self.services)
        self.progress.data['last_scene'] = new_key
        self.progress.save()
        if self.audio:
            try:
                self.audio.play_for(new_key)
            except Exception:
                pass

    def quit(self):
        self.running = False

    def draw_fallback(self, ex):
        self.screen.fill((0, 0, 0))
        fontname = self.settings.get('font_name') or pygame.font.get_default_font()
        font = pygame.font.SysFont(fontname, 22)
        y = 120
        for line in [
            f'Error while drawing scene {self.scene_key}',
            f'{ex}',
            'Press Q to quit',
        ]:
            surf = font.render(line, True, (255, 100, 100))
            self.screen.blit(surf, (60, y))
            y += 32


# ---------- cli surface ----------
def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description='The 101 Game')
    p.add_argument('--start', type=str, default='', help='menu|w0|w1|<scene-key>')
    p.add_argument('--scene', type=str, default='', help='scene-key of alias (w0, 0, typing_ad)')
    p.add_argument('--silent', action='store_true', help='skip audio init, maar wel renderen')
    p.add_argument('--windowed', action='store_true', help='forceer windowed mode (override settings)')
    p.add_argument('--shotdir', type=str, default='screenshots', help='map voor F12/snapshot PNGs')
    p.add_argument('--snapshot', action='store_true', help='render één frame, sla PNG op, exit')
    return p.parse_args()


# Deze starten bewust nieuwe Game-instanties, zodat je losse vensters kunt draaien
def run_menu():
    args = parse_args()
    # menu afdwingen: start=menu, scene leeg
    args.start = 'menu'
    args.scene = ''
    game = Game(args)
    return game.run()


def launch_world(tag: str):
    args = parse_args()
    # directe jump: respecteer tag via scene (resolver doet wN/numeric/key)
    args.start = tag
    args.scene = tag
    game = Game(args)
    return game.run()

def run_menu():
    args = parse_args()
    args.start = 'menu'
    args.scene = ''
    game = Game(args)
    return game.run()

def launch_world(tag: str):
    args = parse_args()
    args.start = tag
    args.scene = tag
    game = Game(args)
    return game.run()

# ---------- main ----------
def main():
    # START komt uit argv/env zodat je eenvoudig via --start kunt sturen
    if START in ('menu', 'level0', 'l0', 'km'):
        return run_menu()
    if START:
        return launch_world(START)

    # geen START → check parse_args().start
    args = parse_args()
    if args.start in ('menu', 'level0', 'l0', 'km'):
        return run_menu()
    if args.start:
        return launch_world(args.start)

    # fallback: normaal menu
    return run_menu()


if __name__ == '__main__':
    main()
