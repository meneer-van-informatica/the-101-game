@{
  # purpose: fairness-audit-only (not for decisioning)
  enums = @{
    race_codes = @('black','white','asian','mixed','other','unknown','prefer_not')
  }
  person_record = @{
    id = 'uuid-or-studentnr'
    consent = @{
      demographics = $true      # expliciet toestemmingsveld
      as_of = '2025-09-06'
    }
    demographics = @{
      race = @('black')         # self-identified; lijst ondersteunt meerdere
      source = 'self_report'    # nooit 'guess' zonder noodzaak
      notes = ''
    }
    governance = @{
      retention_days = 365
      access = @('owner','editor')  # wie mag dit zien
      purpose = 'bias_audit'
    }
  }
}
