from pathlib import Path

path = Path('index.html')
text = path.read_text(encoding='utf-8')
marker = """        @media (max-width: 820px) {
            .script-searcher__tabs {
"""
block = """        @media (min-width: 1100px) {
            #px .script-searcher__panels {
                grid-template-columns: repeat(4, minmax(0, 1fr));
                gap: 12px;
            }

            #px .script-searcher__panel {
                min-width: 0;
                padding: 14px;
            }

            #px .script-searcher__panel-controls {
                gap: 4px;
            }

            #px .script-searcher__panel-controls button {
                padding: 4px 8px;
            }

            #px .script-searcher__panel-page {
                min-width: 58px;
            }
        }

"""
exact = """        @media (min-width: 1100px) {
            #px .script-searcher__panels {
"""
assert marker in text, 'Script Searcher mobile breakpoint not found'
if exact not in text:
    text = text.replace(marker, block + marker, 1)
path.write_text(text, encoding='utf-8')
