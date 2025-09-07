off; film; red; pause; powershell -File .\scripts\run.ps1

```
abn open                 # open ABN login (jij logt zelf in)
abn add 1234,56          # sla saldo op (komma of punt)
abn                      # laat je laatste saldo + tijd zien
abn trend                # ASCII-trend (laatste 30 dagen)
abn hue                  # zet HUE groen/rood op basis van drempel (default €100)
abn hue -ok 250          # drempel aanpassen voor deze call
```

```
shot           # screenshot maken (alle monitoren)
shotqr         # QR uit klembord / laatste shot_*.png uitlezen
shotqr -Copy   # en meteen 1e payload naar je klembord
qr             # doe beide: shot -> decode -> copy
```
