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
global.imageRegistry (umbrella-wide mirror override) wins over the chart-local
image.registry. When neither is set, emits "repository:tag" (back-compat with
registry-qualified repository paths).
Args: (dict "root" $ "image" <image map with .registry .repository .tag>
            "tag" <optional tag override, e.g. a resolved appVersion fallback>)
*/}}
{{- define "gentics-common.image" -}}
{{- $registry := coalesce ((.root.Values.global | default dict).imageRegistry) .image.registry -}}
{{- $tag := coalesce .tag .image.tag -}}
{{- if $registry -}}
{{ $registry }}/{{ .image.repository }}:{{ $tag }}
{{- else -}}
{{ .image.repository }}:{{ $tag }}
{{- end -}}
{{- end -}}

{{/*
Annotations for PersistentVolumeClaims so data survives uninstall/prune by default:
Helm skips deletion (resource-policy: keep), Argo CD skips pruning (Delete=false).
Keep/delete is decided at render time with this precedence:
  1. chart-local flag (pass as "local", e.g. .Values.persistence.keepOnUninstall)
  2. global.persistence.keepOnUninstall (umbrella-wide switch)
  3. unset everywhere -> keep (safe default)
Booleans need three-state logic here: default/coalesce would treat an explicit
`false` as "unset", so we use hasKey / kindIs "invalid" instead.
Full removal regardless of flags: kubectl delete pvc -l app.kubernetes.io/instance=<release>
Args: (dict "root" $ "local" <bool or nil>)
*/}}
{{- define "gentics-common.pvcKeepAnnotations" -}}
{{- $keep := true -}}
{{- $globalPersistence := ((.root.Values.global | default dict).persistence) | default dict -}}
{{- if hasKey $globalPersistence "keepOnUninstall" -}}
{{- if not (kindIs "invalid" $globalPersistence.keepOnUninstall) -}}
{{- $keep = $globalPersistence.keepOnUninstall -}}
{{- end -}}
{{- end -}}
{{- if not (kindIs "invalid" .local) -}}
{{- $keep = .local -}}
{{- end -}}
{{- if $keep -}}
helm.sh/resource-policy: keep
argocd.argoproj.io/sync-options: Delete=false
{{- end -}}
{{- end -}}

{{/*
Gentics Mesh service host for components that talk to Mesh (e.g. Portal).
Priority: explicit local host -> umbrella Mesh service ("<release>-mesh", requires
global.mesh.enabled) -> required error.
Args: (dict "root" $ "local" <host string>)
*/}}
{{- define "gentics-common.meshServiceHost" -}}
{{- $globalMesh := ((.root.Values.global | default dict).mesh) | default dict -}}
{{- if .local -}}
{{ .local }}
{{- else if $globalMesh.enabled -}}
{{ .root.Release.Name }}-mesh
{{- else -}}
{{ required "mesh.host is required when not running under the CMP umbrella (global.mesh.enabled=false)" "" }}
{{- end -}}
{{- end -}}

{{/*
Gentics Mesh service port. Same priority as meshServiceHost; umbrella default is 80
(the Mesh chart's service.mesh.port default).
Args: (dict "root" $ "local" <port>)
*/}}
{{- define "gentics-common.meshServicePort" -}}
{{- $globalMesh := ((.root.Values.global | default dict).mesh) | default dict -}}
{{- if .local -}}
{{ .local }}
{{- else if $globalMesh.enabled -}}
80
{{- else -}}
{{ required "mesh.port is required when not running under the CMP umbrella (global.mesh.enabled=false)" "" }}
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
