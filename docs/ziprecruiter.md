# ZipRecruiter — extractors

STATUS: VERIFIED (live 2026-09-05; CamoFox anti-detection browser). FireCrawl alone = BLOCKED.

## Fetch
- FireCrawl `/jobs-search?search=<kw>&l=` → persistent `document_antibot` 500 (could NOT get past). Sometimes a thin 200 returns ~70 bytes (empty/404).
- **CamoFox = REQUIRED.** Renders full SERP. Use URL `/jobs-search?search=<kw>` — NOT `/jobs` (404) and needs `search=` (using `q=` silently defaults to "Queens, NY").

## Data surface
A11y tree from CamoFox-rendered DOM. Card structure (`article` per job):
```
heading "<Title>" [level=2]
link "<Company>" /co/<Company>/Jobs/-in-<city>
link "<City>, <ST>" /jobs-search?location=...
<salary>          # "$50K - $70K/yr" | "$15.92/hr" | "$40 - $43/hr"
Quick apply / Save job for later / Estimated pay
```
29 job titles / 30 quick-apply entries in one snapshot (react native search).

## Extractable fields
title, company, location, salary ($XK–$YK/yr or $X/hr), quick-apply badge, posted "New", pay-estimate toggle. No job id / apply URL captured in a11y tree (link targets are `/co/<Company>/Jobs/...`).

## Filters
UI exposes: Remote, Date posted, Experience level, Distance, Employment types — all as page buttons (a11y), not confirmed as URL params. `radius`, `location`, `search` are GET params.

## ToS
No robots issue observed at fetch tier. Login optional (Log In link present); listings render unauthenticated.

## Caveat (antagonize)
Location defaults to the browser's geo (e.g. "338 React native jobs within 25 miles of Queens, NY") and relevance is loose — surfaced titles include generic engineering (Full Stack Engineer, Software Engineer), not only react-native. Pass an explicit `location=` to control geo; expect a mixed–but–real result set.

## Verdict
VERIFIED via CamoFox. FireCrawl cannot clear it. Strategy: CamoFox `/jobs-search?search=<kw>`, parse a11y `article` cards (title/company/location/salary).