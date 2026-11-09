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
The image pull secret every Gentics chart falls back to when nothing else is
configured. Kept here so all consuming charts (cms, mesh, portal-java, ...) and
the CMP umbrella share one value instead of repeating it in each values.yaml.
Priority:
  1. global.defaultImagePullSecret  (umbrella-wide override, e.g. a mirror)
  2. chart-local .Values.defaultImagePullSecret
  3. the built-in default below
Setting either value to "" disables the fallback entirely (no imagePullSecrets
block is emitted); an ABSENT key falls through to the next level, which is why
this uses kindIs "invalid" rather than default/coalesce.
Args: (dict "root" $)
*/}}
{{- define "gentics-common.defaultImagePullSecret" -}}
{{- $global := .root.Values.global | default dict -}}
{{- if not (kindIs "invalid" $global.defaultImagePullSecret) -}}
{{- $global.defaultImagePullSecret -}}
{{- else if not (kindIs "invalid" .root.Values.defaultImagePullSecret) -}}
{{- .root.Values.defaultImagePullSecret -}}
{{- else -}}
docker-gentics-com
{{- end -}}
{{- end -}}

{{/*
Image pull secrets block — local secret NAME (string), three-state.
Priority:
  1. local set, non-empty -> that secret alone (global is ignored, never merged)
  2. local set, but EMPTY -> no imagePullSecrets at all (explicit opt-out)
  3. local absent (no key) -> global.imagePullSecrets
  4. nothing set anywhere -> gentics-common.defaultImagePullSecret
Three-state logic is required here: `default`/`coalesce` cannot tell an explicit
empty value from an absent key (same reason as pvcKeepAnnotations below), so the
"was it set at all?" test is kindIs "invalid".
NOTE for consuming charts: do NOT ship `pullSecret: ""` as a default in values.yaml
— that is case 2 and would silently disable pull secrets for every install. Leave
the key out (commented) so it resolves as case 3.
Args: (dict "root" $ "localName" <string or nil>)
*/}}
{{- define "gentics-common.imagePullSecrets" -}}
{{- $global := .root.Values.global | default dict -}}
{{- $fallback := include "gentics-common.defaultImagePullSecret" (dict "root" .root) -}}
{{- if not (kindIs "invalid" .localName) }}
{{- if .localName }}
imagePullSecrets:
  - name: {{ .localName }}
{{- end }}
{{- else if $global.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml $global.imagePullSecrets | nindent 2 }}
{{- else if $fallback }}
imagePullSecrets:
  - name: {{ $fallback }}
{{- end }}
{{- end }}

{{/*
Image pull secrets block — local LIST (array), three-state.
Same priority as gentics-common.imagePullSecrets above, except that here the
explicit opt-out is an empty list ([]).
Args: (dict "root" $ "localList" <list or nil>)
*/}}
{{- define "gentics-common.imagePullSecretsList" -}}
{{- $global := .root.Values.global | default dict -}}
{{- $fallback := include "gentics-common.defaultImagePullSecret" (dict "root" .root) -}}
{{- if not (kindIs "invalid" .localList) }}
{{- if .localList }}
imagePullSecrets:
  {{- toYaml .localList | nindent 2 }}
{{- end }}
{{- else if $global.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml $global.imagePullSecrets | nindent 2 }}
{{- else if $fallback }}
imagePullSecrets:
  - name: {{ $fallback }}
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
{{- /*
CMP example installation: a throwaway demo, so its volumes go away with it.
This deliberately overrides global.persistence.keepOnUninstall rather than
deferring to it — the umbrella writes that key explicitly (default true), so
there is no "unset" state to detect and deferring would make this a no-op.
A chart-local keepOnUninstall still wins below, as the per-component escape.
*/ -}}
{{- $example := ((.root.Values.global | default dict).example) | default dict -}}
{{- if $example.enabled -}}
{{- $keep = false -}}
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

{{/*
OpenTelemetry env vars for a Java component (OTel Java agent baked into the image).
Renders NOTHING when telemetry is off for the component, so charts that do not use
it render byte-identical output.
On/off:    local.enabled true/false -> global.otel.enabled -> off.
           An absent or null local.enabled follows the global switch (kindIs "bool").
Endpoint:  local.endpoint -> global.otel.endpoint -> the CMP umbrella's bundled
           Collector "http://<release>-opentelemetry-collector:4318". The umbrella
           validates that the bundled Collector is installed when it is used.
Protocol:  local.protocol -> global.otel.protocol -> "http/protobuf".
Agent:     loaded through JDK_JAVA_OPTIONS, so JAVA_TOOL_OPTIONS (heap) stays as it
           is. local.agentPath -> defaultAgentPath; an empty defaultAgentPath makes
           local.agentPath required. A missing jar stops the JVM from starting.
Resource:  service.namespace = global.otel.serviceNamespace -> "<namespace>-<release>".
Headers:   local.headersSecret -> global.otel.headersSecret (Secret name, key
           "headers") -> OTEL_EXPORTER_OTLP_HEADERS; omitted when both are empty.
           For OTLP endpoints that need authentication (e.g. an API token).
Every variable whose name is already set in extraEnv is skipped, so the user's value
wins and no duplicate env names reach Kubernetes. OTEL_POD_NAME is emitted before
OTEL_RESOURCE_ATTRIBUTES, which references it as $(OTEL_POD_NAME).
Output: env list items at column 0 (or nothing). Callers indent them inside a
`with`, so that "off" leaves no blank line behind:
  {{- with include "gentics-common.otelEnv" (dict ...) }}
  {{- . | nindent 10 }}
  {{- end }}
Args: (dict "root" $ "local" <otel map> "extraEnv" <env list>
            "defaultServiceName" <string> "defaultAgentPath" <string, "" = required>)
*/}}
{{- define "gentics-common.otelEnv" -}}
{{- $global := ((.root.Values.global | default dict).otel) | default dict -}}
{{- $local := .local | default dict -}}
{{- $enabled := $global.enabled -}}
{{- if kindIs "bool" $local.enabled -}}
{{- $enabled = $local.enabled -}}
{{- end -}}
{{- if $enabled -}}
{{- $agentPath := $local.agentPath | default .defaultAgentPath | required "otel.agentPath is required when telemetry is on for this component: the path of the OpenTelemetry Java agent jar inside the image" -}}
{{- $endpoint := $local.endpoint | default $global.endpoint | default (printf "http://%s-opentelemetry-collector:4318" .root.Release.Name) -}}
{{- $protocol := $local.protocol | default $global.protocol | default "http/protobuf" -}}
{{- $serviceNamespace := $global.serviceNamespace | default (printf "%s-%s" .root.Release.Namespace .root.Release.Name) -}}
{{- $env := list -}}
{{- $env = append $env (dict "name" "JDK_JAVA_OPTIONS" "value" (printf "-javaagent:%s" $agentPath)) -}}
{{- $env = append $env (dict "name" "OTEL_SERVICE_NAME" "value" ($local.serviceName | default .defaultServiceName)) -}}
{{- $env = append $env (dict "name" "OTEL_EXPORTER_OTLP_ENDPOINT" "value" $endpoint) -}}
{{- $env = append $env (dict "name" "OTEL_EXPORTER_OTLP_PROTOCOL" "value" $protocol) -}}
{{- $headersSecret := $local.headersSecret | default $global.headersSecret -}}
{{- if $headersSecret -}}
{{- $env = append $env (dict "name" "OTEL_EXPORTER_OTLP_HEADERS" "valueFrom" (dict "secretKeyRef" (dict "name" $headersSecret "key" "headers"))) -}}
{{- end -}}
{{- $env = append $env (dict "name" "OTEL_POD_NAME" "valueFrom" (dict "fieldRef" (dict "fieldPath" "metadata.name"))) -}}
{{- $env = append $env (dict "name" "OTEL_RESOURCE_ATTRIBUTES" "value" (printf "service.namespace=%s,k8s.namespace.name=%s,k8s.pod.name=$(OTEL_POD_NAME)" $serviceNamespace .root.Release.Namespace)) -}}
{{- $userNames := list -}}
{{- range (.extraEnv | default list) -}}
{{- $userNames = append $userNames .name -}}
{{- end -}}
{{- $out := list -}}
{{- range $env -}}
{{- if not (has .name $userNames) -}}
{{- $out = append $out . -}}
{{- end -}}
{{- end -}}
{{- if $out -}}
{{ toYaml $out }}
{{- end -}}
{{- end -}}
{{- end -}}
