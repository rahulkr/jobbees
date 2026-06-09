# scripts/

Helper scripts. Run from repo root unless otherwise noted.

## coverage.sh — weekly MVP coverage report

Reads `inventory/JOBBees_Feature_Inventory.csv` (gitignored, local-only) and prints how much of the IN + IN★ scope has been completed.

The inventory CSV has a `Your Decision` column (column 9). To mark a feature done, set that cell to one of:

- `done` — minimal
- `done [sprint-3]` — tracked to a specific sprint
- `done [sprint-3, PR#42]` — tracked with PR reference (recommended)

The script handles all three.

### Make it executable (one-time)

```bash
chmod +x scripts/coverage.sh
```

### Usage

```bash
# Summary — used in Friday client call
./scripts/coverage.sh

# Break down by section — see which areas are lagging
./scripts/coverage.sh --by-section

# What did sprint 3 actually complete?
./scripts/coverage.sh --by-sprint 3

# What's still outstanding (full list)
./scripts/coverage.sh --remaining

# Machine-readable for piping into anything
./scripts/coverage.sh --csv
```

### Friday workflow

1. Update the `Your Decision` column for every feature you completed this sprint
2. Run `./scripts/coverage.sh` and `./scripts/coverage.sh --by-section`
3. Paste the output into the Friday call email + meeting notes
4. Commit if any non-inventory changes need to land (the inventory itself is gitignored)
