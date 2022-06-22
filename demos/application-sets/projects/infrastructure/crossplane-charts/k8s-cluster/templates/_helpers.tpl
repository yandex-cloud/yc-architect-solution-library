{{/*
Crossplane managed resource deletionPolicy.
*/}}
{{- define "crossplane.deletionPolicy" -}}
deletionPolicy: Delete
{{- end }}

{{/*
Crossplane labels.
*/}}
{{- define "crossplane.labels" -}}
labels:
  crossplane.io/app: crossplane
{{- end }}

{{/*
Prints a managed resource full name.
*/}}
{{- define "crossplane.fullname" -}}
{{- printf "%s-%s" .Values.projectName .Values.projectSuffix }}
{{- end }}

{{/*
Insert providerConfigRef.
*/}}
{{- define "crossplane.provider" -}}
providerConfigRef:
  name: {{ .Values.providerConfigName }}
{{- end }}

{{/*
Insert folderIdRef.
*/}}
{{- define "crossplane.folderid" -}}
folderIdRef:
  name: folder-{{ .Values.projectName }}-{{ .Values.projectSuffix }}
{{- end }}