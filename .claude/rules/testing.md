# Testing

This repository has no automated tests (no `src/test`, no test plugins in any `pom.xml`). A change
is verified by building and inspecting the result:

- Changelog, mappings, templates: build (`build.md`) and check the affected pages in
  `changelog/target/output` (`index.html`, `<major>/…`, `dependency-report.html`). A mapping entry
  whose file name does not match an entry in `changelog/target/changelogs/<component>/entries` is
  a defect, even if the build succeeds (`strictRenderMode` is `false` in `changelog/pom.xml`).
- Guides theme and content: build without `-Dskip.doc.package` and check the generated HTML
  (`build.md`).
- Helm chart: see `helm-chart.md`.

Say which of these checks were run and which were not; do not report a change as tested on the
strength of a green Maven build alone.
