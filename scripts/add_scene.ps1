# scripts\add_scene.ps1
# doel: nieuwe scene toevoegen aan de game, chain bijwerken, engine registreren en pushen
# gebruik:
#   overschrijf:  powershell -ExecutionPolicy Bypass -File .\scripts\add_scene.ps1 -Key d_frame -Title 'D frame' -After d_minor -Force
#   auto-index:   powershell -ExecutionPolicy Bypass -File .\scripts\add_scene.ps1 -Key d_frame -Title 'D frame' -After d_minor -AutoIndex
# stijl: Windows-only, enkel quotes

param(
    [Parameter(Mandatory=$true)][string]$Key,
    [Parameter(Mandatory=$true)][string]$Title,
    [string]$After,
    [int]$Minutes = 5,
    [int]$Bpm = 84,
    [string]$Label = 'D',
    [switch]$Force,
    [switch]$AutoIndex
)

$ErrorActionPreference = 'Stop'
function Step { param($m) Write-Host ('[ok] ' + $m) }

# 0) root
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $root
try { chcp 65001 | Out-Null } catch {}

# 1) folders
New-Item -ItemType Directory -Path (Join-Path $root 'scenes') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $root 'scripts') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $root 'data') -Force | Out-Null

# 2) chain file
$chainPath = Join-Path $root 'data\scene_chain.txt'
if (-not (Test-Path $chainPath)) { Set-Content -Path $chainPath -Value '' -Encoding UTF8 }
$chain = Get-Content $chainPath | Where-Object { $_ -ne '' } | ForEach-Object { $_.Trim() }

# 3) default After
if ([string]::IsNullOrWhiteSpace($After)) {
    if ($chain.Count -gt 0) { $After = $chain[-1] } else { $After = '' }
}

# 4) unieke key bepalen
$baseKey = $Key
$scenePath = Join-Path $root ('scenes\' + $Key + '.py')
if (Test-Path $scenePath) {
    if ($Force) {
        Step ('scene bestaat; overschrijven: ' + $scenePath)
    } elseif ($AutoIndex) {
        $i = 2
        while (Test-Path (Join-Path $root ('scenes\' + $baseKey + '_' + $i + '.py'))) { $i++ }
        $Key = $baseKey + '_' + $i
        $scenePath = Join-Path $root ('scenes\' + $Key + '.py')
        Step ('scene bestond; nieuwe key gekozen: ' + $Key)
    } else {
        throw 'scene bestaat al: ' + $scenePath + ' (gebruik -Force of -AutoIndex)'
    }
}

# 5) scene template
$scenePy = @"
# scenes/$Key.py
# scene: $Title
# chained after: $After
import time, sys, math, shutil, msvcrt, argparse

ANSI_CLEAR = '\x1b[2J\x1b[H'
ANSI_HIDE = '\x1b[?25l'
ANSI_SHOW = '\x1b[?25h'

def clamp(n,a,b):
    return a if n<a else b if n>b else n

def draw_bar(width, fill, head='█', body='▓', empty=' '):
    fill = clamp(fill, 0, width)
    if fill<=0: return empty*width
    if fill>=width: return body*(width-1)+head
    return body*(fill-1)+head+empty*(width-fill)

def mmss(sec):
    m = int(sec)//60
    s = int(sec)%60
    return f'{m:02d}:{s:02d}'

def main():
    ap = argparse.ArgumentParser(description='$Title')
    ap.add_argument('-bpm', type=int, default=$Bpm)
    ap.add_argument('-minutes', type=int, default=$Minutes)
    ap.add_argument('-label', type=str, default='$Label')
    args = ap.parse_args()

    bpm = args.bpm
    total_s = max(1, args.minutes*60)
    label = args.label
    start = time.perf_counter()
    last = start
    interval = 60.0/max(1,bpm)
    beat = 0
    running = True
    met = True

    try:
        sys.stdout.write(ANSI_HIDE)
        while running:
            now = time.perf_counter()
            elapsed = now - start
            remain = max(0.0, total_s - elapsed)
            cols = shutil.get_terminal_size((100,30)).columns
            cols = max(60, cols)
            inner = cols - 2

            if met and (now - last) >= interval:
                last += interval
                beat += 1

            while msvcrt.kbhit():
                ch = msvcrt.getch()
                if ch in (b'q', b'Q', b'\x1b'):
                    running = False
                elif ch == b' ':
                    met = not met
                elif ch in (b'+', b'='):
                    bpm = clamp(bpm+2, 20, 220); interval = 60.0/bpm
                elif ch in (b'-', b'_'):
                    bpm = clamp(bpm-2, 20, 220); interval = 60.0/bpm
                elif ch in (b'n', b'N'):
                    print('NEXT:$Key_DONE')
                    running = False

            sys.stdout.write(ANSI_CLEAR)
            sys.stdout.write(' scene: $Title | key: $Key | after: $After | bpm: ' + str(bpm) + ' | tijd: ' + mmss(remain) + '\n')
            sys.stdout.write(' keys: [q]=quit  [space]=metronoom  [+]/[-]=bpm  [n]=next\n\n')

            bar_w = inner
            fill = int((elapsed/interval) % 1 * bar_w) if met else 0
            bar = draw_bar(bar_w, fill)

            for i in range(4):
                pos = int(i*(bar_w/4))
                if pos < len(bar):
                    bar = bar[:pos] + ('┃' if i==0 else '│') + bar[pos+1:]

            sys.stdout.write(' [' + bar + ']\n')

            amp = 6
            width = min(80, inner)
            wave = []
            for x in range(width):
                t = elapsed + x/(width*2.0)
                y = math.sin(2*math.pi*(bpm/60.0)*t)
                lvl = int((y+1)*0.5*amp)
                wave.append('▁▂▃▄▅▆▇'[lvl])
            sys.stdout.write(' hook: ' + ''.join(wave) + '\n')

            prog_fill = int((elapsed/total_s)*bar_w)
            sys.stdout.write(' tijd: [' + draw_bar(bar_w, prog_fill, head='■', body='■', empty='·') + ']\n')

            sys.stdout.flush()
            if not running or remain <= 0: break
            time.sleep(0.01)
    finally:
        sys.stdout.write('\n klaar.\n')
        sys.stdout.write(ANSI_SHOW)
        sys.stdout.flush()

if __name__ == '__main__':
    main()
"@

Set-Content -Path $scenePath -Value $scenePy -Encoding UTF8
Step ('scene geschreven: ' + $scenePath)

# 6) engine registreren (best effort)
$eng = Join-Path $root 'engine.py'
$engineTouched = $false
if (Test-Path $eng) {
    $txt = Get-Content $eng -Raw
    if ($txt -notmatch "'$Key'\s*:\s*'scenes\.$Key'") {
        if ($txt -match 'SCENES\s*=\s*\{') {
            $txt = $txt -replace 'SCENES\s*=\s*\{', "SCENES = {" + "`r`n    '$Key': 'scenes.$Key',"
            $engineTouched = $true
        }
    }
    if ($engineTouched) {
        Copy-Item $eng ($eng + '.bak') -Force
        Set-Content -Path $eng -Value $txt -Encoding UTF8
        Step 'engine.py: SCENES aangevuld'
    } else {
        Step 'engine.py: SCENES niet gevonden of al aanwezig (skip)'
    }
} else {
    Step 'engine.py niet gevonden (skip registratie)'
}

# 7) chain bijwerken (voeg toe als uniek)
$chainNew = @()
$chainNew += $chain
$chainNew += $Key
$chainNew = $chainNew | Where-Object { $_ -ne '' } | Select-Object -Unique
Set-Content -Path $chainPath -Value ($chainNew -join "`r`n") -Encoding UTF8
Step ('chain bijgewerkt: data\scene_chain.txt')

# 8) vorige scene markeren (optioneel)
if ($After) {
    $prevPath = Join-Path $root ('scenes\' + $After + '.py')
    if (Test-Path $prevPath) {
        Add-Content -Path $prevPath -Value ("`n# NEXT: " + $Key)
        Step ('marker toegevoegd aan vorige scene: ' + $After)
    }
}

# 9) runner schrijven
$runnerPath = Join-Path $root ('scripts\play_' + $Key + '.ps1')
$runner = @"
# scripts\play_$Key.ps1
$ErrorActionPreference = 'Stop'
chcp 65001 | Out-Null
try { New-Item -Path 'HKCU:\Console' -Force | Out-Null; New-ItemProperty -Path 'HKCU:\Console' -Name 'VirtualTerminalLevel' -PropertyType DWord -Value 1 -Force | Out-Null } catch {}
cmd /c 'mode con: cols=100 lines=32' | Out-Null
$env:PYTHONUTF8 = '1'
$py = Join-Path $PSScriptRoot '..\.venv\Scripts\python.exe'
$scene = Join-Path $PSScriptRoot ('..\scenes\$Key.py')
& $py $scene -bpm $Bpm -minutes $Minutes -label '$Label'
"@
Set-Content -Path $runnerPath -Value $runner -Encoding UTF8
Step ('runner geschreven: ' + $runnerPath)

# 10) git stage + commit + push (zonder quotes rond variabelen)
$sceneRel  = Join-Path 'scenes' ($Key + '.py')
$runnerRel = Join-Path 'scripts' ('play_' + $Key + '.ps1')
$paths = @($sceneRel, $runnerRel, 'data\scene_chain.txt')
if ($engineTouched) { $paths += 'engine.py' }

git add -- @paths
git commit -m ('feat(scene): add ' + $Key + ' (' + $Title + ') after ' + $After)
Step 'commit gemaakt'
git push origin main
Step 'push voltooid'
Write-Host 'klaar: scene staat online en hangt aan de ketting.'
