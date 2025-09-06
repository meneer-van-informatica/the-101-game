@{
  id        = 'rq-labels-dienen-mensen'
  title     = 'Labels dienen mensen, niet andersom'
  created   = '2025-09-06'
  owner     = 'Lucas de Bruin'
  stakeholders = @('Admin','Menno de Bioloog')
  purpose   = 'bias_audit'
  decision_policy = @{
    use_in_decisions = $false
    audit_only       = $true
  }
  go_nogo = @{
    consent_threshold = 0.8
    governance_roles  = @('owner','editor','viewer','responder')
    zero_use_in_logic = $true
  }
  retention_days = 365
  risk_controls = @('self_report_only','prefer_not','aggregate_reporting','small_n_block','separate_storage','quarterly_review')
  product_hook = 'Fairness Inspector for The 101 Game'
  notes = 'Geen demografische features in scoring, ranking of toewijzing; enkel in audit.'
}
