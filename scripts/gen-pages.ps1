Param(
  [string]$Docs = "docs"
)

$ErrorActionPreference = "Stop"

# ---------- Data ----------
$weeks = @(
  @{ key="W0";  title="Bits & Logica";        span="L0–L9";  blurb="binaire tel, XOR, K-map, adder." },
  @{ key="W1";  title="Algoritmen";           span="L10–L19"; blurb="lineair/binair, sort, invariant." },
  @{ key="W2";  title="Data & DB";            span="L20–L29"; blurb="ER, 1–3NF, select/project/join." },
  @{ key="W3";  title="Machines";             span="L30–L39"; blurb="FSM, fetch-decode-execute, pijplijn." },
  @{ key="W4";  title="Netwerken";            span="L40–L49"; blurb="pakket, DNS, HTTP, idempotent." },
  @{ key="W5";  title="AI-Basics";            span="L50–L59"; blurb="split, verlies, metric, bias." },
  @{ key="W6";  title="Robot-Choreo";         span="L60–L69"; blurb="states, millis-timing, tempo." },
  @{ key="W7";  title="Sensor & Regel";       span="L70–L79"; blurb="ruis, Kalman-intuïtie, PID." },
  @{ key="W8";  title="Product & Pitch";      span="L80–L89"; blurb="BOM, marge, poster, consent." },
  @{ key="W9";  title="Ethiek & Show";        span="L90–L99"; blurb="veiligheid, no-face, publiek." }
)
$finale = @{ key="L100"; title="Finale"; blurb="‘alles samen’ bossfight met 3 checks." }

# ---------- Helpers ----------
function New-Dir($p){ if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p | Out-Null } }
function Write-File($path,$content){ $utf8NoBom = New-Object System.Text.UTF8Encoding($false); [IO.File]::WriteAllText($path,$content,$utf8NoBom) }

# ---------- Voorbereiden ----------
New-Dir $Docs
$noj = Join-Path $Docs ".nojekyll"
if (-not (Test-Path $noj)) { New-Item -ItemType File -Path $noj | Out-Null }

# ---------- Styles (mini, donker) ----------
$STYLE = @"
<style>
 :root{--bg:#0b0b10;--panel:#151823;--line:#202635;--muted:#9aa4b2;--txt:#e8e8f0;--acc:#6cf}
 *{box-sizing:border-box} body{margin:0;background:var(--bg);color:var(--txt);font:16px/1.55 system-ui,Segoe UI,Roboto,Inter}
 header{padding:22px 18px;border-bottom:1px solid #222;background:#0e1118}
 h1{margin:0;font-size:22px} .sub{color:var(--muted);font-size:13px}
 main{max-width:1100px;margin:24px auto;padding:0 16px}
 .grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(210px,1fr));gap:14px}
 .card{background:var(--panel);padding:16px;border-radius:12px;border:1px solid var(--line);transition:transform .12s,border-color .12s}
 .card:hover{transform:translateY(-2px);border-color:#2a3750}
 .btn{display:inline-block;margin-top:10px;padding:8px 11px;border-radius:9px;border:1px solid var(--line);color:var(--txt);text-decoration:none}
 .btn:hover{border-color:var(--acc);color:var(--acc)}
 .tag{font-size:12px;color:var(--muted)}
 pre{background:#141821;border:1px solid #222a35;padding:14px;border-radius:10px;overflow:auto}
 a{color:#9bd;text-decoration:none} a:hover{color:#acf}
 .hero{display:flex;gap:18px;flex-wrap:wrap;background:#0e1118;border:1px solid #1a2030;border-radius:14px;padding:16px}
 .hero h2{margin:0}
 footer{opacity:.7;text-align:center;margin:40px 0 28px}
</style>
"@

# ---------- Index ----------
$INDEX = @"
<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>the-101-game — Bommel (v1.0)</title>
$STYLE
<header>
  <h1>the-101-game — Versie B <span class="sub">(Bommel, v1.0)</span></h1>
  <div class="sub">Kies een week (W0..W9) of bekijk de wereldkaart / finale. Repo: <a href="https://github.com/meneer-van-informatica/the-101-game">GitHub</a></div>
</header>
<main>
  <section class="hero">
    <div style="flex:1 1 320px;min-width:280px">
      <h2>W0 — Bits & Logica</h2>
      <div class="tag">L0–L9 · binaire tel, XOR, K-map, adder.</div>
      <p>Start hier als ‘first page’. De live demo’s sluiten aan op je PowerShell-show (on, red, bleep, show, …).</p>
      <a class="btn" href="./W0.html">Open W0</a>
      <a class="btn" href="./wereldkaart.html" style="margin-left:8px">Wereldkaart</a>
    </div>
    <div style="flex:1 1 280px;min-width:240px">
      <h2>Finale — L100</h2>
      <div class="tag">‘alles samen’ bossfight met 3 checks.</div>
      <p>Checkpoint voor publiek: veiligheid, ethiek en live show.</p>
      <a class="btn" href="./L100.html">Open L100</a>
    </div>
  </section>

  <h2 style="margin:22px 0 10px">Wekenoverzicht</h2>
  <section class="grid" id="grid"></section>

  <h2 style="margin:26px 0 10px">Kaders</h2>
  <div class="grid">
    <div class="card">
      <b>Software vs Hardware vs Firmware (Economie)</b>
      <div class="tag">kosten, marge, lifecycle, capaciteiten</div>
      <a class="btn" href="./sw-hw-fw.html">Open</a>
    </div>
    <div class="card">
      <b>#route-4</b>
      <div class="tag">vier sporen naar resultaat</div>
      <a class="btn" href="./route-4.html">Open</a>
    </div>
  </div>
</main>
<footer>© meneer-van-informatica · GitHub Pages</footer>
<script>
  const WEEKS = $([System.Web.Script.Serialization.JavaScriptSerializer]::new().Serialize($weeks))
  const grid = document.getElementById('grid');
  WEEKS.forEach(w => {
    const el = document.createElement('div');
    el.className='card';
    el.innerHTML = `
      <div class="w"><b>${w.key}</b> · ${w.title}</div>
      <div class="tag">${w.span ?? ""} ${w.blurb ?? ""}</div>
      <a class="btn" href="./${w.key}.html">Open ${w.key}</a>`;
    grid.appendChild(el);
  });
</script>
"@
Write-File (Join-Path $Docs "index.html") $INDEX
Write-Host "→ $Docs\index.html"

# ---------- Week template ----------
function WeekHtml($w){
@"
<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>the-101-game · $($w.key) — $($w.title)</title>
$STYLE
<header>
  <a href="./index.html">← terug naar overzicht</a>
  <h1 style="margin:6px 0 0">$($w.key) — $($w.title)</h1>
  <div class="sub">$($w.span) · $($w.blurb)</div>
</header>
<main>
  <h2>Live demo (PowerShell)</h2>
  <pre>
  . \$PROFILE
  on
  red
  bleep
  bloop
  tik
  tok
  loop 30s
  show
  test -Transcript
  </pre>

  <h2>Uitleg / materiaal</h2>
  <p>Hier komt je weekcontent (slides, opdrachten, links). Werk dit per week bij.</p>

  <p><a class="btn" href="./index.html">← Terug</a></p>
</main>
"@
}

# ---------- Finale ----------
$L100 = @"
<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>the-101-game · L100 Finale</title>
$STYLE
<header>
  <a href="./index.html">← terug naar overzicht</a>
  <h1 style="margin:6px 0 0">L100 — Finale</h1>
  <div class="sub">$($finale.blurb)</div>
</header>
<main>
  <h2>Bossfight met 3 checks</h2>
  <ol>
    <li>Techniek: systeem werkt end-to-end.</li>
    <li>Ethiek & veiligheid: verantwoord voor publiek (no-face waar nodig).</li>
    <li>Presentatie: korte pitch + live ‘show’ (licht/geluid).</li>
  </ol>
  <p><a class="btn" href="./index.html">← Terug</a></p>
</main>
"
Write-File (Join-Path $Docs "L100.html") $L100
Write-Host "→ $Docs\L100.html"

# ---------- Wereldkaart ----------
$WORLD = @"
<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>the-101-game · Wereldkaart</title>
$STYLE
<header>
  <a href="./index.html">← terug naar overzicht</a>
  <h1 style="margin:6px 0 0">Wereldkaart (voorbeeld)</h1>
  <div class="sub">Pas aan zoals jij wil.</div>
</header>
<main>
  <p>Plaats hier een SVG/PNG kaart, hotspots per week, of een route door de stof.</p>
  <pre>
  Ideeën:
  - W0..W9 markers met korte tooltips
  - Click → naar de weekpagina
  - Kleine legendes (HW/SW/FW)
  </pre>
  <p><a class="btn" href="./index.html">← Terug</a></p>
</main>
"
Write-File (Join-Path $Docs "wereldkaart.html") $WORLD
Write-Host "→ $Docs\wereldkaart.html"

# ---------- Kaders ----------
$SWHWFW = @"
<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Software vs Hardware vs Firmware (Economie)</title>
$STYLE
<header>
  <a href="./index.html">← terug</a>
  <h1 style="margin:6px 0 0">Software vs Hardware vs Firmware (Economie)</h1>
</header>
<main>
  <ul>
    <li><b>Software</b>: snel itereren, lage marginale kosten, release-tempo.</li>
    <li><b>Hardware</b>: BOM, marge, supply chain, certificering.</li>
    <li><b>Firmware</b>: brug tussen beiden; lifecycle & updates.</li>
  </ul>
  <p><a class="btn" href="./index.html">← Terug</a></p>
</main>
"
Write-File (Join-Path $Docs "sw-hw-fw.html") $SWHWFW
Write-Host "→ $Docs\sw-hw-fw.html"

$ROUTE4 = @"
<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>#route-4</title>
$STYLE
<header>
  <a href="./index.html">← terug</a>
  <h1 style="margin:6px 0 0">#route-4</h1>
</header>
<main>
  <p>Vier sporen naar resultaat (vul jouw eigen invulling aan):</p>
  <ol>
    <li>Concept → mock → user feedback</li>
    <li>Tech spike → MVP → hardening</li>
    <li>Data → model → metric → bias check</li>
    <li>Show → publiek → veiligheid → ethiek</li>
  </ol>
  <p><a class="btn" href="./index.html">← Terug</a></p>
</main>
"
Write-File (Join-Path $Docs "route-4.html") $ROUTE4
Write-Host "→ $Docs\route-4.html"

# ---------- Per week schrijven ----------
foreach($w in $weeks){
  $out = Join-Path $Docs ("{0}.html" -f $w.key)
  Write-File $out (WeekHtml $w)
  Write-Host "→ $out"
}

Write-Host "✅ Pages klaar. Zet GitHub Pages op main /docs."
