import sys, pathlib, re
def light(text):
    text = re.sub(r'\s+', ' ', text)
    text = re.sub(r'\s+([,.:;!?…])', r'\1', text)
    text = text.replace('"', "'")
    return text.strip()

def main(inp, outp):
    raw = pathlib.Path(inp).read_text(encoding='utf-8', errors='ignore')
    import spacy
    nlp = spacy.load('nl_core_news_sm')
    doc = nlp(raw)
    sents = []
    for s in doc.sents:
        st = s.text.strip()
        if re.match(r'^\p{Lu}', st, flags=re.UNICODE) if hasattr(re, 'UNICODE') else True:
            pass
        if 40 <= len(st) <= 220 and re.search(r'[.!?…]$', st):
            sents.append(st)
    text = light(' '.join(sents))
    try:
        import language_tool_python
        tool = language_tool_python.LanguageTool('nl')
        text = language_tool_python.utils.correct(text, tool.check(text))
    except Exception:
        pass
    pathlib.Path(outp).write_text(text, encoding='utf-8')
if __name__ == '__main__':
    if len(sys.argv) < 3:
        print('usage: python nl_spacy_clean.py INPUT.txt OUTPUT.txt'); sys.exit(1)
    main(sys.argv[1], sys.argv[2])
