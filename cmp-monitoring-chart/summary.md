# Session Summary – CMP Monitoring Stack Migration to OpenShift

## Goal
Migrate the Gentics CMP monitoring stack to an existing OpenShift namespace (`gtx-java-devtest`) using a custom parent Helm chart (`cmp-monitoring`) that manages all monitoring components as sub-charts.

## Final Chart Structure
```
cmp-monitoring/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── _helpers.tpl
│   ├── otelcol-configmap.yaml
│   └── prometheus-rbac.yaml
```

Install command:
```bash
helm dependency update cmp-monitoring/
helm upgrade --install cmp-monitoring ./cmp-monitoring \
  -n gtx-java-devtest \
  -f cmp-monitoring/values.yaml
```

## Components
| Component | Image | Helm Chart | Chart Version | Release Name (sub-chart) |
|---|---|---|---|---|
| Grafana | grafana/grafana:11.6.0 | grafana/grafana | 8.9.1 | cmp-monitoring-grafana |
| Prometheus | prom/prometheus:v3.10.0 | prometheus-community/prometheus | 27.5.0 | cmp-monitoring-prometheus |
| Loki | grafana/loki:3.7.0 | grafana/loki | 6.30.1 | cmp-monitoring-loki |
| Tempo | grafana/tempo:2.9.0 | grafana/tempo | 1.24.4 | cmp-monitoring-tempo |
| OTel Collector | otel/opentelemetry-collector-contrib:0.148.0 | open-telemetry/opentelemetry-collector | 0.119.0 | cmp-monitoring-opentelemetry-collector |
| Blackbox Exporter | quay.io/prometheus/blackbox-exporter:v0.28.0 | prometheus-community/prometheus-blackbox-exporter | 9.5.0 | cmp-monitoring-blackbox-exporter |

## Internal Service DNS Names
All components use the `cmp-monitoring-` prefix:
| Service | DNS name | Port |
|---|---|---|
| Prometheus | cmp-monitoring-prometheus-server | 9090 |
| Loki | cmp-monitoring-loki | 3100 |
| Tempo | cmp-monitoring-tempo | 3100 (Grafana datasource), 4317 (OTel gRPC) |
| Grafana | cmp-monitoring-grafana | 3000 |
| OTel Collector | cmp-monitoring-opentelemetry-collector | 8889 (metrics), 4317 (gRPC), 4318 (HTTP) |
| Blackbox Exporter | cmp-monitoring-blackbox-exporter | 9115 |

## OpenShift-Specific Issues Resolved

### SCC (Security Context Constraints)
- `runAsUser` must be in range `[1000970000, 1000979999]` — never hardcode
- `runAsGroup` and `fsGroup` must not be hardcoded
- `seccompProfile.type: RuntimeDefault` required
- `runAsNonRoot: true` required at pod level
- Setting `null` in values.yaml does NOT override chart defaults — use `~` (YAML null)
- Some charts (Prometheus) have TWO pod-level securityContext keys (`securityContext` and `podSecurityContext`) — both must be overridden

### RBAC
- User lacks cluster-level permissions — cannot create `ClusterRole` or `ClusterRoleBinding`
- **Prometheus**: `rbac.create: false` in chart values; namespace-scoped `Role` + `RoleBinding` created via `templates/prometheus-rbac.yaml` in the parent chart
- **Loki**: `rbac.namespaced: true` — chart handles it natively
- **Grafana**: `rbac.namespaced: true` — chart handles it natively

### Per-Chart Security Context Key Names
Each chart uses different key names — a hard-won lesson from this session:

| Component | Pod-level key(s) | Container-level key |
|---|---|---|
| Grafana | `securityContext` | `containerSecurityContext` |
| Prometheus | `server.securityContext` AND `server.podSecurityContext` (both required) | `server.containerSecurityContext` |
| Loki | `loki.podSecurityContext`, `singleBinary.podSecurityContext`, `rollout_operator.podSecurityContext` | n/a (cleared via pod-level) |
| Tempo | `securityContext` (top-level) | `tempo.securityContext` |
| OTel Collector | `podSecurityContext` | `securityContext` |
| Blackbox Exporter | `podSecurityContext` | `securityContext` |

### Other Issues Resolved
- **Grafana `initChownData`**: Disabled (`initChownData.enabled: false`) — renders broken `chown -R :` command when `fsGroup` is null
- **Loki `bucketNames`**: Must be set even for filesystem storage — chart template fails with nil pointer otherwise
- **Loki memcached**: Disabled (`chunksCache.enabled: false`, `resultsCache.enabled: false`) — not needed for devtest, avoids CPU request/limit conflicts
- **OTel Collector config merging**: Chart merges `config:` values rather than replacing — the deprecated `service.telemetry.metrics.address` field from chart defaults could not be removed via merge. Workaround: `configMap.create: false` + custom ConfigMap in `templates/otelcol-configmap.yaml`
- **OTel Collector `batch` processor**: Chart default `processors` block (containing only `memory_limiter`) overwrites custom processors. Resolved by moving full config to the custom ConfigMap
- **Duplicate YAML keys**: Several values files had duplicate top-level keys (e.g. two `server:` blocks, two `loki:` blocks) — YAML silently takes the last one, causing earlier keys to be lost

## Health Check Issues Resolved

### Tempo — Wrong image version
- The Tempo Helm chart (version 1.23.2) hardcodes the image tag — the `tempo.image.tag` value is silently ignored
- Chart version 1.24.4 ships with appVersion 2.9.0, which is acceptable for devtest
- **Fix**: Upgrade chart dependency to `grafana/tempo` version `1.24.4`

### Grafana — Multiple issues
- **OOM kill**: Default memory limit of 100Mi is too low for Grafana 11+
  - **Fix**: Set `resources.limits.memory: 256Mi`, `resources.requests.memory: 128Mi`
- **Read-only filesystem**: `readOnlyRootFilesystem: true` prevented Grafana from writing to `/tmp` (needed for plugin installation) and other runtime paths
  - **Fix**: Set `containerSecurityContext.readOnlyRootFilesystem: false`
- **Liveness probe killing container during startup**: Grafana's DB migrations and startup take longer than the default liveness probe timeout on a resource-constrained cluster
  - **Fix**: Set `livenessProbe.initialDelaySeconds: 180`
- **Grafana 12 incompatibility with restricted OpenShift**: Grafana 12 includes a `grafana-apiserver` module that attempts to register itself as a Kubernetes API extension, requiring cluster-level API access not available in a restricted namespace. This causes the HTTP server to accept TCP connections but immediately reset them, making health checks permanently fail. Confirmed by reproducing the reset even from loopback (`curl http://[::1]:3000/api/health`) inside the pod itself.
  - **Fix**: Downgrade to Grafana 11.6.0 (image `grafana/grafana:11.6.0`). Grafana 11 does not include the `grafana-apiserver` module and starts cleanly in restricted environments. Delete the existing PVC before upgrading to avoid database schema conflicts: `oc delete pvc cmp-monitoring-grafana -n gtx-java-devtest`
- **Bundled plugin auto-installation**: Grafana 12 attempts to download and install bundled plugins (`grafana-lokiexplore-app`, `grafana-pyroscope-app`, etc.) on every startup, consuming CPU/memory and slowing startup. The `disable_plugins` ini key suppresses this. Not needed after downgrade to 11.6.0 but documented for reference.

### General health check debugging approach
- `oc describe pod` events distinguish between `connection refused` (process not listening), `connection reset by peer` (process accepting but immediately closing), and `EOF` (process closing mid-response)
- `connection reset by peer` from the kubelet does NOT necessarily mean a network issue — it can be an application-level reset, verifiable by running `curl` from inside the pod itself
- Use `oc logs --previous` to get logs from the last terminated container instance
- Use `netstat -tlnp` inside the pod to verify what address/port the process is actually listening on
- To distinguish node-level from application-level issues, deploy a known-working HTTP server (e.g. `httpbin`) on the same node and verify its health probes pass

## Current Status
| Component | Status |
|---|---|
| Grafana | ✅ Running and healthy (11.6.0) |
| Prometheus | ❌ Health checks failing — next to investigate |
| Loki | ❓ Unknown |
| Tempo | ❓ Unknown |
| OTel Collector | ❌ Health checks failing — next to investigate |
| Blackbox Exporter | ❌ Health checks failing — next to investigate |

## Health Check Endpoints
| Component | Health endpoint |
|---|---|
| Prometheus | `/-/healthy` on port 9090 |
| Grafana | `/api/health` on port 3000 |
| Loki | `/ready` on port 3100 |
| Tempo | `/ready` on port 3200 |
| OTel Collector | `/` on port 13133 (health_check extension) |
| Blackbox Exporter | `/-/healthy` on port 9115 |