# Licensing

Gentics CMP uses an open-core licensing model. This repository contains code under two licenses.

| Path | License | License text |
| --- | --- | --- |
| `ee/` | Business Source License 1.1 (BUSL-1.1) | [`ee/LICENSE`](ee/LICENSE), [`LICENSES/BUSL-1.1.txt`](LICENSES/BUSL-1.1.txt) |
| everything else | Apache License 2.0 | [`LICENSE`](LICENSE), [`LICENSES/Apache-2.0.txt`](LICENSES/Apache-2.0.txt) |

The `LICENSE` file in `ee/` overrides the `LICENSE` file in the repository root for everything below `ee/`.

## Core – Apache License 2.0

Everything outside the `ee/` directory is licensed under the Apache License 2.0, a permissive, OSI-approved open source license. The core is fully functional on its own. You can run it in production, modify it and redistribute it under the terms of Apache 2.0.

## Enterprise Modules – Business Source License 1.1

Code inside the `ee/` directory is licensed under the Business Source License 1.1. The source is public and you are free to read, build, modify and evaluate it. Use for development, testing, evaluation and demonstration is permitted without restriction. **Any production use requires a commercial license from Gentics** – contact sales@gentics.com.

Every BSL-licensed module automatically converts to the Apache License 2.0 on its Change Date, three years after its release date (see [`ee/LICENSE`](ee/LICENSE) for the exact date per module). BSL code is therefore not permanently proprietary; it is open source on a delay, guaranteed by the license itself.

The modules below `ee/` are:

* `ee/cmp-chart` – Umbrella Helm chart for Gentics CMP

The umbrella Helm chart in `ee/cmp-chart` deploys the complete platform including the Enterprise Modules of its components. The changelog and guides modules in this repository are Apache-2.0.

## Which license applies to a given file?

The license of a file is determined by its directory: `ee/` → BUSL-1.1, everything else → Apache-2.0.

## Contributions

See [`CONTRIBUTING.md`](CONTRIBUTING.md). Contributions outside `ee/` are accepted under the Apache License 2.0 with a Developer Certificate of Origin sign-off. Contributions to `ee/` require our Contributor License Agreement ([individual](CLA-individual.md), [corporate](CLA-corporate.md)), because Gentics must hold the rights needed to relicense the code on the Change Date.

## Trademarks

The licenses above cover the code, not the Gentics name and logos. See [`TRADEMARKS.md`](TRADEMARKS.md).

## Third-party software

See [`NOTICE`](NOTICE).

## Gentics CMP repositories

This file is the central licensing overview for Gentics CMP. The same open-core model applies to every repository; each one carries its own `LICENSE`, `ee/LICENSE`, `LICENSING.md`, `CONTRIBUTING.md`, `CLA-individual.md`, `CLA-corporate.md` and `TRADEMARKS.md`.

| Repository | Component | Apache-2.0 | BUSL-1.1 (`ee/`) |
| --- | --- | --- | --- |
| [cmp](https://github.com/gentics/cmp) | Umbrella: changelog, guides, Helm chart | changelog, guides | umbrella Helm chart |
| [cms-oss](https://github.com/gentics/cms-oss) | Gentics CMS | CMS core, REST API, UI, Workspace | content staging, forms, form generator, Keycloak integration, multichannelling, enterprise server distribution |
| [mesh](https://github.com/gentics/mesh) | Gentics Mesh | Mesh core, MCP server, content RAG | MS SQL, Oracle and PostgreSQL connectors, Keycloak, search and favorite plugins, enterprise Helm chart |
| [cmp-portals](https://github.com/gentics/cmp-portals) | Portals | Portal \| php, Portal \| php-laravel, Portal \| java | Helm charts of the portals |

All Enterprise Modules first released with Gentics CMP 9.0 have the release date 2027-01-01 and the Change Date 2030-01-01. Modules added later get their own dates in the `ee/LICENSE` of their repository.

Commercial licenses for production use of the Enterprise Modules: sales@gentics.com.
