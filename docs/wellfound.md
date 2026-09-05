# Wellfound — extractors

STATUS: VERIFIED (live 2026-09-04; Firecrawl + curl)

## Fetch
`/role/l/<role>/<location>` = filterable feed (2,978 results sw-engineer/US, Page 1 of 54). No bot wall, no auth. Firecrawl suffices. `?page=N` paginates server-side.

## Best data surface
Raw HTML has `<script id="__NEXT_DATA__">` (~256KB) with an Apollo GraphQL cache (`pageProps.apolloState.data`) — typed `JobListingSearchResult`: title, compensation, jobType, remote, remoteConfig, yearsExperienceMin/Max, locationNames, liveStartAt (absolute date), id, slug, description. Firecrawl strips `<script>` from markdown, so grep the RAW HTML, not markdown.

## Extractable fields
title, company, location, salary ($ low k–high k / €£), remote flag, absolute posted date (`liveStartAt`), apply URL (`/jobs/<id>-<slug>`), job id (numeric prefix). All in the JSON cache.

## Filters
URL-addressable (path): role, location, remote `/remote`, industry. NOT URL-addressable: salary / experience / job type / recency — client-side only (`?job_type=` is ignored, verified). robots disallows `?role=`,`?jobId=`,`?jobSlug=`,`?preview=`,`/profile/{edit,notifications,review,resume}`, `/jobs/applications`, `/u/`.

## Verdict
PARTIAL (initial report said markdown was the surface; real surface is `__NEXT_DATA__` JSON). Strategy: one Firecrawl call per (role,location), parse the JSON cache, apply salary/exp/type client-side.