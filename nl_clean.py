import sys, re, pathlib

def to_sentences(text):
    text = re.sub(r'\s+', ' ', text.strip())
    text = re.sub(r'\[(?:music|applause|laughter|inaudible)[^\]]*\]', '', text, flags=re.I)
    text = re.sub(r'\([^)]*\)', '', text)
    pattern = r'(?<=[\.\!\?…])\s+(?=[A-ZÀ-ÖØ-Þ0-9\'"“”])'
    parts = re.split(pattern, text)
    sents = [s.strip() for s in parts if 25 <= len(s.strip()) <= 220]
    if not sents:
        sents = [l.strip() for l in text.split('.') if len(l.strip()) > 0]
    return sents

def light_cleanup(text):
    # spaties, dubbele quotes → enkele quotes, rare underscores, dubbele punten
    text = re.sub(r'\s+', ' ', text)
    text = text.replace('"', "'")
    text = re.sub(r'\s+([,.:;!?…])', r'\1', text)
    text = re.sub(r'\.{3,}', '…', text)
    text = re.sub(r'[_]{2,}', '_', text)
    return text.strip()

def lt_cleanup(text):
    try:
        import language_tool_python
        tool = language_tool_python.LanguageTool('nl')
        matches = tool.check(text)
        return language_tool_python.utils.correct(text, matches)
    except Exception:
        return text  # als LT niet beschikbaar is, laat zoals het is

def main():
    if len(sys.argv) < 3:
        print("usage: python nl_clean.py INPUT.txt OUTPUT.txt")
        sys.exit(1)
    inp = pathlib.Path(sys.argv[1])
    outp = pathlib.Path(sys.argv[2])
    raw = inp.read_text(encoding='utf-8', errors='ignore')
    sents = to_sentences(raw)
    body = ' '.join(sents)
    body = light_cleanup(body)
    body = lt_cleanup(body)
    outp.write_text(body, encoding='utf-8')
    print(f'clean geschreven: {outp}')

if __name__ == '__main__':
    main()
