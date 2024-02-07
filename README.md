# Issue Backups (WIP)

Small set of scripts, written for [Deno](https://deno.land/),[^1] for backing up GitHub issues and comments using the [GitHub REST API]*(https://docs.github.com/en/rest?apiVersion=2022-11-28). This was built with the TEIC in mind, but the Javascript is repo/organization agnostic. 

This is mostly a wrapper around the standard API--however, the REST API for issues does not include all comment data; the REST API for comments similarly does not include comment data. This script both merges those outputs and converts the Markdown to HTML for later processing.[^2]

## How to use 

Retrieve the JSON for an entire organization's issues and comments (e.g. `TEIC`) 

```bash
deno task backup --org TEIC

# Output in ./issues/TEIC/{repo1, repo2, repo3}.json
```


Retrieve the JSON for a particular repository (e.g. `TEIC/Stylesheets`)

```bash
deno task backup --org TEIC --repo Stylesheets

# Output in ./issues/TEIC/Stylesheets.json
```

See [.github/workflows/build.yml](.github/workflows/build.yml) for an example of using GitHub Actions to automate the backup of issues.

## EXPERIMENTAL TEI CONVERSION

`convert.js` takes the JSON (compiled by `backup.js`) and uses the `gh2cmc.xsl` script to convert a repository's issues to CMC-TEI. Note that this must be run *after* running `backup`.

To convert all retrieved issues from the TEIC folder to TEI: 

```bash
deno task convert ./issues/TEIC

# Output in ./tei/TEIC/{repo1, repo2, repo3}.xml
```

This conversion does not, at present, validate against the latest tei_all (with CMC module) — this is due to the attempts made in `gh2cmc.xsl` to try and parse the serialized HTML produced from markdown (it *almost* works, but there are some edge cases that prove difficult) 



---
[^1]: While this code, in its current form, is not cross-compatible with Node, a Node implementation would just need to rewrite some of the imports and `tasks` scripts in `deno.json`

[^2]: The GitHub API does produce HTML if given the appropriate header (`github/full+json`), but the produced HTML is replete with GitHub specific adornment and is not well-formed (e.g. `<br>`); parsing the markdown in the JavaScript itself is both faster and allows for more control over the output