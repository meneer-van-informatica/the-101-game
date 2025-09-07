Param([switch]$Transcript)

# Optioneel transcript
if ($Transcript) {
  if (Get-Command export-on -ErrorAction SilentlyContinue) { export-on }
}

# Helper om veilig functies aan te roepen
function Try-Call($name, $args) {
  if (Get-Command $name -ErrorAction SilentlyContinue) {
    & $name @args
  } else {
    Write-Host "(skip) $name ontbreekt"
  }
}

$steps = @(
  @{ Title="Lights ON";    Fn="on";     Args=@() },
  @{ Title="Red";          Fn="red";    Args=@() },
  @{ Title="Green";        Fn="green";  Args=@() },
  @{ Title="Blue";         Fn="blue";   Args=@() },
  @{ Title="Orange";       Fn="orange"; Args=@() },
  @{ Title="Bleep";        Fn="bleep";  Args=@() },
  @{ Title="Bloop";        Fn="bloop";  Args=@() },
  @{ Title="Tik";          Fn="tik";    Args=@() },
  @{ Title="Tok";          Fn="tok";    Args=@() },
  @{ Title="Loop 5s";      Fn="loop";   Args=@("5s") },
  @{ Title="Show (kort)";  Fn="show";   Args=@() },
  @{ Title="Lights OFF";   Fn="off";    Args=@() }
)

$idx = 0
foreach($s in $steps){
  $idx++
  $pct = [int](($idx / $steps.Count) * 100)
  
  # Gedimd: toon eerst de status van het commando (Hint)
  Write-Progress -Activity "De-101 game · test" -Status "Next: $($s.Title)" -PercentComplete $pct
  Write-Host "`t[HINT]: Press Enter to proceed to command: $($s.Title)" -ForegroundColor DarkGray
  
  # Wacht op userinput (enter)
  $input = Read-Host "Press Enter to continue"
  
  Try-Call $s.Fn $s.Args
  Start-Sleep -Milliseconds 700
}

Write-Progress -Activity "the-101-game · test" -Completed
if ($Transcript) { if (Get-Command export-off -ea 0) { export-off } }
Write-Host "✅ Test afgerond." -ForegroundColor Green
