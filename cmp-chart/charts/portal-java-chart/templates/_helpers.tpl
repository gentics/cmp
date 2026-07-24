{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "gentics-portal.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "gentics-portal.fullname" -}}
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
{{- define "gentics-portal.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "gentics-portal.labels" -}}
helm.sh/chart: {{ include "gentics-portal.chart" . }}
{{ include "gentics-portal.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "gentics-portal.selectorLabels" -}}
app.kubernetes.io/name: {{ include "gentics-portal.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "gentics-portal.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "gentics-portal.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name Mesh secret
*/}}
{{- define "gentics-portal.mesh.secretName" -}}
{{- if .Values.mesh.secretName -}}
{{- .Values.mesh.secretName -}}
{{- else -}}
{{ .Release.Name }}-mesh-secret
{{- end -}}
{{- end -}}

{{/*
Gentics Mesh host/port the portal connects to.
Priority: explicit mesh.host/mesh.port -> umbrella Mesh service ("<release>-mesh":80,
requires global.mesh.enabled) -> required error.
*/}}
{{- define "gentics-portal.meshHost" -}}
{{- include "gentics-common.meshServiceHost" (dict "root" . "local" .Values.mesh.host) -}}
{{- end -}}

{{- define "gentics-portal.meshPort" -}}
{{- include "gentics-common.meshServicePort" (dict "root" . "local" .Values.mesh.port) -}}
{{- end -}}

{{/*
Fully qualified Portal image (registry/repository:tag, global.imageRegistry aware).
image.repository stays required — there is no pre-built portal image.
*/}}
{{- define "gentics-portal.image" -}}
{{- $_ := required "portal-java has no pre-built image. Build your portal image and set image.repository (see README)." .Values.image.repository -}}
{{- include "gentics-common.image" (dict "root" . "image" .Values.image) -}}
{{- end -}}

{{/*
Image pull secrets — local imagePullSecrets (array) overrides global; global is the default.
*/}}
{{- define "gentics-portal.imagePullSecrets" -}}
{{- include "gentics-common.imagePullSecretsList" (dict "root" . "localList" .Values.imagePullSecrets) -}}
{{- end }}

{{/*
Name of the secret containing the Portal license key.
Priority: local license.secret -> umbrella global license secret ("<release>-license")
         -> chart-local "<fullname>-secrets" (holds license.key or legacy licenseKey).
*/}}
{{- define "gentics-portal.licenseSecretName" -}}
{{- include "gentics-common.licenseSecretName" (dict "root" . "localSecret" .Values.license.secret "fallbackName" (printf "%s-secrets" (include "gentics-portal.fullname" .))) -}}
{{- end -}}
