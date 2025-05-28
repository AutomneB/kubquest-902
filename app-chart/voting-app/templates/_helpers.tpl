{{/*
Return the name of the chart
*/}}
{{- define "voting-app.name" -}}
{{ .Chart.Name }}
{{- end }}

{{/*
Return a full name using the release name
*/}}
{{- define "voting-app.fullname" -}}
{{ .Release.Name }}-{{ include "voting-app.name" . }}
{{- end }}

{{/*
Standard labels for all resources
*/}}
{{- define "voting-app.labels" -}}
app.kubernetes.io/name: {{ include "voting-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/component: frontend
app.kubernetes.io/part-of: demo-voting
{{- end }}

{{/*
Selector labels — must match exactly between Deployment.selector.matchLabels and pod template metadata.labels
Keep it minimal and stable
*/}}
{{- define "voting-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "voting-app.name" . }}
{{- end }}