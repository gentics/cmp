{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "gentics-portal-php.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "gentics-portal-php.fullname" -}}
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
{{- define "gentics-portal-php.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "gentics-portal-php.labels" -}}
helm.sh/chart: {{ include "gentics-portal-php.chart" . }}
{{ include "gentics-portal-php.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "gentics-portal-php.selectorLabels" -}}
app.kubernetes.io/name: {{ include "gentics-portal-php.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "gentics-portal-php.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "gentics-portal-php.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name Mesh secret
*/}}
{{- define "gentics-portal-php.mesh.secretName" -}}
{{- if .Values.mesh.secretName -}}
{{- .Values.mesh.secretName -}}
{{- else -}}
{{ .Release.Name }}-mesh-secret
{{- end -}}
{{- end -}}

{{/*
Fully qualified Portal image (registry/repository:tag, global.imageRegistry aware).
image.repository stays required — there is no pre-built portal image.
*/}}
{{- define "gentics-portal-php.image" -}}
{{- $_ := required "portal-php has no pre-built image. Build your portal image and set image.repository (see README)." .Values.image.repository -}}
{{- include "gentics-common.image" (dict "root" . "image" .Values.image) -}}
{{- end -}}

{{/*
Image pull secrets — local imagePullSecrets (array) overrides global; global is the default.
*/}}
{{- define "gentics-portal-php.imagePullSecrets" -}}
{{- include "gentics-common.imagePullSecretsList" (dict "root" . "localList" .Values.imagePullSecrets) -}}
{{- end }}

{{/*
URL of the Gentics Mesh instance the portal connects to.
Priority: explicit mesh.url -> umbrella Mesh service ("http://<release>-mesh:80",
requires global.mesh.enabled) -> required error.
*/}}
{{- define "gentics-portal-php.meshUrl" -}}
{{- $globalMesh := ((.Values.global | default dict).mesh) | default dict -}}
{{- if .Values.mesh.url -}}
{{ .Values.mesh.url }}
{{- else if $globalMesh.enabled -}}
http://{{ include "gentics-common.meshServiceHost" (dict "root" . "local" "") }}:{{ include "gentics-common.meshServicePort" (dict "root" . "local" "") }}
{{- else -}}
{{ required "mesh.url is required when not running under the CMP umbrella (global.mesh.enabled=false)" "" }}
{{- end -}}
{{- end -}}
