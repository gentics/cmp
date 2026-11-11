{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "cmp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "cmp.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "cmp.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ include "cmp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Name of the shared license secret created by the umbrella chart.
All sub-charts that support license.secret reference this name.
*/}}
{{- define "cmp.licenseSecretName" -}}
{{- .Release.Name }}-license
{{- end -}}

{{/*
Name of the secret holding the MariaDB root password.
Uses mariadb.auth.existingSecret when set (key "root-password" expected),
otherwise the chart-managed "<release>-mariadb" secret.
*/}}
{{- define "cmp.mariadbRootSecretName" -}}
{{- ((.Values.mariadb.auth).existingSecret) | default (printf "%s-mariadb" .Release.Name) -}}
{{- end -}}

{{/*
Name of the secret holding the CMS database password (key "password").
Uses cms.database.passwordSecret when set, otherwise the chart-managed secret.
*/}}
{{- define "cmp.cmsDbSecretName" -}}
{{- (((.Values.cms).database).passwordSecret) | default (printf "%s-cms-db" .Release.Name) -}}
{{- end -}}

{{/*
Name of the secret holding the Mesh database password (key "password").
Uses mesh.database.passwordSecret when set, otherwise the chart-managed secret.
*/}}
{{- define "cmp.meshDbSecretName" -}}
{{- (((.Values.mesh).database).passwordSecret) | default (printf "%s-mesh-db" .Release.Name) -}}
{{- end -}}

{{/*
"true" when the bundled monitoring stack is installed, "" otherwise.
Mirrors the dependency condition "monitoring.enabled,global.otel.enabled" in
Chart.yaml: Helm uses the first of these paths that holds a boolean.
*/}}
{{- define "cmp.monitoringEnabled" -}}
{{- $monitoring := (.Values.monitoring | default dict).enabled -}}
{{- if kindIs "bool" $monitoring -}}
{{- if $monitoring -}}true{{- end -}}
{{- else if ((.Values.global).otel).enabled -}}
true
{{- end -}}
{{- end -}}

{{/*
"true" when a Java component is installed and its telemetry is on, "" otherwise.
Same rule as gentics-common.otelEnv: <component>.otel.enabled true/false wins,
an absent or null value follows global.otel.enabled.
Args: (dict "root" $ "component" "cms"|"mesh"|"portal-java")
*/}}
{{- define "cmp.componentOtelEnabled" -}}
{{- $values := index .root.Values .component | default dict -}}
{{- $local := dig "otel" "enabled" nil $values -}}
{{- $enabled := ((.root.Values.global).otel).enabled -}}
{{- if kindIs "bool" $local -}}
{{- $enabled = $local -}}
{{- end -}}
{{- if and $values.enabled $enabled -}}
true
{{- end -}}
{{- end -}}
