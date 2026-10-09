---
paths:
  - "cmp-chart/**"
  - "ci/*.sh"
---

# CMP umbrella Helm chart

- `cmp-chart` is the umbrella chart (`Chart.yaml`, `values.yaml`, own templates for the bundled
  MariaDB, the shared license secret and `templates/validation.yaml`). The sub-charts `cms`,
  `gentics-mesh` (alias `mesh`), `gentics-portal-java` (alias `portal-java`) and
  `gentics-portal-php` (alias `portal-php`) live in their component repositories; change their
  templates there, not here.
- `cmp-chart/charts/gentics-common` is a library chart (shared named templates such as
  `gentics-common.image`, `gentics-common.imagePullSecretsList`), released separately with its own
  `version` in its `Chart.yaml`.
- Values that must agree with each other are checked in `templates/validation.yaml` (e.g.
  `global.mesh.enabled` vs. `mesh.enabled`); extend it when a new value depends on another.
- The dependency versions and repositories in `cmp-chart/Chart.yaml` are set by Jenkins from the
  root `pom.xml` (`ci/set-chart-dependency-versions.sh`) and committed with the release. Do not
  edit them by hand unless the task requires it.
- `cmp-chart/charts/*.tgz` and `cmp-chart/Chart.lock` are git-ignored; never commit them.

## Verification

Lint with the image CI uses (`ci/build-helm-chart.sh`, `alpine/helm:3.11.1`). It needs no
credentials; the warning about the missing `cms`, `gentics-mesh`, `gentics-portal-java`,
`gentics-portal-php` dependencies is expected without a `helm dependency update`:

```
docker run --rm -v $(pwd):/apps -w /apps alpine/helm:3.11.1 lint cmp-chart
```

Rendering with the sub-charts (`helm template`) first needs `ci/update-helm-dependencies.sh`, which
logs in to `repo.gentics.com` with `REPO_USERNAME` / `REPO_PASSWORD`. Ask the user to provide them
in the environment; never ask for them in the conversation and never write them into a file.
