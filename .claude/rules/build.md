# Build

Maven multi-module build (root `pom.xml`, packaging `pom`), modules `changelog` and `guides`. All
component artefacts are downloaded from `repo.gentics.com`; nothing is built from sibling
checkouts.

Local build of both modules, without generating mapping files and without rendering the guides
HTML:

```
mvn -B -Dskip.mapping=true -Dskip.doc.package=true package
```

- `-Dskip.mapping=true` — see `changelog.md` → *Mapping files from local builds*.
- `-Dskip.doc.package=true` skips the `Generate HTML` execution in `guides/pom.xml`, which runs
  `guides/build/dockerBuild.sh` in the Docker image `gentics/hugo-asciidoctor:0.154.5`. Leave it
  off when the guides theme, content or Hugo configuration is changed; Docker must then be
  available. That execution accepts exit code 255 as success (`successCodes` `0,255`), so check
  `guides/target/target/html/<major>` (sic, the script resolves its root to `guides/target`)
  instead of trusting the build result. The guides zip packs whatever is in that folder, so with
  `-Dskip.doc.package=true` it contains the HTML of an earlier run, if any.
- Output: `changelog/target/output` (changelog site and `dependency-report.html`),
  `changelog/target/cmp-changelog-<version>.zip`, `guides/target/cmp-guides-<version>.zip`.
- A single module: add `-pl changelog` or `-pl guides`.

CI runs `mvn -U -B -fae clean install` (`ci/Jenkinsfile`). Do not run `deploy` locally.
