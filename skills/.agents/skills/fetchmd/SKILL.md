---
name: fetchmd
description: Last-resort URL fetcher via the local `fetchmd` CLI (~/.local/bin/fetchmd). Always try WebFetch first. Invoke this only when normal fetching has actually failed in this conversation (the page returned 403 or blocked WebFetch, the summary lost text needed verbatim, or firecrawl's main-content heuristic dropped the article on nrk.no and similar sites), or when the user asks for fetchmd by name. Not for search, crawling, or JS-only SPAs.
---

# fetchmd

Local URL → markdown fetcher. Plain HTTP GET with a browser User-Agent, main-content
extraction via trafilatura, YAML front matter with title/author/date. Ignores robots.txt.
Runs via `uv run --script` (deps cached on first run).

```sh
fetchmd URL [URL ...]      # main content as markdown + front matter
fetchmd --full URL         # whole page → markdown (use if extraction dropped something)
fetchmd --raw URL          # raw HTML
fetchmd --no-meta URL      # no front matter
fetchmd -o out.md URL      # write to file
```

Notes:
- If extraction finds <200 chars it auto-falls back to `--full` (message on stderr).
- Extraction drops paragraphs that are entirely a link; use `--full` when exact completeness matters.
- No JS rendering. For SPAs that need a browser, fall back to `firecrawl scrape --include-tags article URL`
  or `firecrawl scrape URL` (do NOT use `--only-main-content` on nrk.no).
- Quote content verbatim; do not paraphrase figures.
