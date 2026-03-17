{{/*
Expand the name of the chart.
*/}}
{{- define "cotc.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
Truncated to 63 chars; trailing dashes removed.
*/}}
{{- define "cotc.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Chart label
*/}}
{{- define "cotc.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cotc.labels" -}}
helm.sh/chart: {{ include "cotc.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Per-component selector labels
Usage: {{ include "cotc.selectorLabels" (dict "root" . "component" "nats") }}
*/}}
{{- define "cotc.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cotc.name" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
Service name helpers — used across deployments and the nginx configmap.
*/}}
{{- define "cotc.natsServiceName" -}}
{{- printf "%s-nats" (include "cotc.fullname" .) }}
{{- end }}

{{- define "cotc.dbServiceName" -}}
{{- printf "%s-db" (include "cotc.fullname" .) }}
{{- end }}

{{- define "cotc.collectorServiceName" -}}
{{- printf "%s-cotccollector" (include "cotc.fullname" .) }}
{{- end }}

{{- define "cotc.subscriberServiceName" -}}
{{- printf "%s-cotcsubscriber" (include "cotc.fullname" .) }}
{{- end }}

{{- define "cotc.guiServiceName" -}}
{{- printf "%s-cotcgui" (include "cotc.fullname" .) }}
{{- end }}

{{- define "cotc.gatewayServiceName" -}}
{{- printf "%s-api-gateway" (include "cotc.fullname" .) }}
{{- end }}
