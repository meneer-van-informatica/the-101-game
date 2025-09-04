class Voice:
    def __init__(self, silent: bool = False):
        self.silent = silent

    def say_title(self, text: str):
        if not self.silent:
            print(f'TTS: {text}')
