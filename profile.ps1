# --- rp alias patch ---
try {
    if (Get-Alias -Name 'rp' -ErrorAction SilentlyContinue) {
        Remove-Item Alias:rp -Force
    }
} catch { }
Set-Alias -Name 'rp' -Value 'Reload-Profile' -Scope Global -Force
# --- end patch ---
