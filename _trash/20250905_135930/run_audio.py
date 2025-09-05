import json
from pathlib import Path

def load_json(path, default):
    p = Path(path)
    try:
        with open(p, 'r', encoding='utf-8-sig') as f:  # slikt BOM
            return json.load(f)
    except FileNotFoundError:
        print('[warn] scene_music.json niet gevonden, gebruik default')
        return default
    except json.JSONDecodeError as e:
        print(f'[error] ongeldige JSON: {e}')
        return default
