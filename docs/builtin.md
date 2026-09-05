# builtin - Deep Research: extractors for a filterable job list

STATUS: pending deep research.

## Goal
Find what extractors/selectors/endpoints are available on Built In to pull job
listings into a more filterable list for job-hell (pre-screen before apply).
Document concretely: fetch path (Firecrawl or CamoFox), HTML/AX-tree selectors or
JSON endpoints, the fields each exposes, and which filters can be built on top.

## To research (live, via Firecrawl/CamoFox MCP)
- Public endpoints / embedded JSON / API surface used by the site.
- The listing-card structure in the fetched markdown or accessibility tree.
- Which fields are directly extractable: title, company, location, salary,
  remote flag, posted date, apply URL, job id.
- Which filters each site exposes on its search page (remote, job type,
  experience, pay, date, skills, location).
- Blocks, bot walls, auth gates; the reliable tier (Firecrawl vs CamoFox).
- Pagination / next-page behavior.

## Findings
(pending)
