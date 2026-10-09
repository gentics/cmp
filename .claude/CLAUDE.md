# Gentics CMP — Guidelines

Generic workflow for resolving a task (bug fix, enhancement, or feature) in this repository.
Topic rules live in `.claude/rules/`: `build.md`, `testing.md`, `changelog.md`, `helm-chart.md`.

## What this repository is

CMP (Content Management Platform) bundles released versions of the Gentics components. It
contains no product code. It produces three artefacts:

- `changelog` (`cmp-changelog`) — the combined CMP changelog and dependency report. It unpacks
  the changelog entries (`entries` / `changelog-entries` zips) and dependency reports of the
  component versions from the Maven repository and renders them with the
  `com.gentics:changelog-manager-plugin` (templates in `changelog/src/base/templates`).
- `guides` (`cmp-guides`) — the combined Guides site (Hugo + Asciidoctor, theme in
  `guides/src/main/hugo/themes/gentics`). It unpacks the guides content of ANDP, the Mesh
  commercial plugins and both Portals, and the `openapi.yaml` of Mesh, CMS OSS and CMS EE.
- `cmp-chart` — the CMP umbrella Helm chart over the `cms`, `gentics-mesh`,
  `gentics-portal-java` and `gentics-portal-php` charts, plus the library chart
  `cmp-chart/charts/gentics-common`. It is not a Maven module; see `rules/helm-chart.md`.

## Component versions

The bundled component versions are the properties in the root `pom.xml` (`cms-oss.version`,
`cms.version`, `aloha.version`, `mesh.version`, `meshsql.version`, `mesh.plugins.version`,
`portal.java.version`, `portal.php.version`, `andp.version`). They are changed in separate
`Bump Versions` commits. Do not change them as part of a task, unless the task requires it or
the user has explicitly requested it.

A defect in a component's own changelog text, guide or OpenAPI specification is fixed in that
component's repository, not here: this repository only consumes the published artefacts.

## Releases

Releases are done by Jenkins (`ci/Jenkinsfile`, parameters `runDeploy` and `release`). The
release commit also writes the mapping files and the `cmp-chart/Chart.yaml` dependency versions
(see `rules/changelog.md` and `rules/helm-chart.md`).

## Java

CI builds with `JAVA_HOME=$JAVA_1_11_HOME` (`ci/Jenkinsfile`); the build compiles no Java code
and also succeeds with JDK 21. Check that `JAVA_HOME` points to a JDK; if it is not set, set it
for the current session.

## Order of work

0. Verify the versions of Gentics CMP components being included into the forthcoming release, 
by checking the latest version tag in the component's repository and corresponding hotfix/release branch:
- Mesh OSS: https://github.com/gentics/mesh
- Mesh EE: https://git.gentics.com/psc/mesh/mesh-enterprise
- Mesh Commercial Plugins: https://github.com/gentics/mesh-commercial-plugins
- Portal|Java: https://git.gentics.com/psc/products/portal-java
- Portal|PHP: https://git.gentics.com/psc/products/portal-php
- CMS OSS: https://github.com/gentics/cms-oss
- CMS EE: https://git.gentics.com/psc/cms
- Acta Nova Dialog Portal: https://git.gentics.com/psc/andp
 If the latest tagged version is incremented against the one currently stored in the CMP's `pom/xml`, 
 the component is a subject to a release.
1. Implement the change — see `rules/changelog.md` or `rules/helm-chart.md`.
2. Verify — see `rules/build.md` and `rules/testing.md`.
