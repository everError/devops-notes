# 04. Rebase

---

## 🎯 한 줄 정의

**내 브랜치의 커밋들을 다른 커밋 위에 다시 얹는 것.** 기존 커밋을 옮기는 것이 아니라 **같은 변경 내용으로 새 커밋을 만들어 붙이므로 해시가 바뀝니다.**

```
before                          after: git rebase main
main ──A──B──E                  main ──A──B──E──C'──D'
            \                                     ↑
     feature ──C──D                        C,D 를 E 뒤로 다시 적용
```

---

## 1. merge 와의 비교

```
merge:  main ──A──B──E──────M   ← 병합 커밋 M 이 두 갈래를 합침
                  \        /
          feature ──C──D

rebase: main ──A──B──E──C'──D'  ← 일직선, C/D 의 해시는 바뀜
```

| | merge | rebase |
|---|---|---|
| 이력 | 분기·합류가 보존됨 | 일직선 |
| 커밋 해시 | 유지 | **새로 생성** |
| 원래 커밋 | 그대로 남음 | 버려짐(reflog 에는 남음) |
| 원격 반영 | 일반 push | **force push 필요** |
| 충돌 | 한 번에 해결 | 커밋 단위로 반복 가능 |
| 공유 브랜치 | 안전 | **금지** |

### 황금률

> **다른 사람이 받아 간 커밋은 rebase 하지 않는다.**

이미 공유된 커밋을 rebase 하면 같은 변경이 서로 다른 해시로 두 벌 존재하게 되어, 다른 사람이 pull 할 때 중복 커밋과 충돌이 발생합니다. 혼자 쓰는 기능 브랜치에서만 사용합니다.

---

## 2. 기본 사용

```bash
git switch feature
git fetch origin
git rebase origin/main        # 내 커밋들을 최신 main 위로 다시 얹음
```

한 줄로:

```bash
git pull --rebase origin main
```

### 진행 제어

충돌이 나면 rebase 는 그 커밋에서 멈춥니다.

```bash
# 파일을 수정해 충돌 해결 후
git add <file>
git rebase --continue         # 다음 커밋으로 진행

git rebase --skip             # 이 커밋을 버리고 진행 (내용이 이미 반영된 경우)
git rebase --abort            # 전부 취소하고 rebase 시작 전 상태로 복귀
```

> **ours/theirs 가 뒤바뀝니다.** rebase 는 기준 브랜치 위에 내 커밋을 재적용하므로, 충돌 시 **`--ours` = 기준 브랜치(main)**, **`--theirs` = 재적용 중인 내 커밋** 입니다. merge 때와 반대이므로 주의합니다.

### 주요 옵션

| 옵션 | 동작 |
|---|---|
| `-i`, `--interactive` | 커밋 목록을 편집기로 열어 순서 변경·합치기·삭제 |
| `--onto <새기준>` | 기준점을 명시적으로 지정 (아래 4절) |
| `--autosquash` | `fixup!` / `squash!` 커밋을 대상 커밋 아래로 자동 배치 |
| `--autostash` | 작업 트리가 더러워도 자동으로 stash 했다가 끝나고 복원 |
| `--update-refs` | 스택으로 쌓은 하위 브랜치들의 위치도 함께 갱신 (Git 2.38+) |
| `--rebase-merges` | 병합 커밋의 구조를 보존하며 재적용 |
| `--exec "<명령>"` | 각 커밋마다 명령 실행. 예: `--exec "npm test"` 로 모든 커밋에서 테스트 검증 |

```bash
git config --global rebase.autosquash true
git config --global rebase.autostash true
```

---

## 3. 대화형 rebase (`-i`)

커밋 이력을 정리하는 핵심 도구입니다.

```bash
git rebase -i HEAD~4          # 최근 4개 커밋 정리
git rebase -i origin/main     # main 이후 내 커밋 전체 정리
```

편집기에 아래와 같은 목록이 열립니다. **위가 오래된 커밋** 입니다.

```
pick a1b2c3d 로그인 폼 추가
pick d4e5f6a 오타 수정
pick b7c8d9e 유효성 검사 추가
pick e1f2a3b 콘솔 로그 제거
```

각 줄의 명령어를 바꾸고 저장하면 그대로 실행됩니다.

| 명령 | 축약 | 동작 |
|---|---|---|
| `pick` | `p` | 그대로 사용 |
| `reword` | `r` | 내용은 두고 메시지만 수정 |
| `edit` | `e` | 그 커밋에서 멈춤. 파일을 고치고 `--amend` 후 `--continue` |
| `squash` | `s` | 위 커밋에 합침. **메시지를 합쳐서 편집** |
| `fixup` | `f` | 위 커밋에 합침. **이 커밋의 메시지는 버림** |
| `drop` | `d` | 커밋 삭제 |
| `break` | `b` | 그 지점에서 일시 정지 |

줄 순서를 바꾸면 커밋 순서가 바뀌고, 줄을 지우면 `drop` 과 같습니다.

### 예: 잡다한 커밋 정리

```
pick a1b2c3d 로그인 폼 추가
fixup d4e5f6a 오타 수정          ← 위에 합치고 메시지 버림
pick b7c8d9e 유효성 검사 추가
drop e1f2a3b 콘솔 로그 제거      ← 삭제
```

결과는 커밋 2개가 됩니다.

### `--autosquash` 로 자동화

작업 중에 "이건 그 커밋에 들어갔어야 했는데" 싶을 때:

```bash
git add <file>
git commit --fixup=a1b2c3d    # "fixup! 로그인 폼 추가" 라는 커밋 생성
# ... 작업 계속 ...
git rebase -i --autosquash HEAD~5   # a1b2c3d 아래로 자동 배치되어 열림
```

메시지도 합치고 싶으면 `--squash=<sha>` 를 씁니다.

---

## 4. `--onto` — 기준점 갈아 끼우기

`git rebase --onto <새기준> <제외할범위> <대상브랜치>` 형태로, "어디부터 어디까지를 어디에 붙일지" 를 직접 지정합니다.

### 상황: 잘못된 브랜치에서 분기했을 때

```
main ──A──B
           \
    develop ──C──D
                  \
        feature ──E──F     ← develop 이 아니라 main 에서 땄어야 했음
```

```bash
git rebase --onto main develop feature
```

`develop` 에 있는 커밋(C, D)을 제외하고 E, F 만 `main` 위로 옮깁니다.

```
main ──A──B──E'──F'
           \
    develop ──C──D
```

### 상황: 앞쪽 커밋 몇 개만 버리기

```bash
git rebase --onto HEAD~5 HEAD~3 <브랜치>
# HEAD~5 위에, HEAD~3 이후의 커밋만 다시 얹음 → 가운데 2개가 제거됨
```

---

## 5. GitLab 의 Rebase 버튼

머지 요청 화면에 **Rebase** 버튼이 나타나는 경우:

1. **Fast-forward merge 정책** — 프로젝트가 병합 커밋을 만들지 않도록 설정되어 있으면, 소스 브랜치가 대상 브랜치보다 뒤처졌을 때 병합이 막힙니다. Rebase 로 최신 위에 올려야 병합이 열립니다.
2. **최신 대상 브랜치 기준으로 파이프라인을 다시 돌리고 싶을 때** — 먼저 병합된 다른 변경과 내 변경이 함께 있어도 문제가 없는지 확인합니다.

버튼을 누르면 GitLab 이 서버에서 rebase 한 뒤 **소스 브랜치를 force push** 합니다. 댓글에 `/rebase` 를 입력해도 동일하게 동작합니다.

### 주의

- **충돌이 있으면 버튼은 실패합니다.** 로컬에서 처리해야 합니다.

  ```bash
  git fetch origin && git rebase origin/main
  # 충돌 해결 후
  git push --force-with-lease
  ```

- **로컬 브랜치가 어긋납니다.** 버튼을 눌렀다면 로컬을 원격 기준으로 다시 맞춥니다.

  ```bash
  git fetch origin && git reset --hard origin/<브랜치>
  ```

- **여러 명이 함께 쓰는 브랜치의 머지 요청에는 사용하지 않습니다.** force push 이므로 다른 사람의 로컬 이력이 깨집니다.

---

## 6. 되돌리기와 확인

rebase 이전 커밋도 일정 기간 저장소에 남아 있으므로 복구할 수 있습니다.

```bash
git reflog                                # rebase 직전 위치 확인
git reset --hard HEAD@{5}                 # 그 시점으로 복귀

git reset --hard ORIG_HEAD                # 직전 rebase/merge 시작 지점으로 (더 간단)
```

rebase 전후를 비교하려면:

```bash
git range-diff origin/main HEAD@{1} HEAD
# 재적용 과정에서 변경 내용이 달라지지 않았는지 확인
```
