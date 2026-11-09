# CMP Monitoring Chart

Installs the monitoring stack for Gentics CMP: an OpenTelemetry Collector that receives
OTLP, with Tempo (traces), Loki (logs), Prometheus (metrics), Grafana and a Blackbox exporter.

## Install

Plain Kubernetes:

```bash
helm upgrade --install cmp-monitoring . -n <namespace> --create-namespace
```

OpenShift (requires Helm 3.17 or newer):

```bash
helm upgrade --install cmp-monitoring . -n <namespace> -f values-openshift.yaml
```

The overlay removes the fixed UIDs so the SCC can assign its own. Older Helm versions ignore
it, so the chart stops with an error when it detects OpenShift and the UIDs are still set.

## Endpoints

Service names are fixed and do not depend on the release name, so install only one release
per namespace.

| Component | Service | Port |
|---|---|---|
| OTLP input | `cmp-monitoring-opentelemetry-collector` | 4317 (gRPC), 4318 (HTTP) |
| Grafana | `cmp-monitoring-grafana` | 80 |
| Prometheus | `cmp-monitoring-prometheus-server` | 80 |
| Loki | `cmp-monitoring-loki` | 3100 |
| Tempo | `cmp-monitoring-tempo` | 3200 (query), 4317 / 4318 (OTLP) |
| Blackbox | `cmp-monitoring-blackbox-exporter` | 9115 |

## Grafana access

Grafana is not exposed by default:

```bash
kubectl -n <namespace> port-forward svc/cmp-monitoring-grafana 3000:80
kubectl -n <namespace> get secret cmp-monitoring-grafana -o jsonpath='{.data.admin-password}' | base64 -d
```

To expose it, set `grafana.ingress.*`. OpenShift creates a Route from the Ingress automatically.

## Configuration to check

- **Availability probes:** `prometheus.serverFiles.prometheus.yml` (job `blackbox`) assumes CMP
  runs as release `cmp` in the same namespace.
- **Resources:** all components set explicit requests and limits, because a namespace
  LimitRange may otherwise apply very low defaults.
- **Retention:** Loki 7 days, Tempo 48 hours, Prometheus 15 days. Each has a 10Gi volume.
