# RQ — Labels dienen mensen, niet andersom

**Research Question (RQ)**  
Hoe labelen we identiteiten (bijv. 'zwart'/'wit') in code zó dat labels mensen dienen (fairness-audit) en nooit beslissingen sturen of schade veroorzaken?

## Samenvatting
- Typsnelheid en prestaties zijn grotendeels trainbaar; demografische labels zijn *niet* voor besluitvorming maar alleen voor fairness-meting.  
- Labels worden vrijwillig, met toestemming en doelbinding vastgelegd ('bias_audit'), met retentie en toegang strak begrensd.  
- Operatiemodellen en beoordelingslogica gebruiken géén demografische features. Audits en rapportages wel, gescheiden van beslissingen.  
- We publiceren een transparant schema en een controlelijst; zonder voldane voorwaarden: geen data.

## Document (kader en spelregels)
**Scope**  
- Domein: The 101 Game, onderwijscontext.  
- Data: vrijwillige self-report demografie, prestatiemetingen (wpm, fouten, scores), technische logs.  

**Definities**  
- 'Demografie': vrijwillig self-report, meervoudig mogelijk; geen 'guess'.  
- 'Fairness-audit': statistische vergelijking van uitkomsten per groep met onzekerheid en context.

**Constraints**  
- Consent verplicht, purpose 'bias_audit', minimale retentie, beperkte toegang.  
- Geen gebruik van demografie in beslislogica, scoring, ranking of toewijzing.

**Data-handling**  
- Schema: zie 'data\demographics_schema.psd1'.  
- Opslag: versleuteld of afgeschermd; in repo alléén example-schema, geen echte persoonsdata.  
- Retentie: standaard 365 dagen of korter; periodiek wissen.

**Metriek en rapportage**  
- Meet wpm, foutenpercentages, deelname; rapporteer gemiddelden, sd, en betrouwbaarheidsintervallen per groep.  
- Geen ordinale codering voor demografie; gebruik one-hot of sets.

**Risico's en mitigatie**  
- Mislabeling: uitsluitend self-report en 'prefer_not'.  
- Re-identificatie: aggregatie, drempels, geen small-n tabellen.  
- Scope-drift: expliciete 'purpose' en reviewmomenten per kwartaal.

**Go/No-Go check (voor elke cohort)**  
- Consent ≥ 80 procent en 'prefer_not' gerespecteerd → go.  
- Governance vastgelegd (owner, viewer, editor, responder) → go.  
- Beslislogica geaudit op zero-use van demografie → go.  
- Voorwaarden niet voldaan → no-go: géén demografiedata verzamelen.

## Reden van vastleggen
- Pedagogisch: leerlingen beschermen en begrijpelijk maken wat meten wel/niet betekent.  
- Juridisch-ethisch: doelbinding, dataminimalisatie, audittrail.  
- Operationeel: herhaalbare, veilige workflow en minder incidenten.

## AI-producthaak
- 'Fairness Inspector' voor The 101 Game: script dat je CSV's leest, veilige tabellen maakt, drempelchecks doet en een 'fairness_report.md' schrijft.

## Zodat we niet in de problemen komen
- Checklists voor consent, access, retentie en publicatie.  
- Scripts blokkeren automatisch committen van echte persoonsdata; alleen example-schema's in repo.

## Of gewoon niet doen
- Als consent laag is, of risico op schade reëel, of het leerdoel ook zonder labels haalbaar is, dan doen we het niet en rapporteren we zonder demografie.
