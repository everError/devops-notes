# Tekton CLI (`tkn`) 주요 명령어 요약

Tekton 리소스를 터미널에서 생성하고, 실행하며, 상태를 확인할 때 사용하는 핵심 `tkn` 명령어들을 정리했습니다.

-----

### \#\# 1. 리소스 생성 및 조회

YAML 파일로 정의된 리소스는 `kubectl`로 생성하지만, 생성된 리소스의 목록을 조회하는 것은 `tkn`이 더 편리합니다.

  * **Task/Pipeline 리소스 클러스터에 적용 (생성)**

    ```bash
    # 이 단계는 보통 kubectl을 사용합니다.
    kubectl apply -f <your-task-or-pipeline.yaml>
    ```

  * **Task/Pipeline 목록 조회**

    ```bash
    # Task 목록 보기
    tkn task ls

    # Pipeline 목록 보기
    tkn pipeline ls
    ```

-----

### \#\# 2. 리소스 실행 및 로그 확인

`Task`나 `Pipeline`을 실행하고 그 결과를 즉시 확인할 수 있습니다.

  * **Task 실행하기**

    ```bash
    # Task를 실행하고 바로 로그 확인
    tkn task start <TASK_NAME> --showlog
    ```

  * **Pipeline 실행하기**

    ```bash
    # Pipeline을 실행하고 바로 로그 확인
    tkn pipeline start <PIPELINE_NAME> --showlog
    ```

      * *Pipeline이 파라미터(params)나 워크스페이스(workspaces)를 필요로 할 경우, CLI에서 입력하라는 프롬프트가 나타납니다.*

  * **가장 마지막 실행 로그 확인**

    ```bash
    # 가장 최근에 실행된 TaskRun의 로그 보기
    tkn taskrun logs --last -f

    # 가장 최근에 실행된 PipelineRun의 로그 보기
    tkn pipelinerun logs --last -f
    ```

      * `-f` 또는 `--follow` 옵션은 로그를 실시간으로 계속 출력해 줍니다.

-----

### \#\# 3. 실행 이력 및 상세 정보 확인

과거에 실행된 `TaskRun`이나 `PipelineRun`의 목록과 상세 내용을 확인할 수 있습니다.

  * **TaskRun / PipelineRun 목록 조회**

    ```bash
    # TaskRun 실행 이력 보기
    tkn taskrun ls

    # PipelineRun 실행 이력 보기
    tkn pipelinerun ls
    ```

  * **리소스 상세 정보 보기**

    ```bash
    # 특정 Task의 상세 정보(파라미터, 스텝 등) 확인
    tkn task describe <TASK_NAME>

    # 특정 Pipeline의 상세 정보 확인
    tkn pipeline describe <PIPELINE_NAME>

    # 특정 TaskRun의 상세 정보 확인
    tkn taskrun describe <TASKRUN_NAME>
    ```