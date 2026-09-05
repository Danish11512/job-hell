# Greenhouse — extractors

STATUS: VERIFIED + antagonize-corrected (live 2026-09-04). Correction: the legacy JSON API is ALIVE — an earlier draft called it dead after testing the malformed no-path `/jobs?token=` form (which 301s).

## Fetch
No bot wall, no auth, no 403. Firecrawl + curl both 200. Embed host migrated 301: `boards.greenhouse.io` → `job-boards.greenhouse.io`.

## Best data surface — legacy JSON API (alive, best structured source)
`https://boards-api.greenhouse.io/v1/boards/<org>/jobs?content=true` → HTTP 200, valid JSON, per-job: title, location, content, departments[], offices[], metadata, internal_job_id, first_published, updated_at, application_deadline, absolute_url.
Also `/v1/boards/<org>/departments` (departments tree). Per-job `/v1/boards/<org>/jobs/<id>` → 200.
Prefer this over markdown parsing.

## Alt surface — embed HTML `window.__remixContext`
`job-boards.greenhouse.io/embed/job_board?for=<org>` embeds a ~33KB JSON blob. Path: `state.loaderData["routes/embed.job_board"].jobPosts.data`. Gives `published_at`/`updated_at` + department path that markdown omits.

## Extractable fields
title, company (`board.name`), location (free-text: "Remote - USA"/"San Francisco, CA"), posted date (`published_at`/`updated_at`, ISO), apply URL (`absolute_url`), job id (`id`=gh_jid). No salary, no remote boolean (infer via location substring).

## Filters
Department, office/location, free-text, custom fields all CLIENT-SIDE (post-hydration). URL params (`?department_id=`, `?office_id=`, `?location=`, `?query=`, `?sort=`) do NOT filter server-side (all return total=171). Server honors only `?page=N` and `?for=<token>`. Filter locally in Python by department.id / location / title / recency.

## Pagination
`?page=N`, 50/page, `total_pages` authoritative (Airbnb: 171 total, 4 pages). Page 5 → empty (no error).

## ToS
robots disallows `/embed/` on both hosts (no enforcement, flag only). Job detail = employer's custom page (Airbnb `careers.airbnb.com/positions/<id>` has Pay Range `$140—$150 USD`) — salary only there, employer-specific.

## Verdict
VERIFIED. Strategy: one JSON API call per org → locally filtered list. Full structured data, no JS needed.