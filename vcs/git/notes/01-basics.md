# 01. 기본 개념과 명령어

---

## 🎯 세 영역 모델

Git 의 거의 모든 명령어는 아래 세 영역 사이에서 파일을 옮기는 동작입니다. 이 구조를 알면 `add` / `reset` / `restore` 의 차이가 자연스럽게 정리됩니다.

```
작업 트리            인덱스(스테이징)          저장소(.git)
Working Tree   ──▶   Index / Staging   ──▶   Repository
                add                    commit

    ◀──────────────────────────────────────
       restore <file>        reset --soft
              restore --staged <file>
```

| 영역 | 의미 | 확인 방법 |
|---|---|---|
| 작업 트리 | 실제 파일이 놓인 디렉토리 | `git diff` (인덱스와의 차이) |
| 인덱스 | 다음 커밋에 담길 내용의 예약 목록 | `git diff --staged` (커밋과의 차이) |
| 저장소 | 확정된 커밋들의 기록 | `git log` |

**HEAD** 는 현재 체크아웃된 커밋을 가리키는 포인터입니다. 보통 현재 브랜치의 마지막 커밋을 가리킵니다.

- `HEAD~1` : 한 세대 위 커밋(첫 번째 부모를 따라감)
- `HEAD^2` : 병합 커밋의 두 번째 부모
- `HEAD@{2}` : reflog 기준으로 두 단계 전에 HEAD 가 있던 위치

---

## 1. 저장소 만들기

### `git init`

빈 디렉토리를 저장소로 만듭니다.

```bash
git init                      # 현재 디렉토리를 저장소로
git init -b main              # 기본 브랜치 이름을 main 으로 지정
```

### `git clone`

원격 저장소를 복제합니다.

```bash
git clone <url>
git clone <url> <디렉토리명>          # 다른 이름으로 받기
git clone --branch develop <url>     # 특정 브랜치를 체크아웃한 상태로 받기
git clone --depth 1 <url>            # 최근 1개 커밋만 (얕은 복제, CI 에서 유용)
git clone --recurse-submodules <url> # 서브모듈까지 함께
```

| 옵션 | 동작 |
|---|---|
| `--depth <n>` | 히스토리를 n개 커밋으로 잘라서 받음. 용량과 시간을 크게 줄이지만 `log` 로 과거를 볼 수 없고 rebase 범위가 제한됨 |
| `--filter=blob:none` | 커밋과 트리는 모두 받되 파일 내용은 필요할 때 받아옴. `--depth` 보다 제약이 적은 대안 |
| `--single-branch` | 지정한 브랜치 하나만 추적 |

---

## 2. 상태 확인

### `git status`

```bash
git status
git status -s                 # 짧은 형식
git status -sb                # 짧은 형식 + 브랜치/원격 대비 상태
git status --ignored          # 무시된 파일도 표시
```

`-s` 출력에서 앞의 두 글자는 순서대로 **인덱스 상태**, **작업 트리 상태** 입니다.

| 표기 | 의미 |
|---|---|
| `M ` | 수정 후 스테이징됨 |
| ` M` | 수정했으나 스테이징 안 됨 |
| `MM` | 스테이징한 뒤 또 수정함 |
| `A ` | 새로 추가되어 스테이징됨 |
| `??` | 추적되지 않는 파일 |
| `UU` | 양쪽에서 수정되어 충돌 |

---

## 3. 스테이징

### `git add`

```bash
git add <file>
git add .                     # 현재 디렉토리 이하 전부
git add -A                    # 저장소 전체 (삭제 포함)
git add -u                    # 이미 추적 중인 파일의 변경만 (새 파일 제외)
git add -p                    # 변경 덩어리 단위로 골라서 스테이징
git add -n .                  # 실제로 넣지 않고 대상만 미리 보기
```

| 옵션 | 동작 |
|---|---|
| `-A`, `--all` | 추가·수정·삭제 전부 반영 |
| `-u`, `--update` | 추적 중인 파일만. 새 파일은 건드리지 않음 |
| `-p`, `--patch` | 파일 안의 변경 덩어리를 하나씩 물어보며 선택. 한 파일에 섞인 작업을 분리해 커밋할 때 사용 |
| `-f`, `--force` | `.gitignore` 로 무시된 파일을 강제로 추가 |

`add -p` 대화형 응답:

| 키 | 동작 |
|---|---|
| `y` / `n` | 이 덩어리를 넣음 / 넘김 |
| `s` | 덩어리를 더 잘게 나눔 |
| `e` | 직접 편집해서 일부 줄만 반영 |
| `q` | 중단 |

### 파일 삭제와 이동

```bash
git rm <file>                 # 파일 삭제 + 스테이징
git rm --cached <file>        # 파일은 남기고 추적만 해제 (실수로 커밋한 설정 파일 처리)
git mv <old> <new>            # 이동/이름 변경 + 스테이징
```

---

## 4. 커밋

### `git commit`

```bash
git commit -m "메시지"
git commit                    # 편집기를 열어 여러 줄 메시지 작성
git commit -a -m "메시지"     # 추적 중인 파일의 변경을 자동 스테이징 후 커밋 (새 파일 제외)
git commit --amend            # 마지막 커밋을 고쳐 씀
git commit --amend --no-edit  # 메시지는 그대로 두고 내용만 갱신
```

| 옵션 | 동작 |
|---|---|
| `-a` | `add -u` 와 커밋을 한 번에. **추적되지 않는 새 파일은 포함되지 않는 점**에 주의 |
| `--amend` | 새 커밋을 만드는 대신 마지막 커밋을 대체. **해시가 바뀌므로** 이미 공유한 커밋에는 사용하지 않음 |
| `--no-edit` | `--amend` 시 편집기를 열지 않고 기존 메시지 유지 |
| `--fixup=<sha>` | 나중에 `rebase -i --autosquash` 로 자동 합쳐질 임시 커밋 생성 |
| `--no-verify` | 커밋 훅을 건너뜀. 훅이 막는 이유를 확인하지 않고 우회하는 것이므로 권장하지 않음 |

### 커밋 메시지

```
<타입>: <한 줄 요약, 명령형, 마침표 없음>

무엇을 왜 바꿨는지. 어떻게 바꿨는지는 코드가 말해주므로
이유와 배경 위주로 적는다.
```

타입 예: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`

---

## 5. `.gitignore`

```gitignore
# 주석
node_modules/          # 디렉토리
*.log                  # 확장자
/dist                  # 저장소 루트의 dist 만
!important.log         # 예외로 추적
**/temp/               # 모든 깊이의 temp
```

**이미 추적 중인 파일은 `.gitignore` 에 넣어도 계속 추적됩니다.** 추적을 끊어야 합니다.

```bash
git rm --cached <file>
git rm -r --cached .          # 전체 인덱스를 비우고 규칙을 다시 적용할 때
```

무시 규칙이 어디서 왔는지 확인:

```bash
git check-ignore -v <file>
```
