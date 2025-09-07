Param(
  [string]$Docs = "docs",
  [int]$From = 0,
  [int]$To = 9
)
$tpl = Join-Path $Docs "_week.template.html"
if (-not (Test-Path $tpl)) { throw "Template ontbreekt: $tpl" }

$raw = Get-Content $tpl -Raw
for ($i=$From; $i -le $To; $i++){
  $html = $raw.Replace("{{WEEK}}","W$i").Replace("{{WEEKNUM}}","$i")
  $out  = Join-Path $Docs ("W{0}.html" -f $i)
  $null = New-Item -Force -ItemType File -Path $out
  Set-Content $out -Value $html -Encoding UTF8
  Write-Host "→ $out"
}
