import os
import sys
import json
import argparse
import pygame

from core import audio as audio_mod
from core.tts import Voice
from core.progress import Progress


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


# ---------- scene loader ----------

def import_scenes():
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


# ---------- game ----------

class Game:
    def __init__(self, args):
        ensure_data_dirs()

        # defaults: fullscreen ON
        defaults = {
            'fullscreen': True,
            'music_bpm': 90,
            'target_fps': 60,
            'font_name': 'consolas',
        }
        self.settings = load_json('data/settings.json', defaults)
        if getattr(args, 'windowed', False):
            self.settings['fullscreen'] = False

        # init pygame (audio pre_init alleen als niet-silent)
        if not args.silent:
            audio_mod.pre_init()
        pygame.init()

        # display
        self.size = (1280, 720)
        self.apply_display_mode()
        pygame.display.set_caption('The 101 Game • PyGame × Audio')

        # services
        self.silent = bool(args.silent)
        self.progress = Progress()
        self.voice = Voice(silent=self.silent)

        # audio service
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

        self.services = {
            'audio': self.audio,
            'tts': self.voice,
            'settings': self.settings,
            'progress': self.progress,
            'silent': self.silent,
        }

        # scenes
        self.scene_classes = import_scenes()
        self.scene_key, self.scene = make_scene('scene_picker', self.scene_classes, self.services)

        # timing
        self.clock = pygame.time.Clock()
        self.target_fps = int(self.settings.get('target_fps', 60))
        self.running = True

        # startmuziek voor de eerste scene
        if self.audio:
            try:
                self.audio.play_for(self.scene_key)
            except Exception:
                pass

    # ---- display helpers ----

    def apply_display_mode(self):
        # Echte fullscreen gebruikt desktopresolutie; anders windowed 1280x720
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

            # events
            for e in pygame.event.get():
                if e.type == pygame.QUIT:
                    self.quit(); continue
                if e.type == pygame.KEYDOWN:
                    if e.key == pygame.K_q:
                        self.quit(); continue
                    if e.key == pygame.K_F11 or (e.key == pygame.K_RETURN and (e.mod & pygame.KMOD_ALT)):
                        self.toggle_fullscreen(); continue
                    if e.key == pygame.K_F9 and self.audio:
                        # herlaad muziek-mapping live
                        self.audio.load_scene_map(load_json('data/scene_music.json', {}))
                        continue
                try:
                    self.scene.handle_event(e)
                except Exception as ex:
                    print(f'[scene handle_event error] {ex}')

            # update
            try:
                self.scene.update(dt)
            except Exception as ex:
                print(f'[scene update error] {ex}')

            # metronoom/beat alleen als scene het wil
            if self.audio and getattr(self.scene, 'wants_beat', False):
                try:
                    self.audio.music_tick(dt_ms)
                except Exception:
                    pass

            # scene switch
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
                self.scene.draw(self.screen)
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
        font = pygame.font.SysFont(self.settings.get('font_name') or pygame.font.get_default_font(), 22)
        y = 120
        for line in [
            f'Error while drawing scene {self.scene_key}',
            f'{ex}',
            'Press Q to quit'
        ]:
            surf = font.render(line, True, (255, 100, 100))
            self.screen.blit(surf, (60, y))
            y += 32


# ---------- cli ----------

def parse_args():
    p = argparse.ArgumentParser(description='The 101 Game')
    p.add_argument('--silent', action='store_true', help='skip audio init but still render/update')
    p.add_argument('--windowed', action='store_true', help='force windowed mode (override settings)')
    return p.parse_args()


def main():
    Game(parse_args()).run()


if __name__ == '__main__':
    main()
