$cfg = Get-Content .\data\hue_config.json -Raw | ConvertFrom-Json
$uri = "http://$($cfg.ip)/api/$($cfg.username)/groups/0/action"
$payload = @{ on = $false } | ConvertTo-Json -Compress
Invoke-RestMethod -Uri $uri -Method Put -Body $payload -ContentType 'application/json' | Out-Host
