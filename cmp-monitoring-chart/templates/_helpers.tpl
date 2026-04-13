{{/*
Shared pod-level securityContext for all components.
Clears hardcoded UIDs/GIDs so OpenShift SCC assigns them from its allowed range.
*/}}
{{- define "cmp-monitoring.podSecurityContext" -}}
runAsNonRoot: true
runAsUser: null
runAsGroup: null
fsGroup: null
seccompProfile:
  type: RuntimeDefault
{{- end }}

{{/*
Shared container-level securityContext for all components.
*/}}
{{- define "cmp-monitoring.containerSecurityContext" -}}
allowPrivilegeEscalation: false
runAsNonRoot: true
runAsUser: null
runAsGroup: null
capabilities:
  drop: ["ALL"]
seccompProfile:
  type: RuntimeDefault
{{- end }}

{{/*
Container-level securityContext for components that need filesystem write access
(e.g. blackbox exporter).
*/}}
{{- define "cmp-monitoring.containerSecurityContextNoReadOnly" -}}
allowPrivilegeEscalation: false
runAsNonRoot: false
runAsUser: null
runAsGroup: null
readOnlyRootFilesystem: false
seccompProfile:
  type: RuntimeDefault
{{- end }}

{{/*
Fully qualified service name helpers — used in config cross-references.
All names follow the pattern: <release>-<alias>-<suffix>
*/}}
{{- define "cmp-monitoring.prometheusServerHost" -}}
{{ .Release.Name }}-prometheus-server
{{- end }}

{{- define "cmp-monitoring.lokiHost" -}}
{{ .Release.Name }}-loki
{{- end }}

{{- define "cmp-monitoring.tempoHost" -}}
{{ .Release.Name }}-tempo
{{- end }}

{{- define "cmp-monitoring.grafanaHost" -}}
{{ .Release.Name }}-grafana
{{- end }}

{{- define "cmp-monitoring.otelCollectorHost" -}}
{{ .Release.Name }}-opentelemetry-collector
{{- end }}

{{- define "cmp-monitoring.blackboxHost" -}}
{{ .Release.Name }}-blackbox-exporter
{{- end }}

{{- define "cmp-monitoring.otelConfigMapName" -}}
{{ .Release.Name }}-otelcol-config
{{- end }}
