{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "cms.name" -}}
{{- default .Chart.Name .Values.global.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cms.fullname" -}}
{{- if .Values.global.fullnameOverride -}}
{{- .Values.global.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.global.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "cms.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "cms.labels" -}}
helm.sh/chart: {{ include "cms.chart" . }}
{{ include "cms.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "cms.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cms.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "cms.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "cms.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Database host for CMS.
Uses explicit database.host if set; falls back to the bundled MariaDB service name
when global.mariadb.enabled is true; otherwise raises an error.
*/}}
{{- define "cms.databaseHost" -}}
{{- if .Values.database.host -}}
{{ .Values.database.host }}
{{- else if .Values.global.mariadb.enabled -}}
{{ .Release.Name }}-mariadb
{{- else -}}
{{ required "database.host is required when global.mariadb.enabled is false" "" }}
{{- end -}}
{{- end -}}

{{/*
Secret name and key for the CMS database password.
Priority: explicit database.passwordSecret → umbrella MariaDB secret → sub-chart local secret.
Returns a full secretKeyRef block.
*/}}
{{- define "cms.databasePasswordRef" -}}
{{- if .Values.database.passwordSecret -}}
secretKeyRef:
  name: {{ .Values.database.passwordSecret }}
  key: password
{{- else if .Values.global.mariadb.enabled -}}
secretKeyRef:
  name: {{ .Release.Name }}-cms-db
  key: password
{{- else if .Values.database.password -}}
secretKeyRef:
  name: {{ include "cms.fullname" . }}
  key: database-password
{{- else -}}
{{ required "Either database.password, database.passwordSecret, or global.mariadb.enabled are required" "" }}
{{- end -}}
{{- end -}}

{{/*
Name of the secret containing the CMS license key.
Priority: local cms.license.secret (explicit override) → global license secret (umbrella chart)
         → cms.fullname (sub-chart's own secret, when license.key is set locally).
*/}}
{{- define "cms.licenseSecretName" -}}
{{- if .Values.cms.license.secret -}}
{{ .Values.cms.license.secret }}
{{- else if .Values.global.license.key -}}
{{ .Release.Name }}-license
{{- else -}}
{{ include "cms.fullname" . }}
{{- end -}}
{{- end -}}

{{/*
Image pull secrets — local image.pullSecret overrides global; global is the default.
Local accepts a plain secret name string; global uses the Kubernetes-native array format.
*/}}
{{- define "cms.imagePullSecrets" -}}
{{- if .Values.image.pullSecret }}
imagePullSecrets:
  - name: {{ .Values.image.pullSecret }}
{{- else if .Values.global.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml .Values.global.imagePullSecrets | nindent 2 }}
{{- end }}
{{- end }}
