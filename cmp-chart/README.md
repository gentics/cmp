# Gentics CMP — Umbrella Helm Chart

Deploys the Gentics Content Management Platform: **CMS**, **Mesh**, **Portal | Java**,
**Portal | PHP** and an optional bundled **MariaDB**, wired together automatically.

Each sub-chart also works standalone; the umbrella adds cross-component wiring:

| Wiring | Mechanism |
|---|---|
| Database host/credentials for CMS & Mesh | `global.mariadb.enabled` + generated `<release>-cms-db` / `<release>-mesh-db` secrets + db-init job |
| License key for all components | `global.license.key` → shared `<release>-license` secret |
| Portal Java → Mesh connection | `global.mesh.enabled` → `<release>-mesh:80` (override via `portal-java.mesh.host`/`port`) |
| Portal PHP → Mesh connection | `global.mesh.enabled` → `http://<release>-mesh:80` (override via `portal-php.mesh.url`) |
| Mesh API key for the portals | the mesh chart always renders the (empty) secret `<release>-mesh-secret` (key `apikey`); enable `mesh.generateApiKey=true` (e.g. `--set` on first install) to have a Job generate the key and patch it in. Create-once — an existing key is never regenerated. Bring your own via `portal-java.mesh.secretName` / `portal-php.mesh.secretName` |
| Image pull secrets | `global.imagePullSecrets` (overridable per chart) |
| Registry mirror | `global.imageRegistry` rewrites the registry of **all** images |
| Telemetry (OpenTelemetry) and monitoring | `global.otel.enabled` → OTel Java agent in CMS, Mesh, Portal Java + optional bundled monitoring stack, see [Telemetry and monitoring](#telemetry-and-monitoring) |

## Quick start

```bash
helm install cmp . \
  --set global.license.key="<YOUR_LICENSE_KEY>"
```

Portal | Java has no pre-built image — build your portal project image and set
`portal-java.image.repository`/`tag` before enabling `portal-java.enabled`.

## Telemetry and monitoring

The Java components (CMS, Mesh, Portal | Java) can send traces, metrics and logs via
OpenTelemetry. The OpenTelemetry Java agent is part of the CMS and Mesh images; the chart
only switches it on. Portal | PHP sends no telemetry.

### Modes

| Mode | Values | Result |
|---|---|---|
| Off (default) | — | No telemetry, no monitoring stack. Rendered output is unchanged. |
| Bundled | `global.otel.enabled=true` | Telemetry goes to a monitoring stack installed with this release: OpenTelemetry Collector, Prometheus, Loki, Tempo, Grafana (with the CMP dashboards) and a Blackbox exporter for availability probes. |
| External | `global.otel.enabled=true`<br>`monitoring.enabled=false`<br>`global.otel.endpoint=http://<collector>:4318` | Telemetry goes to an existing OTLP endpoint; no stack is installed. |
| One component | e.g. `mesh.otel.enabled=true`<br>`mesh.otel.endpoint=http://<collector>:4318` | Only that component sends telemetry. |

```bash
# Bundled
helm upgrade --install cmp . --set global.otel.enabled=true

# Bundled on OpenShift (Helm 3.17 or newer): my-openshift-values.yaml holds the
# commented "OpenShift" securityContext lines from values.yaml, set to ~
helm upgrade --install cmp . --set global.otel.enabled=true -f my-openshift-values.yaml

# External: send to the bundled stack of another CMP release, e.g. "cmp" in namespace "cmp-prod"
helm upgrade --install cmp-test . --set global.otel.enabled=true --set monitoring.enabled=false \
  --set global.otel.endpoint=http://cmp-opentelemetry-collector.cmp-prod.svc:4318
```

The resource attribute `service.namespace` (default `<namespace>-<release>`, override with
`global.otel.serviceNamespace`) keeps several CMP installations apart in one stack.

### What a component gets

With telemetry on, a component's pod gets these environment variables:

| Variable | Value |
|---|---|
| `JDK_JAVA_OPTIONS` | `-javaagent:<agentPath>`. `JAVA_TOOL_OPTIONS` (heap settings) is not touched. |
| `OTEL_SERVICE_NAME` | `Gentics CMS`, `Gentics Mesh`, `Gentics Portal Java` |
| `OTEL_EXPORTER_OTLP_ENDPOINT` / `_PROTOCOL` | component → global → bundled Collector `http://<release>-opentelemetry-collector:4318`; protocol default `http/protobuf` |
| `OTEL_RESOURCE_ATTRIBUTES` | `service.namespace`, `k8s.namespace.name`, `k8s.pod.name` |
| `OTEL_EXPORTER_OTLP_HEADERS` | only with `headersSecret` (see below) |

Every setting under `global.otel` can be overridden per component under `cms.otel`,
`mesh.otel` and `portal-java.otel` (`enabled`, `endpoint`, `protocol`, `headersSecret`,
`serviceName`, `agentPath`). A variable that you set yourself in the component's
`extraEnv` (`cms.cms.extraEnv` for the CMS) always wins.

- **Portal | Java:** portal images are project-specific, so `portal-java.otel.agentPath`
  must point at the agent jar in your image. The JVM does not start if the file is missing.
- **Don't load the agent twice:** remove any `-javaagent` you added to `JAVA_TOOL_OPTIONS`
  yourself before switching telemetry on.
- **Authenticated endpoints:** `global.otel.headersSecret` (or `<component>.otel.headersSecret`)
  names a Secret whose key `headers` holds the OTLP headers, e.g.
  `kubectl create secret generic otel-auth --from-literal=headers='Authorization=Bearer <token>'`.
  Not needed for the bundled stack.

### The bundled monitoring stack

| Component | Service | Port |
|---|---|---|
| OTLP input (Collector) | `<release>-opentelemetry-collector` | 4317 (gRPC), 4318 (HTTP) |
| Grafana | `<release>-grafana` | 80 |
| Prometheus | `<release>-prometheus-server` | 80 |
| Loki | `<release>-loki` | 3100 |
| Tempo | `<release>-tempo` | 3200 (query), 4317 / 4318 (OTLP) |
| Blackbox exporter | `<release>-blackbox-exporter` | 9115 |

- **One stack per namespace:** the ConfigMaps `loki` and `tempo` (named by the Loki and
  Tempo charts) and the probe-target ConfigMap `cmp-blackbox-targets` have fixed names.
- **Grafana access:** not exposed by default (set `grafana.ingress.*`; OpenShift creates
  a Route from the Ingress):
  ```bash
  kubectl port-forward svc/<release>-grafana 3000:80
  kubectl get secret <release>-grafana -o jsonpath='{.data.admin-password}' | base64 -d
  ```
- **Dashboards:** "CMP" and "CMP Service Overview" (`dashboards/` in this chart) are
  provisioned into the Grafana folder "CMP". They are read-only and updated with every
  chart version. To customise one, use "Save as": the copy is stored in Grafana's database
  (on its volume) and kept across upgrades.
- **Availability probes:** the Blackbox exporter probes the enabled components on their
  configured Service ports.
- **Retention and storage:** Loki 7 days, Tempo 48 hours, Prometheus 15 days, each on a
  10Gi volume; Grafana 2Gi. All components set explicit resource requests and limits,
  because a namespace LimitRange may otherwise apply very low defaults.
- **OpenShift:** `values.yaml` contains commented "OpenShift" lines (`runAsUser`,
  `runAsGroup`, `fsGroup: ~`) in the security settings of Grafana, Prometheus, Loki, Tempo
  and the Blackbox exporter. Copy them into your own values file, so the SCC can assign
  its own IDs; this requires Helm 3.17 or newer. Older Helm versions ignore the nulls, so
  the chart stops with an error when it detects OpenShift and the UIDs are still set.

## Generated credentials

On plain `helm install`, these secrets are generated once (random) and reused on upgrades:

| Secret | Key | Bring-your-own value |
|---|---|---|
| `<release>-mariadb` (root password) | `root-password` | `mariadb.auth.existingSecret` |
| `<release>-cms-db` (CMS DB user) | `password` | `cms.database.passwordSecret` |
| `<release>-mesh-db` (Mesh DB user) | `password` | `mesh.database.passwordSecret` |
| `<release>-cms` (CMS node user) | `node-user-password` | `cms.cms.nodeUserPasswordSecret` |
| `<release>-mesh-admin` (Mesh admin) | `password` | `mesh.initialAdminPassword.existingSecret` |
| `<release>-mesh-mcp-server-auth` (MCP bearer token, only when `mesh.mcpServer.enabled` with http transport) | `MCP_AUTH_TOKEN` | `mesh.mcpServer.transport.auth.existingSecret` |
| `<release>-mesh-secret` (Mesh API key for the portals — secret rendered empty by Helm, key patched in by the apikey Job when `mesh.generateApiKey=true`) | `apikey` | `portal-java.mesh.secretName` / `portal-php.mesh.secretName` |

When a bring-your-own value is set, the chart does **not** create that secret; your secret
must exist in the release namespace with the key listed above.

## Deploying with Argo CD

The generated credentials above use Helm's `lookup` function, which returns nothing when
Argo CD renders the chart (it uses `helm template` without cluster access). Without
countermeasures every sync would regenerate the random passwords: the app stays
permanently OutOfSync and credentials rotate under the running pods.

### Recommended: bring your own secrets

Set **all five** bring-your-own values from the table above (e.g. backed by
External Secrets Operator, Sealed Secrets, or SOPS). The rendered manifests are then fully
deterministic — verify with two identical `helm template` runs.

```yaml
# Application values example
mariadb:
  auth:
    existingSecret: cmp-mariadb-root
cms:
  database:
    passwordSecret: cmp-cms-db
  cms:
    nodeUserPasswordSecret: cmp-cms-node
mesh:
  database:
    passwordSecret: cmp-mesh-db
  initialAdminPassword:
    existingSecret: cmp-mesh-admin
```

### Fallback: keep chart-generated passwords

If you accept chart-generated passwords, tell Argo CD to ignore (and not overwrite)
Secret data:

```yaml
# Application spec
syncPolicy:
  syncOptions:
    - RespectIgnoreDifferences=true
ignoreDifferences:
  - kind: Secret
    jsonPointers:
      - /data
```

With `RespectIgnoreDifferences=true` the first sync creates the random passwords and later
syncs never overwrite them. Note this ignores data diffs on **all** Secrets of the app.

### Helm hooks under Argo CD

The db-init job (Helm `post-install` hook) runs as an Argo CD **PostSync** hook on
*every* sync. It is idempotent (`CREATE ... IF NOT EXISTS`) — do not remove those guards.

### The Mesh API-key job under Argo CD

The apikey job (`mesh.generateApiKey=true`) is deliberately a **plain Job**, not a Helm
hook — a PostSync hook would deadlock (Argo waits for the portals to be healthy before
PostSync, while the portals wait for the job's key). The job is deterministic and
idempotent: it exits immediately when the key is already present. After the
`ttlSecondsAfterFinished` cleanup Argo re-creates it on the next sync, where it no-ops.

⚠️ The `<release>-mesh-secret` secret is rendered **empty** by the chart while the live
object carries the patched-in key — with auto-sync + `selfHeal` Argo would revert (wipe)
it. Use the Secret `ignoreDifferences` recipe above, or bring your own secret via
`portal-*.mesh.secretName` and leave `mesh.generateApiKey` off.

## Uninstall & data retention

All PersistentVolumeClaims (MariaDB data, CMS data/cache/backup, Mesh shared/snapshots,
Portal shared) are annotated with `helm.sh/resource-policy: keep` and
`argocd.argoproj.io/sync-options: Delete=false` by default. **`helm uninstall` (or
deleting the Argo CD Application) keeps all data volumes** — an accidental uninstall is
not a data-loss event.

```bash
helm uninstall <release>              # workloads gone, volumes kept
```

For throwaway/test installs where uninstall should delete the volumes too:

```bash
helm install t . --set global.persistence.keepOnUninstall=false ...
helm uninstall t                      # everything gone, including PVCs
```

Per-component override (wins over the global switch): set `keepOnUninstall` in the
component's persistence section — `mariadb.persistence.keepOnUninstall`,
`cms.cms.persistence.keepOnUninstall` (governs all CMS volumes),
`mesh.persistence.keepOnUninstall`, `portal-java.persistence.keepOnUninstall`.
Note the flag is baked into the applied manifests: to change it on a running release,
`helm upgrade` with the new value first, then uninstall.

Reinstalling under the same release name re-uses the kept volumes (PVC names are
release-derived; if Helm refuses to adopt an existing PVC, reference it explicitly via
the corresponding `persistence.*.existingClaim` value).

To **permanently delete all CMP data** after uninstalling:

```bash
kubectl delete pvc -l app.kubernetes.io/instance=<release>
```
