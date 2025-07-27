# Tekton YAML 주요 필드 정리

Tekton 파이프라인을 구성하는 핵심 리소스(`Task`, `Pipeline`, `PipelineRun`)의 주요 YAML 필드를 정리했습니다.

---

## Task

`Task`는 파이프라인의 가장 작은 실행 단위로, 하나 이상의 스텝(`steps`)으로 구성됩니다.

* `apiVersion: tekton.dev/v1`
* `kind: Task`
* `metadata`: Task의 이름(`name`) 등 메타데이터를 정의합니다.
* **`spec`**: Task의 명세를 정의하는 핵심 부분입니다.
    * **`params`**: Task 실행 시 외부에서 받을 파라미터(매개변수)를 정의합니다.
    * **`steps`**: 실제 작업이 실행되는 단계들의 배열입니다. 각 스텝은 하나의 컨테이너에서 실행됩니다.
        * `name`: 스텝의 고유한 이름입니다.
        * `image`: 스텝에서 사용할 컨테이너 이미지입니다.
        * `script`: 여러 줄의 셸 스크립트를 실행할 때 사용합니다.
        * `command` / `args`: 컨테이너의 Entrypoint와 Command를 직접 지정합니다.
    * **`workspaces`**: 여러 `steps` 또는 다른 `Task`와 파일 시스템을 공유하기 위한 작업 공간을 정의합니다.
    * **`results`**: Task 실행 후 결과물(문자열)을 다른 Task에 전달하기 위해 사용됩니다.

---

## Pipeline

`Pipeline`은 여러 `Task`들을 묶어 실행 순서와 데이터 흐름을 정의합니다.

* `apiVersion: tekton.dev/v1`
* `kind: Pipeline`
* `metadata`: Pipeline의 이름(`name`) 등 메타데이터를 정의합니다.
* **`spec`**: Pipeline의 명세를 정의하는 핵심 부분입니다.
    * **`params`**: Pipeline 전체에서 사용할 파라미터를 정의합니다.
    * **`workspaces`**: Pipeline에 참여하는 `Task`들이 사용할 공통 작업 공간을 정의합니다.
    * **`tasks`**: Pipeline을 구성하는 `Task`들의 목록과 실행 순서를 정의합니다.
        * `name`: 해당 단계의 고유한 이름입니다.
        * `taskRef`: 실행할 `Task`의 이름을 참조합니다.
        * `params`: 참조하는 `Task`에 전달할 파라미터 값을 지정합니다.
        * `runAfter`: 특정 `Task`가 끝난 후에 이 단계를 실행하도록 순서를 강제합니다.
        * `workspaces`: `Task`의 `workspace`를 Pipeline의 `workspace`와 연결합니다.

---

## PipelineRun

`PipelineRun`은 `Pipeline`을 실제로 실행시키는 객체입니다.

* `apiVersion: tekton.dev/v1`
* `kind: PipelineRun`
* `metadata`: `PipelineRun`의 메타데이터를 정의합니다. (`generateName` 사용 시 고유 이름 생성)
* **`spec`**: `PipelineRun`의 명세를 정의합니다.
    * **`pipelineRef`**: 실행할 `Pipeline`의 이름을 참조합니다.
    * **`params`**: `Pipeline`에 정의된 `params`에 실제 값을 전달합니다.
    * **`workspaces`**: `Pipeline`에 정의된 `workspaces`에 실제 볼륨(`PersistentVolumeClaim` 등)을 할당합니다.