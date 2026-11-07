<h1 align="center">Gentics CMP</h1>
<h3 align="center">The Content Management Platform – one platform, four repositories</h3>

<p align="center">
  <a href="LICENSING.md"><img src="https://img.shields.io/badge/core-Apache--2.0-brightgreen.svg" alt="Core: Apache-2.0" /></a>
  <a href="LICENSING.md"><img src="https://img.shields.io/badge/ee-BUSL--1.1-blue.svg" alt="Enterprise Modules: BUSL-1.1" /></a>
  <a href="CONTRIBUTING.md"><img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg" alt="PRs welcome" /></a>
</p>

This is the umbrella repository of **Gentics CMP**. It does not contain the platform's code; it contains the
things that only make sense for the platform as a whole: the overall changelog, the guides, the umbrella Helm
chart and the central [licensing overview](LICENSING.md). If you are new, start here: this README explains
how the repositories fit together and where to go for what.

## The platform in one picture

```
            ┌───────────────────────── editors, admins, AI agents ─────────────────────────┐
            │                                                                              │
            ▼                                                                              ▼
┌──────────────────────────┐   publishes content   ┌──────────────────────────┐   content API (REST/GraphQL)
│  Gentics CMS             │ ─────────────────────▶│  Gentics Mesh            │ ◀────────────────────────────┐
│  github.com/gentics/     │                       │  github.com/gentics/mesh │                              │
│  cms-oss                 │                       │                          │                              │
│                          │                       │  headless content        │   ┌──────────────────────┐   │
│  editing, workflows,     │                       │  repository, permissions,│   │  Portals             │   │
│  WYSIWYG (Aloha),        │                       │  search (Elasticsearch), │   │  github.com/gentics/ │   │
│  Workspace (AI co-pilot),│                       │  Content RAG,            │   │  cmp-portals         │   │
│  MCP tools               │                       │  MCP server              │   │  Portal | php        │   │
└──────────────────────────┘                       └──────────────────────────┘   │  Portal | java       │   │
            │                                                   │                 └──────────────────────┘   │
            │  AI features via GenAIx (Gentics-hosted service)  │                            │ renders         │
            ▼                                                   ▼                            ▼               │
      ┌───────────┐                                   ┌──────────────────┐            website visitors ──────┘
      │  GenAIx   │                                   │  Elasticsearch   │
      └───────────┘                                   └──────────────────┘

                       ┌─────────────────────────────────────────────────────┐
                       │  cmp (this repo): changelog · guides · Helm umbrella │
                       │  chart (ee/cmp-chart) · licensing overview           │
                       └─────────────────────────────────────────────────────┘
```

**The flow:** editors work in **Gentics CMS**. The CMS publishes content into **Gentics Mesh**, the headless
content repository. **Portals** (or any application of yours) read the content from Mesh through its REST and
GraphQL APIs and render it. AI agents reach both systems through **MCP servers**, and the CMS Workspace
talks to **GenAIx**, the Gentics-hosted AI service. **This repository** ties the components together into
releasable platform versions.

## The repositories

| Repository | What it is | Tech | Enterprise Modules (`ee/`) |
| --- | --- | --- | --- |
| [gentics/cms-oss](https://github.com/gentics/cms-oss) | Gentics CMS: editing, publishing, user management, REST API, editor UI, Workspace UI, MCP tools | Java 17, Maven, TypeScript/Vite | content staging, forms, form generator, Keycloak, multichannelling, enterprise server distribution |
| [gentics/mesh](https://github.com/gentics/mesh) | Gentics Mesh: headless content repository with REST/GraphQL, permissions, Elasticsearch search, Content RAG, MCP server | Java 17, Maven, Vert.x | MS SQL, Oracle and PostgreSQL connectors; Keycloak, search and favorite plugins; enterprise Helm chart |
| [gentics/cmp-portals](https://github.com/gentics/cmp-portals) | The portal frameworks that render Mesh content: Portal \| php (Laravel) and Portal \| java (Vert.x) | PHP 8.3/Composer, Java 17/Maven | Helm charts of the portals |
| [gentics/cmp](https://github.com/gentics/cmp) | **This repo.** Platform changelog, guides, umbrella Helm chart, licensing overview | Maven, Helm | umbrella Helm chart |

Every repository has the same shape: open-source core under Apache 2.0, Enterprise Modules in an `ee/`
directory under the Business Source License 1.1, and the same set of licensing files
(`LICENSE`, `ee/LICENSE`, `LICENSING.md`, `CONTRIBUTING.md`, `CLA-*.md`, `TRADEMARKS.md`).
The core of every component runs without `ee/`.

## Getting started as a developer

### 1. Clone what you need

Most work happens in one component. Clone that repository and read its README; it has the build and test
instructions. You only need the other repositories when you work across the boundary, e.g. on CMS → Mesh
publishing or on a portal feature that needs a Mesh change.

```bash
git clone https://github.com/gentics/cms-oss.git
git clone https://github.com/gentics/mesh.git
git clone https://github.com/gentics/cmp-portals.git
git clone https://github.com/gentics/cmp.git
```

### 2. Build

| Component | Requirements | Build |
| --- | --- | --- |
| Gentics CMS | Java 17, Maven 3.9+, Node.js (UIs), Docker (tests) | `cd cms-oss && mvn clean install` |
| Gentics Mesh | Java 17, Maven 3.9+, Docker (tests) | `cd mesh && mvn clean install` |
| Portal \| php | PHP 8.3 (`intl`, `json`), Composer | `cd cmp-portals/portal-php && composer install && composer test` |
| Portal \| java | Java 17, Maven, Docker (tests) | `cd cmp-portals/portal-java && mvn clean install` |
| cmp (changelog, guides) | Java 17, Maven | `cd cmp && mvn clean install` |

The Maven reactors of CMS and Mesh include their `ee/` modules, so a full build produces both the community
artifacts (Apache 2.0) and the enterprise artifacts (BUSL-1.1). The dependency rule is strict and
one-way: `ee/` may depend on the core, the core never depends on `ee/`.

### 3. Run the platform

The fastest way to a complete platform is the umbrella Helm chart in [`ee/cmp-chart`](ee/cmp-chart). It
installs CMS, Mesh and the portals from the Gentics Helm repository and lets you switch components on and off:

```bash
helm dependency update ee/cmp-chart
helm install cmp ee/cmp-chart \
  --set cms.enabled=true \
  --set mesh.enabled=true \
  --set portal-java.enabled=true \
  --set portal-php.enabled=false
```

See [`ee/cmp-chart/values.yaml`](ee/cmp-chart/values.yaml) for the configuration of the bundled MariaDB,
Elasticsearch and the individual components. The chart is an Enterprise Module: free to use for
development, testing and evaluation; production use needs a commercial license (see
[Licensing](#licensing)).

For a single component, use its Docker image: [gentics/cms-oss](https://hub.docker.com/r/gentics/cms-oss)
and [gentics/mesh](https://hub.docker.com/r/gentics/mesh) on Docker Hub, or the Helm charts in the
components' `ee/` directories.

## Versions and releases

* Each component has its own version number and changelog. This repository pins the component versions of a
  platform release in [`pom.xml`](pom.xml) and in the umbrella chart's [`Chart.yaml`](ee/cmp-chart/Chart.yaml),
  and generates the combined [Gentics CMP changelog](https://www.gentics.com/cmp/changelog/) from them.
* **Gentics CMP 9** is the first release of the open-core platform. The 9.0 work happens on the
  `f-gpu-2756` branches of `cms-oss` and `mesh` and on `dev` of `cmp-portals`.
* Branches follow the same convention everywhere: `dev` for the next release, `hotfix-<version>` for
  maintenance of released versions, `f-<ticket>` for feature branches.

## What lives in this repository

```
cmp/
├── changelog/      Maven module that assembles the platform changelog from the component changelogs
├── guides/         Maven module that builds the platform guides (https://www.gentics.com/guides/)
├── ee/cmp-chart/   Umbrella Helm chart for the whole platform (BUSL-1.1)
├── ci/             Jenkins pipeline and Helm build helpers
├── LICENSING.md    Central licensing overview for all repositories
├── CONTRIBUTING.md DCO for the core, CLA for ee/
├── CLA-*.md        Contributor License Agreements (individual, corporate)
└── TRADEMARKS.md   How the Gentics name and logos may be used
```

## Documentation

* [Gentics CMP guides](https://www.gentics.com/guides/) – installation, configuration and development guides for all components
* [Gentics CMP changelog](https://www.gentics.com/cmp/changelog/)
* [Gentics Infoportal](https://www.gentics.com/infoportal/) – product documentation
* Component READMEs: [cms-oss](https://github.com/gentics/cms-oss#readme), [mesh](https://github.com/gentics/mesh#readme), [cmp-portals](https://github.com/gentics/cmp-portals#readme)

## External dependencies (versions in the changelog)

Information about latest versions of external dependencies were retrieved via the following links:
* MariaDB: https://mariadb.org/mariadb/all-releases/
* Oracle Database: https://docs.oracle.com/en/database/oracle/oracle-database/index.html
* Elasticsearch: https://www.elastic.co/guide/en/elasticsearch/reference/current/es-release-notes.html
* MS SQL Server: https://learn.microsoft.com/de-de/troubleshoot/sql/releases/download-and-install-latest-updates
* PostgreSQL: https://www.postgresql.org/docs/release/
* Keycloak: https://www.keycloak.org/docs/latest/release_notes/index.html

The versions need to be updated regularly in the file: `static_dependencies.json` in the components repositories.

## Licensing

Gentics CMP is **open core**:

* **Core – Apache License 2.0.** Everything outside the `ee/` directories. OSI-approved open source; use it in
  production, modify it, redistribute it.
* **Enterprise Modules – Business Source License 1.1.** Everything inside `ee/`. The source is public; use for
  development, testing, evaluation and demonstration is free. Production use requires a commercial license
  from Gentics – contact [sales@gentics.com](mailto:sales@gentics.com). Every module converts to Apache 2.0
  three years after its release (Change Date), guaranteed by the license.

[`LICENSING.md`](LICENSING.md) has the overview across all repositories and the exact Change Date per module.

## Contributing

Pull requests are welcome in every repository; open them where the code lives.

* Contributions to the core are accepted under Apache 2.0 with a DCO sign-off (`git commit -s`).
* Contributions to `ee/` need our [Contributor License Agreement](CLA-individual.md) (there is a
  [corporate version](CLA-corporate.md) too); the CLA bot asks on your first `ee/` pull request.

See [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Getting help

* Issues: in the repository of the affected component
* Commercial support, licenses and professional services: [sales@gentics.com](mailto:sales@gentics.com)

---

Copyright (c) 2026 Gentics Software GmbH. Gentics is a registered trademark of Gentics Software GmbH, see
[`TRADEMARKS.md`](TRADEMARKS.md).
