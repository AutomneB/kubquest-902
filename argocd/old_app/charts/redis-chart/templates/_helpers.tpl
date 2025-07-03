{{- define "redis.fullname" -}}
redis
{{- end }}

{{- define "redis-chart.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end }}

{{- define "redis-chart.chart" -}}
{{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}
