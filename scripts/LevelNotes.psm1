# scripts\LevelNotes.psm1

function New-LevelIdea {
    param(
        [Parameter(Mandatory=$true)][string]$Title,
        [ValidateSet('level','mechanic','narrative','tech','idea')][string]$Type='idea',
        [string[]]$Tags=@(),
        [string[]]$Links=@()
    )
    $notesDir = Join-Path (Get-Location) 'notes'
    if (-not (Test-Path $notesDir)) { New-Item -ItemType Directory -Path $notesDir | Out-Null }

    $ts = Get-Date -Format 'yyyy-MM-dd-HHmmss'
    $slug = ($Title.ToLower() -replace '[^a-z0-9]+','-').Trim('-')
    if ([string]::IsNullOrWhiteSpace($slug)) { $slug = 'untitled' }
    $id = $ts + '-' + $slug
    $path = Join-Path $notesDir ($id + '.md')

    $tagsLine  = 'tags: [' + (($Tags | Sort-Object -Unique) -join ', ') + ']'
    $linksLine = 'links: [' + (($Links | Sort-Object -Unique) -join ', ') + ']'
    $created   = (Get-Date -Format 's')

    $lines = @(
        '---',
        'id: ' + $id,
        'title: ' + $Title,
        'type: ' + $Type,
        $tagsLine,
        $linksLine,
        'created: ' + $created,
        '---',
        '',
        '# Notes',
        '',
        '## Links'
    )
    foreach ($l in $Links) { $lines += ('[[' + $l + ']]') }
    $lines += @(
        '',
        '## Tasks',
        '- [ ] define win condition',
        '- [ ] 90s demo path'
    )
    Set-Content -Path $path -Value $lines -Encoding UTF8
    Write-Output $path
}

function Add-Links {
    param(
        [Parameter(Mandatory=$true)][string]$IdOrFile,
        [Parameter(Mandatory=$true)][string[]]$Links
    )
    $file = if (Test-Path $IdOrFile) { $IdOrFile } else { Join-Path 'notes' ($IdOrFile + '.md') }
    if (-not (Test-Path $file)) { throw 'note not found' }
    Add-Content -Path $file -Value '## Links'
    foreach ($l in ($Links | Sort-Object -Unique)) {
        Add-Content -Path $file -Value ('[[' + $l + ']]')
    }
}

function Add-Tags {
    param(
        [Parameter(Mandatory=$true)][string]$IdOrFile,
        [Parameter(Mandatory=$true)][string[]]$Tags
    )
    $file = if (Test-Path $IdOrFile) { $IdOrFile } else { Join-Path 'notes' ($IdOrFile + '.md') }
    if (-not (Test-Path $file)) { throw 'note not found' }

    $content = Get-Content -Path $file -Raw
    $tagsNew = ($Tags | Sort-Object -Unique)
    if ($content -match 'tags:\s*\[(.*?)\]') {
        $existing = ($matches[1] -split '\s*,\s*') | Where-Object { $_ -ne '' } | Sort-Object -Unique
        $merged = ($existing + $tagsNew) | Sort-Object -Unique
        $mergedLine = 'tags: [' + ($merged -join ', ') + ']'
        $content = [regex]::Replace($content,'tags:\s*\[(.*?)\]',$mergedLine,1)
    } else {
        $insert = 'tags: [' + ($tagsNew -join ', ') + ']'
        $content = $content -replace 'type:\s*(\S+)', 'type: $1' + [Environment]::NewLine + $insert
    }
    Set-Content -Path $file -Value $content -Encoding UTF8
}

function Find-Notes {
    param(
        [string]$Tag,
        [string]$Text,
        [string]$LinkTo
    )
    $files = Get-ChildItem -Path 'notes' -Filter '*.md' -File -ErrorAction SilentlyContinue
    $rows = foreach ($f in $files) {
        $raw = Get-Content -Path $f.FullName -Raw
        $id    = if ($raw -match '(?m)^\s*id:\s*(.+)$')    { $matches[1].Trim() } else { [IO.Path]::GetFileNameWithoutExtension($f.Name) }
        $title = if ($raw -match '(?m)^\s*title:\s*(.+)$') { $matches[1].Trim() } else { $id }
        $tags  = if ($raw -match '(?m)^\s*tags:\s*\[(.*?)\]') { ($matches[1] -split '\s*,\s*') } else { @() }
        $ok = $true
        if ($Tag)    { $ok = $ok -and ($tags -contains $Tag) }
        if ($Text)   { $ok = $ok -and ($raw -match [regex]::Escape($Text)) }
        if ($LinkTo) { $ok = $ok -and ($raw -match '\[\[' + [regex]::Escape($LinkTo) + '\]\]') }
        if ($ok) {
            [pscustomobject]@{ Id=$id; Title=$title; Tags=($tags -join ' '); Path=$f.FullName }
        }
    }
    $rows | Sort-Object Title | Format-Table -AutoSize
}

function Start-BrainDump {
    param([string]$Id)
    if ($Id) {
        $file = if (Test-Path $Id) { $Id } else { Join-Path 'notes' ($Id + '.md') }
        if (-not (Test-Path $file)) { throw 'note not found' }
    } else {
        $daily = Join-Path 'notes' ((Get-Date -Format 'yyyy-MM-dd') + '-daily.md')
        if (-not (Test-Path $daily)) {
            Set-Content -Path $daily -Value @(
                '---',
                'id: ' + (Get-Date -Format 'yyyy-MM-dd') + '-daily',
                'title: daily brain dump',
                'type: journal',
                'tags: [journal]',
                'links: []',
                'created: ' + (Get-Date -Format 's'),
                '---',
                '',
                '# Dump'
            ) -Encoding UTF8
        }
        $file = $daily
    }
    Write-Host 'dump mode, lege regel om te stoppen'
    while ($true) {
        $line = Read-Host '⟫'
        if ([string]::IsNullOrWhiteSpace($line)) { break }
        Add-Content -Path $file -Value ('- ' + (Get-Date -Format 'HH:mm:ss') + ' ' + $line)
    }
    Write-Output $file
}

function Open-LastNote {
    $last = Get-ChildItem -Path 'notes' -Filter '*.md' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($null -eq $last) { throw 'no notes yet' }
    Start-Process notepad.exe $last.FullName | Out-Null
}

function Get-NotesData {
    $dir = Join-Path (Get-Location) 'notes'
    if (-not (Test-Path $dir)) { return @() }
    $files = Get-ChildItem -Path $dir -Filter '*.md' -File
    $notes = foreach ($f in $files) {
        $raw = Get-Content -Path $f.FullName -Raw
        $id    = if ($raw -match '(?m)^\s*id:\s*(.+)$')    { $matches[1].Trim() } else { [IO.Path]::GetFileNameWithoutExtension($f.Name) }
        $title = if ($raw -match '(?m)^\s*title:\s*(.+)$') { $matches[1].Trim() } else { $id }
        $tags  = if ($raw -match '(?m)^\s*tags:\s*\[(.*?)\]') { ($matches[1] -split '\s*,\s*') | Where-Object { $_ -ne '' } } else { @() }
        $matchesLinks = [regex]::Matches($raw, '\[\[([^\]]+)\]\]')
        $links = @(); foreach ($m in $matchesLinks) { $links += $m.Groups[1].Value.Trim() }
        [pscustomobject]@{ Id=$id; Title=$title; Tags=$tags; File=$f; Links=($links | Sort-Object -Unique) }
    }
    return $notes
}

function Export-NotesGraph {
    param([string]$OutFile = (Join-Path 'docs' 'graph.md'))
    $notes = Get-NotesData
    if ($notes.Count -eq 0) { throw 'no notes found' }
    $docs = Split-Path $OutFile -Parent
    if (-not (Test-Path $docs)) { New-Item -ItemType Directory -Path $docs | Out-Null }

    $idToNode = @{}
    $i = 0
    foreach ($n in $notes) { $idToNode[$n.Id] = 'n' + $i; $i++ }

    $nodeLines = New-Object System.Collections.Generic.HashSet[string]
    $edgeLines = New-Object System.Collections.Generic.HashSet[string]

    foreach ($n in $notes) {
        $nid = $idToNode[$n.Id]
        $label = $n.Title.Replace('"','&quot;')
        $null = $nodeLines.Add('  ' + $nid + '["' + $label + '"]')
        foreach ($link in $n.Links) {
            if (-not $idToNode.ContainsKey($link)) {
                $idToNode[$link] = 'nX' + ($idToNode.Count)
                $null = $nodeLines.Add('  ' + $idToNode[$link] + '["' + $link.Replace('"','&quot;') + '"]')
            }
            $a = $nid
            $b = $idToNode[$link]
            $null = $edgeLines.Add('  ' + $a + ' --> ' + $b)
        }
    }

    $content = @()
    $content += '```mermaid'
    $content += 'graph TD'
    $content += ($nodeLines | Sort-Object)
    $content += ($edgeLines | Sort-Object)
    $content += '```'
    Set-Content -Path $OutFile -Value $content -Encoding UTF8
    return $OutFile
}

function Export-NotesIndex {
    param([string]$OutFile = (Join-Path 'docs' 'README.md'))
    $notes = Get-NotesData | Sort-Object Title
    if ($notes.Count -eq 0) { throw 'no notes found' }
    $docs = Split-Path $OutFile -Parent
    if (-not (Test-Path $docs)) { New-Item -ItemType Directory -Path $docs | Out-Null }

    $lines = @()
    $lines += '# Notes index'
    $lines += ''
    $lines += 'Zie ook: de graaf in [graph.md](./graph.md).'
    $lines += ''
    foreach ($n in $notes) {
        $rel = [IO.Path]::Combine('..','notes',[IO.Path]::GetFileName($n.File.FullName)) -replace '\\','/'
        $tagStr = if ($n.Tags.Count -gt 0) { ' - tags: ' + ($n.Tags -join ' ') } else { '' }
        $lines += '- [' + $n.Title + '](' + $rel + ')' + $tagStr
    }
    Set-Content -Path $OutFile -Value $lines -Encoding UTF8
    return $OutFile
}

function Export-NotesSite {
    param([string]$OutFile = (Join-Path 'docs' 'index.html'))
    $graphFile = Export-NotesGraph
    $indexFile = Export-NotesIndex
    $graph = Get-Content -Path $graphFile -Raw
    $m = [regex]::Match($graph, '```mermaid(.*?)```', 'Singleline')
    if (-not $m.Success) { throw 'mermaid block not found' }
    $mermaidGraph = $m.Groups[1].Value.Trim()

    $html = @'
<!doctype html>
<html>
<head>
<meta charset='utf-8'>
<meta name='viewport' content='width=device-width, initial-scale=1'>
<title>Notes graph</title>
</head>
<body>
<h1>Notes graph</h1>
<div class='mermaid'>
'@ + $mermaidGraph + @'
</div>
<h2>Index</h2>
<p>Zie <a href='./README.md'>README.md</a> voor de lijst.</p>
<script src='https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js'></script>
<script>mermaid.initialize({startOnLoad:true});</script>
</body>
</html>
'@
    Set-Content -Path $OutFile -Value $html -Encoding UTF8
    return $OutFile
}

function Publish-Notes {
    param([string]$Message = 'export notes graph and index')
    $null = Export-NotesGraph
    $null = Export-NotesIndex
    git add docs notes | Out-Null
    git commit -m $Message
    git push
}

Export-ModuleMember -Function New-LevelIdea,Add-Links,Add-Tags,Find-Notes,Start-BrainDump,Open-LastNote,Get-NotesData,Export-NotesGraph,Export-NotesIndex,Export-NotesSite,Publish-Notes
