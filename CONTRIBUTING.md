# Contributing

Thanks for considering a contribution! This project follows an **AI-first** workflow.

## How to contribute
1. Open an issue describing the change.
2. Generate your code via AI.
3. Ensure every new/changed source file starts with an **AI-Generated** header:
   - Python: `# AI-Generated: Model=..., Date=..., Prompt="..."` (+ License line)
   - PowerShell: `# AI-Generated: ...`
   - Batch: `REM AI-Generated: ...`
4. Run locally: `.\play.bat`
5. Submit a PR with a short demo (gif/screenshot) if UI changes.

## Scope / Level design
- 10 worlds × 10 levels + 1 final boss = 101.
- Level rhythm: **[Hook 5s] [Do 40s] [Proof 15s] [Next 1s]**
- Each level teaches **exactly one thing**.

## License & provenance
- MIT license (repo).
- Keep headers up to date on refactors.
