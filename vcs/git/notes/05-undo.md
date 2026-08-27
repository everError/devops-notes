# 05. 되돌리기

---

## 🎯 먼저 물어볼 두 가지

되돌리기 명령을 고르는 기준은 두 가지뿐입니다.

1. **무엇을 되돌리는가?** 작업 트리 / 인덱스 / 커밋
2. **이미 공유했는가?** 공유했다면 이력을 바꾸는 명령은 쓸 수 없습니다.

| 대상 | 공유 전 | 공유 후 |
|---|---|---|
| 작업 트리의 파일 수정 | `git restore <file>` | 동일 |
| 스테이징 | `git restore --staged <file>` | 동일 |
| 마지막 커밋 | `git reset` / `git commit --amend` | `git revert` |
| 과거 커밋 | `git rebase -i` | `git revert` |
| 추적되지 않는 파일 | `git clean` | 동일 |

---

## 1. `git restore` — 파일 단위 복원

```bash
git restore <file>                        # 작업 트리의 수정을 버리고 인덱스 상태로
git restore .                             # 전체
git restore --staged <file>               # 스테이징만 해제 (수정 내용은 유지)
git restore --staged --worktree <file>    # 둘 다 되돌림
git restore --source=HEAD~2 <file>        # 두 커밋 전의 내용으로 가져오기
git restore --source=<브랜치> <file>       # 다른 브랜치의 파일 버전 가져오기
```

| 옵션 | 기준 | 동작 |
|---|---|---|
| (없음) | 인덱스 | 작업 트리를 인덱스 내용으로 덮어씀 |
| `--staged` | HEAD | 인덱스를 HEAD 내용으로 되돌림 |
| `--staged --worktree` | HEAD | 둘 다 HEAD 로 |
| `--source=<커밋>` | 지정 커밋 | 그 시점의 파일 내용을 가져옴 |

`--worktree` 로 되돌린 수정 내용은 **커밋된 적이 없으면 복구할 수 없습니다.** 애매하면 `git stash` 로 치워두는 편이 안전합니다.

---

## 2. `git reset` — 브랜치 포인터 이동

`reset` 은 현재 브랜치가 가리키는 커밋을 옮깁니다. 옵션은 "어디까지 함께 되돌릴 것인가" 를 정합니다.

```bash
git reset --soft HEAD~1       # 커밋만 취소. 변경은 스테이징된 채로 남음
git reset HEAD~1              # (--mixed, 기본) 커밋과 스테이징 취소. 파일 수정은 남음
git reset --hard HEAD~1       # 커밋·스테이징·파일 수정 전부 폐기
```

| 옵션 | 브랜치 포인터 | 인덱스 | 작업 트리 | 용도 |
|---|---|---|---|---|
| `--soft` | 이동 | 유지 | 유지 | 커밋 여러 개를 하나로 다시 묶을 때 |
| `--mixed`(기본) | 이동 | 초기화 | 유지 | 커밋과 스테이징만 취소하고 다시 나눠 담을 때 |
| `--hard` | 이동 | 초기화 | 초기화 | 전부 버릴 때. **커밋 안 한 변경은 복구 불가** |

### 자주 쓰는 형태

```bash
# 최근 3개 커밋을 하나로 다시 커밋
git reset --soft HEAD~3
git commit -m "기능 구현"

# 커밋은 취소하되 작업 내용은 그대로 두고 다시 정리
git reset HEAD~1

# 원격 상태로 완전히 맞추기
git fetch origin
git reset --hard origin/main

# 스테이징만 전부 해제 (옛 방식, restore --staged 와 동일 효과)
git reset
```

### `reset` 은 언제 위험한가

- `--hard` 는 **커밋되지 않은 변경을 되살릴 방법이 없습니다.**
- 이미 push 한 커밋을 `reset` 으로 지우면 이후 force push 가 필요하고, 공유 브랜치에서는 다른 사람의 이력이 깨집니다. 이 경우 `revert` 를 씁니다.

---

## 3. `git revert` — 되돌리는 커밋을 새로 만들기

이력을 바꾸지 않고, **반대 내용의 새 커밋**을 추가합니다. 이미 공유된 커밋을 무를 때의 정답입니다.

```bash
git revert <sha>                          # 되돌리는 커밋 생성
git revert -n <sha>                       # 커밋하지 않고 인덱스에만 반영
git revert <sha1>..<sha2>                 # 범위 되돌리기
git revert -m 1 <병합커밋sha>              # 병합 커밋 되돌리기
git revert --abort                        # 충돌 중 취소
git revert --continue
```

| 옵션 | 동작 |
|---|---|
| `-n`, `--no-commit` | 여러 개를 되돌리고 커밋 하나로 묶고 싶을 때 |
| `-m <부모번호>` | 병합 커밋은 부모가 둘이므로 **어느 쪽 기준으로 되돌릴지** 지정해야 함. 보통 `-m 1` 이 대상 브랜치(main) 쪽 |
| `--no-edit` | 자동 생성 메시지를 그대로 사용 |

> 병합 커밋을 revert 한 뒤 같은 브랜치를 다시 병합하면, Git 이 "이미 병합됨" 으로 보아 변경이 반영되지 않습니다. 이때는 **revert 를 다시 revert** 하거나 브랜치를 새로 따서 진행합니다.

---

## 4. `git clean` — 추적되지 않는 파일 정리

```bash
git clean -n                  # 삭제 대상 미리 보기 (반드시 먼저)
git clean -f                  # 파일 삭제
git clean -fd                 # 디렉토리까지
git clean -fdx                # .gitignore 로 무시된 파일까지 (빌드 산출물 전체 정리)
git clean -fdi                # 대화형으로 선택
```

`-x` 는 `node_modules`, `bin`, `obj`, 로컬 설정 파일까지 지웁니다. 완전히 새로 받은 상태를 만들 때만 사용합니다.

```bash
# 저장소를 갓 클론한 상태로 초기화
git reset --hard HEAD && git clean -fdx
```

---

## 5. `git reflog` — 최후의 복구 수단

reflog 는 **HEAD 와 브랜치가 이동한 모든 기록**입니다. reset, rebase, amend, 브랜치 삭제로 이력에서 사라진 커밋도 여기에 남아 있어 되살릴 수 있습니다.

```bash
git reflog                                # HEAD 이동 기록
git reflog show <브랜치>                   # 특정 브랜치의 기록
git reflog --date=iso                     # 시각 표시
```

```
a1b2c3d HEAD@{0}: reset: moving to HEAD~3
e4f5a6b HEAD@{1}: commit: 유효성 검사 추가
b7c8d9e HEAD@{2}: rebase (finish): returning to refs/heads/feature
```

### 복구

```bash
git reset --hard HEAD@{1}                 # 그 시점으로 되돌리기
git switch -c 복구브랜치 e4f5a6b           # 사라진 커밋에서 브랜치 생성
git cherry-pick e4f5a6b                   # 그 커밋만 현재 브랜치로 가져오기
```

### `ORIG_HEAD`

`merge`, `rebase`, `reset` 같은 큰 조작 직전의 위치가 자동으로 저장됩니다.

```bash
git reset --hard ORIG_HEAD                # 방금 한 병합/rebase 취소
```

> reflog 는 로컬 전용이며 기본 만료 기간이 있습니다(도달 가능한 항목 90일, 도달 불가 항목 30일). 클론한 저장소에는 이전 기록이 없습니다.

---

## 6. 상황별 정리

| 상황 | 명령 |
|---|---|
| 커밋 메시지를 잘못 썼다 (아직 push 안 함) | `git commit --amend` |
| 커밋 메시지를 잘못 썼다 (이미 push, 혼자 쓰는 브랜치) | `git commit --amend` 후 `git push --force-with-lease` |
| 파일 하나를 커밋에 빠뜨렸다 | `git add <file> && git commit --amend --no-edit` |
| 커밋을 잘못된 브랜치에 했다 | `git reset --soft HEAD~1` 후 브랜치 전환하고 다시 커밋<br>또는 올바른 브랜치에서 `git cherry-pick <sha>` 후 원래 브랜치에서 `reset --hard HEAD~1` |
| `--hard` 로 커밋을 날렸다 | `git reflog` 로 찾아 `git reset --hard <sha>` |
| 커밋하지 않은 수정을 `--hard` 로 날렸다 | 복구 불가 (편집기 자체 이력 외에는 방법 없음) |
| 브랜치를 `-D` 로 지웠다 | `git reflog` 에서 마지막 커밋을 찾아 `git switch -c <이름> <sha>` |
| 이미 배포된 변경을 무르고 싶다 | `git revert <sha>` |
| 병합 자체를 무르고 싶다 (아직 push 전) | `git reset --hard ORIG_HEAD` |
| 큰 파일을 실수로 커밋해 저장소가 무거워졌다 | `git filter-repo` 로 이력에서 제거 후 팀 전체가 다시 클론<br>(이력 전체가 바뀌므로 팀 합의 필수) |
