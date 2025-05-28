{{- define "result-app.fullname" -}}
{{ .Release.Name }}-result
{{- end }}

{{- define "result-app.labels" -}}
app.kubernetes.io/name: {{ include "result-app.fullname" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
