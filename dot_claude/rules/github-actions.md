---
paths:
  - ".github/workflows/*.yml"
  - ".github/workflows/*.yaml"
  - ".github/actions/**/action.yml"
  - ".github/actions/**/action.yaml"
---

# GitHub Actions rules

## Pin action versions to commit SHAs

Pin GitHub Actions action versions to immutable commit SHAs. Use `pinact` for this after adding or editing workflow or composite-action files that reference actions with `uses:`.

## Lint after editing

After editing any GitHub Actions workflow or composite-action file (under `.github/workflows/` or `.github/actions/`), run `actionlint` on the changed files to catch syntax, expression, and shellcheck issues before committing. `actionlint` is installed locally via Homebrew.

## Adding more rules to this file

When new GitHub Actions guidance gets added (reusable workflow conventions, secrets handling, concurrency patterns, etc.), add it as its own H2 section in this file. Keep each rule short, with at least one concrete *what to do instead* example where applicable.
