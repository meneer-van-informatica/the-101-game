import json
import os


class Progress:
    def __init__(self):
        self.path = os.path.join('data', 'progress.json')
        self.data = {'last_scene': None, 'completed': []}
        self.load()

    def load(self):
        try:
            with open(self.path, 'r', encoding='utf-8') as f:
                data = json.load(f)
                self.data['last_scene'] = data.get('last_scene')
                comp = data.get('completed', [])
                self.data['completed'] = comp if isinstance(comp, list) else list(comp)
        except Exception:
            self.data = {'last_scene': None, 'completed': []}

    def save(self):
        os.makedirs('data', exist_ok=True)
        try:
            with open(self.path, 'w', encoding='utf-8') as f:
                json.dump(self.data, f, indent=2, ensure_ascii=False)
        except Exception:
            pass

    def mark_complete(self, wid: str):
        if wid and wid not in self.data['completed']:
            self.data['completed'].append(wid)

    def unlock_next(self, worlds: list, wid: str):
        if wid:
            self.data['last_scene'] = wid
