# 📘 Helm `_helpers.tpl` 파일 개념 및 사용법

`_helpers.tpl` 파일은 Helm Chart 내에서 **반복적으로 사용하는 이름, 라벨, 어노테이션 등의 값**을 **템플릿 함수**로 정의하여 재사용성을 높이고 관리 편의성을 향상시키는 용도로 사용됩니다.

---

## 🔹 `_helpers.tpl` 위치

* 경로: `charts/<chart-name>/templates/_helpers.tpl`
* 이 파일은 Helm이 자동으로 인식하며, `define`과 `include` 키워드를 통해 활용됩니다.

---

## 🔹 주요 개념

### 🔸 define

Helm 템플릿 안에서 함수를 정의할 때 사용합니다.

```yaml
{{- define "<함수이름>" -}}
<반환할 텍스트나 YAML>
{{- end -}}
```

### 🔸 include

정의한 템플릿 함수를 불러와 사용할 때 사용합니다.

```yaml
{{ include "<함수이름>" . }}
```

* 두 번째 인자인 `.`은 현재 컨텍스트를 넘겨주는 것입니다 (예: `.Values`, `.Chart`, `.Release` 등 사용 가능).

### 🔸 nindent

렌더링된 문자열에 들여쓰기를 적용합니다.

```yaml
{{ include "mychart.labels" . | nindent 4 }}
```

* 출력된 YAML을 구조에 맞게 정렬할 수 있습니다.

---

## 🔹 예시: `_helpers.tpl` 정의

```yaml
{{- define "mychart.name" -}}
{{ .Chart.Name }}
{{- end -}}

{{- define "mychart.labels" -}}
app.kubernetes.io/name: {{ include "mychart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
```

---

## 🔹 예시: 다른 템플릿 파일에서 사용하기 (예: `deployment.yaml`)

```yaml
metadata:
  name: {{ include "mychart.name" . }}
  labels:
    {{ include "mychart.labels" . | nindent 4 }}
```

---

## ✅ `_helpers.tpl` 사용 시 장점

| 장점          | 설명                               |
| ----------- | -------------------------------- |
| **중복 제거**   | 라벨, 이름, 어노테이션 등의 반복된 내용 추출 가능    |
| **유지보수 용이** | 한 곳만 수정하면 전체 템플릿에 적용됨            |
| **가독성 향상**  | 주요 로직은 템플릿 파일에, 공통 로직은 헬퍼로 분리 가능 |

---