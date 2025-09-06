# install_licecap.ps1 — installeert LICEcap via winget en checkt versie
$ErrorActionPreference = 'Stop'
$target = 'Cockos.LICEcap'
winget install --id $target --source winget --accept-package-agreements --accept-source-agreements
$exe = 'C:\Program Files (x86)\LICEcap\licecap.exe'
if (-not (Test-Path $exe)) { throw 'licecap.exe niet gevonden' }
$ver = (Get-Item $exe).VersionInfo.ProductVersion
'OK: LICEcap versie {0} gevonden op {1}' -f $ver, $exe | Write-Host
