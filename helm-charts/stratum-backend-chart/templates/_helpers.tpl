{{- define "stratum-backend-chart.image" -}}
{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}
{{- end -}}

{{- define "stratum-backend-chart.labels" -}}
helm.sh/chart: {{ include "stratum-backend-chart.chart" . }}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
{{- define "stratum-backend-chart.chart" -}}
{{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}
{{- define "stratum-backend-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}