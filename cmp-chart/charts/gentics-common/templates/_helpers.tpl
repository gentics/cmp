{{/* vim: set filetype=mustache: */}}
{{/*
============================================================================
gentics-common — shared named templates for Gentics CMP charts.

This is a Helm LIBRARY chart: it defines templates but renders nothing itself.
Each consuming chart (cms, mesh, portal-java) declares it as a dependency and
wraps these generic helpers in its own chart-scoped helper names.

Every helper takes a single dict argument and reads the release/values context
through `.root` (the chart's `$` / `.`), so the helpers are chart-agnostic.
============================================================================
*/}}

{{/*
Name of the license secret to reference.
Priority: explicit local secret -> umbrella global license secret -> chart-local fallback.
Args: (dict "root" $ "localSecret" <string> "fallbackName" <string>)
*/}}
{{- define "gentics-common.licenseSecretName" -}}
{{- $globalLicense := ((.root.Values.global | default dict).license) | default dict -}}
{{- if .localSecret -}}
{{ .localSecret }}
{{- else if $globalLicense.key -}}
{{ .root.Release.Name }}-license
{{- else -}}
{{ .fallbackName }}
{{- end -}}
{{- end -}}

{{/*
Image pull secrets block — local secret NAME (string) overrides global array.
Args: (dict "root" $ "localName" <string>)
*/}}
{{- define "gentics-common.imagePullSecrets" -}}
{{- $global := .root.Values.global | default dict -}}
{{- if .localName }}
imagePullSecrets:
  - name: {{ .localName }}
{{- else if $global.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml $global.imagePullSecrets | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Image pull secrets block — local LIST (array) overrides global array.
Args: (dict "root" $ "localList" <list>)
*/}}
{{- define "gentics-common.imagePullSecretsList" -}}
{{- $global := .root.Values.global | default dict -}}
{{- $secrets := coalesce .localList $global.imagePullSecrets -}}
{{- if $secrets }}
imagePullSecrets:
  {{- toYaml $secrets | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Fully qualified image reference "registry/repository:tag".
global.imageRegistry (umbrella) wins over the chart-local image.registry.
When no registry is set, emits "repository:tag" (back-compat with full-path repositories).
Args: (dict "root" $ "image" <image map with .registry .repository .tag>)
NOTE: defined for #20; not yet wired into any chart.
*/}}
{{- define "gentics-common.image" -}}
{{- $registry := coalesce ((.root.Values.global | default dict).imageRegistry) .image.registry -}}
{{- if $registry -}}
{{ $registry }}/{{ .image.repository }}:{{ .image.tag }}
{{- else -}}
{{ .image.repository }}:{{ .image.tag }}
{{- end -}}
{{- end -}}

{{/*
Database host.
Priority: explicit db.host -> bundled MariaDB service ("<release>-mariadb") -> required error.
Args: (dict "root" $ "db" <database map>)
*/}}
{{- define "gentics-common.databaseHost" -}}
{{- $db := .db | default dict -}}
{{- $globalMariadb := ((.root.Values.global | default dict).mariadb) | default dict -}}
{{- if $db.host -}}
{{ $db.host }}
{{- else if $globalMariadb.enabled -}}
{{ .root.Release.Name }}-mariadb
{{- else -}}
{{ required "database.host is required when global.mariadb.enabled is false" "" }}
{{- end -}}
{{- end -}}

{{/*
Generic database scalar (port / name / username) with a fallback default when the
bundled MariaDB is enabled.
Args: (dict "root" $ "db" <database map> "key" <field name> "default" <value> "requiredMsg" <string>)
*/}}
{{- define "gentics-common.databaseValue" -}}
{{- $db := .db | default dict -}}
{{- $globalMariadb := ((.root.Values.global | default dict).mariadb) | default dict -}}
{{- $val := index $db .key -}}
{{- if $val -}}
{{ $val }}
{{- else if $globalMariadb.enabled -}}
{{ .default }}
{{- else -}}
{{ required .requiredMsg "" }}
{{- end -}}
{{- end -}}

{{/*
Database password secretKeyRef block.
Priority: db.passwordSecret -> umbrella "<release>-<component>-db" -> chart-local secret -> required error.
Args: (dict "root" $ "db" <database map> "component" "cms"|"mesh"
            "localSecretName" <string> "localSecretKey" <string>)
*/}}
{{- define "gentics-common.databasePasswordRef" -}}
{{- $db := .db | default dict -}}
{{- $globalMariadb := ((.root.Values.global | default dict).mariadb) | default dict -}}
{{- if $db.passwordSecret -}}
secretKeyRef:
  name: {{ $db.passwordSecret }}
  key: password
{{- else if $globalMariadb.enabled -}}
secretKeyRef:
  name: {{ .root.Release.Name }}-{{ .component }}-db
  key: password
{{- else if $db.password -}}
secretKeyRef:
  name: {{ .localSecretName }}
  key: {{ .localSecretKey }}
{{- else -}}
{{ required "Either database.password, database.passwordSecret, or global.mariadb.enabled are required" "" }}
{{- end -}}
{{- end -}}
