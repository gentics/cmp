---
paths:
  - "changelog/**"
---

# Changelog

**This repository has no changelog entries of its own**. The combined changelog is generated from
the entries published by the components (`changelog/pom.xml`, execution `unpack-changelogs`, into
`changelog/target/changelogs/<component>/entries`). A new or corrected entry text belongs in the
component's own repository, following that repository's changelog rules. Ask the user for its
location if it is not obvious.

Component IDs, as configured in `changelog/pom.xml` (`changelog-manager-plugin` → `components`):
`cms`, `aloha`, `mesh`, `meshsql`, `meshplugins`, `portaljava`, `portalphp`.
Allowed entry types (`changelogTypes`): `manualchange`, `feature`, `enhancement`, `bugfix`,
`documentation`, `optional-manualchange`, `security`.

## What is maintained here

- `changelog/src/base/mappings/<component>_<cmp-version>.json` — which entry files of a component
  belong to a CMP version (`changeLogEntryFileNames`, `componentVersion`, `version`, `date`).
  Jenkins generates them in the release build and commits them with the
  `Prepare for the next development iteration` commit (e.g. `d6e5d21`). Manual corrections add or
  fix entry file names in an existing mapping (e.g. `4556273`, `75c7386`); the names must match
  the entry file names exactly, including the type (`optional-manualchange`, not
  `optional-manual-change`).
- `changelog/src/base/mappings/<component>_skiplist_<major>.0.lst` — one entry file name per line;
  a new set is added for every CMP major version (e.g. `2b18820` "Add CMP 8.6 skiplists").
  When the mapping for a new version is generated (`changelog-manager-plugin` 3.0.3,
  `ChangelogUtils.createChangelogFromUnmappedEntries`), an entry already mapped to an older
  version and listed in the skiplist of the new version's major is not mapped again.
- `changelog/src/base/mappings/<component>_ignore.lst` (currently only `aloha_ignore.lst`) — entry
  file names, one per line, that are never mapped to any version.
- `changelog/majorversions.json` — the release date and the customer-facing description of each
  CMP major version, newest first.
- `changelog/src/base/templates`, `changelog/src/base/static` — Velocity templates, CSS, JS and
  icons of the generated site and the dependency report.

## Mapping files from local builds

With `skip.mapping=false` (the default in the root `pom.xml`) the build writes a mapping file for
the current `-SNAPSHOT` version into `changelog/src/base/mappings`, e.g.
`cms_8.3.23-SNAPSHOT.json`. Never commit them. Build locally with `-Dskip.mapping=true` (see
`build.md`).
