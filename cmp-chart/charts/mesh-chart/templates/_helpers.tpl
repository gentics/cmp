{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "mesh.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mesh.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "mesh.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "mesh.labels" -}}
helm.sh/chart: {{ include "mesh.chart" . }}
{{ include "mesh.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "mesh.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mesh.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "mesh.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "mesh.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/* Build Environment Variables with Overrides */}}
{{- define "mesh.envVars" }}
{{- $root := . -}}
{{- $extraEnv := .Values.extraEnv -}}
{{- $builtInEnv := (tpl ($.Files.Get "config/env.yaml") $root) | fromYaml }}
{{- range $builtInEnv.builtInEnvVariables -}}
{{- if eq "false" (include "hasEnvOverride" (list $extraEnv .name)) -}}
{{- range $k, $v := . -}}
{{ if eq $k "name" -}}
{{ print "- " $k ": " ($v | toYaml) }}
{{ else -}}
{{ print "  " $k ": " ($v | toJson) }}
{{ end -}}
{{- end -}}
{{- end -}}
{{- end -}}
## Extra Environment Variables
{{ toYaml $extraEnv }}
{{- end }}

{{/* Find a key/value pair in a list */}}
{{- define "hasKeyWithValue" -}}
  {{- $returnVal := false -}}
  {{- $list := index . 0 -}}
  {{- $key := index . 1 -}}
  {{- $value := index . 2 -}}
  {{/* Loop through the list */}}
  {{- range $list -}}
    {{/* Loop through the list items */}}
    {{- range $i, $val := . -}}
      {{/* Check if key and value matches */}}
      {{- if and (eq $i $key) (eq $val $value) -}}
        {{- $returnVal = true -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{/* Return the result */}}
{{- $returnVal -}}
{{- end -}}

{{/* Check if key name exists in the extraEnv list */}}
{{- define "hasEnvOverride" -}}
{{- $extraEnv := index . 0 -}}
{{- $inputVal := index . 1 -}}
{{- include "hasKeyWithValue" (list $extraEnv "name" $inputVal) -}}
{{- end -}}

{{/*
Database host for Mesh.
Uses explicit database.host if set; falls back to the bundled MariaDB service name
when global.mariadb.enabled is true; otherwise raises an error.
*/}}
{{- define "mesh.databaseHost" -}}
{{- $db := .Values.database | default dict -}}
{{- if $db.host -}}
{{ $db.host }}
{{- else if .Values.global.mariadb.enabled -}}
{{ .Release.Name }}-mariadb
{{- else -}}
{{ required "database.host is required when global.mariadb.enabled is false" "" }}
{{- end -}}
{{- end -}}

{{/*
Database port for Mesh.
Uses explicit database.port if set; falls back to 3306 when global.mariadb.enabled.
*/}}
{{- define "mesh.databasePort" -}}
{{- $db := .Values.database | default dict -}}
{{- if $db.port -}}
{{ $db.port }}
{{- else if .Values.global.mariadb.enabled -}}
3306
{{- else -}}
{{ required "database.port is required when global.mariadb.enabled is false" "" }}
{{- end -}}
{{- end -}}

{{/*
Database name for Mesh.
Uses explicit database.name if set; falls back to "mesh" when global.mariadb.enabled.
*/}}
{{- define "mesh.databaseName" -}}
{{- $db := .Values.database | default dict -}}
{{- if $db.name -}}
{{ $db.name }}
{{- else if .Values.global.mariadb.enabled -}}
mesh
{{- else -}}
{{ required "database.name is required when global.mariadb.enabled is false" "" }}
{{- end -}}
{{- end -}}

{{/*
Database username for Mesh.
Uses explicit database.username if set; falls back to "mesh" when global.mariadb.enabled.
*/}}
{{- define "mesh.databaseUsername" -}}
{{- $db := .Values.database | default dict -}}
{{- if $db.username -}}
{{ $db.username }}
{{- else if .Values.global.mariadb.enabled -}}
mesh
{{- else -}}
{{ required "database.username is required when global.mariadb.enabled is false" "" }}
{{- end -}}
{{- end -}}

{{/*
Secret name and key for the Mesh database password.
Priority: explicit database.passwordSecret → umbrella MariaDB secret → sub-chart local secret.
Returns a full secretKeyRef block.
*/}}
{{- define "mesh.databasePasswordRef" -}}
{{- $db := .Values.database | default dict -}}
{{- if $db.passwordSecret -}}
secretKeyRef:
  name: {{ $db.passwordSecret }}
  key: password
{{- else if .Values.global.mariadb.enabled -}}
secretKeyRef:
  name: {{ .Release.Name }}-mesh-db
  key: password
{{- else if $db.password -}}
secretKeyRef:
  name: {{ include "mesh.fullname" . }}-database
  key: password
{{- else -}}
{{ required "Either database.password, database.passwordSecret, or global.mariadb.enabled are required" "" }}
{{- end -}}
{{- end -}}

{{/*
Name of the secret containing the Mesh license key.
Priority: local license.secret (explicit override) → global license secret (umbrella chart)
         → mesh.fullname-secrets (sub-chart's own secret, when license.key is set locally).
Note: Mesh mounts the license from the shared PVC, not directly from this secret.
      This helper is provided for consistency and future use.
*/}}
{{- define "mesh.licenseSecretName" -}}
{{- if .Values.license.secret -}}
{{ .Values.license.secret }}
{{- else if .Values.global.license.key -}}
{{ .Release.Name }}-license
{{- else -}}
{{ include "mesh.fullname" . }}-secrets
{{- end -}}
{{- end -}}

{{/*
Image pull secrets for the main Mesh image.
Local imagePullSecrets overrides global; global is the default. Both use the array format.
*/}}
{{- define "mesh.imagePullSecrets" -}}
{{- $secrets := coalesce .Values.imagePullSecrets .Values.global.imagePullSecrets -}}
{{- if $secrets }}
imagePullSecrets:
  {{- toYaml $secrets | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Image pull secrets for the Mesh tools image.
Local tools.image.pullSecret overrides global; global is the default.
Local accepts a plain secret name string; global uses the array format.
*/}}
{{- define "mesh.toolsImagePullSecrets" -}}
{{- if .Values.tools.image.pullSecret }}
imagePullSecrets:
  - name: {{ .Values.tools.image.pullSecret }}
{{- else if .Values.global.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml .Values.global.imagePullSecrets | nindent 2 }}
{{- end }}
{{- end }}
