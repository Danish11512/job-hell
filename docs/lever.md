# Lever — extractors

STATUS: PARTIAL — VERIFIED OPEN + 1 correction (live 2026-09-04; Firecrawl)

## Fetch
No bot wall, no auth. Firecrawl 200 on every endpoint (board, posting, JSON API, robots). Cleanest site — ships a public JSON API. Prior `/notion` 404 = non-customer slug, not a block.

## Best data surface — public JSON API (no auth/key)
`GET https://api.lever.co/v0/postings/<slug>?mode=json` → JSON array per board. gohighlevel = 86 postings, ~2.4MB, one response (no pagination).

Fields per posting: `id` (UUID), `text` (title), `categories` {commitment, department, location, team, allLocations[]}, `workplaceType` (remote/onsite/hybrid), `country`, `createdAt` (epoch-ms = real date), `description`/`descriptionPlain` (full body), `additional`/`additionalPlain` (FREE-TEXT — salary range lives here, regex-parseable), `lists`, `opening`. PLUS `applyUrl` and `hostedUrl` as first-class fields (not derived).
Company NOT in JSON — resolve from board slug/OG tags.

## Extractable fields
title, location, remote (`workplaceType`), posted date (real timestamp), apply URL (`applyUrl`), job id, full description + salary (when disclosed). Bonus: department/team/commitment in one call, no per-job follow-up.

## Filters (server-side on JSON API — verified)
`department`, `location`, `commitment`, `team` — WORK server-side (e.g. departmenEngineering→25, location=US→18, commitment=EE Full-Time→33, team=Affiliates→1).
`workplaceType` — DOES NOT filter server-side (correction: returns full mixed set). Client-side on board UI only. Not faceted: salary, date, experience, skills.

## Pagination
None — full board in one response.

## ToS
robots: `Allow: /`, `Crawl-delay: 1`, AI bots (GPTBot/ClaudeBot/CCBot) disallowed. API public/undocumented-but-stable. Throttle ≤1 req/sec/board.

## Verdict
PARTIAL (open + rich, but correction: `workplaceType` not a server filter; applyUrl/hostedUrl are direct fields). Best simple target — one unauthenticated JSON call per board.