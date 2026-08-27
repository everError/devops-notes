# Git

명령어 하나하나의 사용법보다 **"이 상황에서 무엇을 써야 하는가"** 를 먼저 찾을 수 있도록 정리한 문서입니다.

---

## 📂 문서 목록

| 문서 | 다루는 내용 |
|---|---|
| [01. 기본 개념과 명령어](./notes/01-basics.md) | 세 영역 모델, `init` / `clone` / `add` / `commit` / `status` |
| [02. 브랜치와 병합](./notes/02-branch-and-merge.md) | `branch` / `switch` / `merge`, fast-forward, 충돌 해결 |
| [03. 원격 저장소](./notes/03-remote.md) | `remote` / `fetch` / `pull` / `push`, upstream, 강제 푸시 |
| [04. Rebase](./notes/04-rebase.md) | `rebase`, 대화형 정리, `--onto`, GitLab 의 Rebase 버튼 |
| [05. 되돌리기](./notes/05-undo.md) | `reset` / `revert` / `restore` / `clean` / `reflog` |
| [06. 조회와 추적](./notes/06-inspect.md) | `log` / `diff` / `show` / `blame` / `bisect` |
| [07. 심화 도구](./notes/07-advanced.md) | `stash` / `cherry-pick` / `tag` / `worktree` / `submodule` |
| [08. 설정과 협업 흐름](./notes/08-config-and-workflow.md) | `config`, `.gitignore`, 브랜치 전략, 머지 요청 흐름 |

---

## 🎯 상황별 색인

### 커밋하기 전

| 상황 | 명령어 | 문서 |
|---|---|---|
| 지금 무엇이 바뀌었는지 보기 | `git status -s`, `git diff` | [01](./notes/01-basics.md) |
| 한 파일에서 일부 변경만 커밋 | `git add -p` | [01](./notes/01-basics.md) |
| 방금 스테이징한 것을 내리기 | `git restore --staged <file>` | [05](./notes/05-undo.md) |
| 수정한 것을 통째로 버리기 | `git restore <file>` | [05](./notes/05-undo.md) |
| 지금 일을 잠시 치워두기 | `git stash push -u -m "메모"` | [07](./notes/07-advanced.md) |

### 커밋한 뒤

| 상황 | 명령어 | 문서 |
|---|---|---|
| 마지막 커밋 메시지 고치기 | `git commit --amend` | [01](./notes/01-basics.md) |
| 마지막 커밋에 파일 하나 더 넣기 | `git add <file> && git commit --amend --no-edit` | [01](./notes/01-basics.md) |
| 커밋을 취소하되 변경은 남기기 | `git reset --soft HEAD~1` | [05](./notes/05-undo.md) |
| 이미 공유한 커밋을 무르기 | `git revert <sha>` | [05](./notes/05-undo.md) |
| 커밋 여러 개를 하나로 합치기 | `git rebase -i HEAD~N` | [04](./notes/04-rebase.md) |
| 다른 브랜치의 커밋 하나만 가져오기 | `git cherry-pick <sha>` | [07](./notes/07-advanced.md) |

### 협업 중

| 상황 | 명령어 | 문서 |
|---|---|---|
| 원격 최신 상태만 받아오기(병합 없이) | `git fetch --prune` | [03](./notes/03-remote.md) |
| 내 브랜치를 최신 main 위로 올리기 | `git rebase origin/main` | [04](./notes/04-rebase.md) |
| 머지 요청이 "rebase 필요" 라고 뜰 때 | GitLab Rebase 버튼 또는 위 명령 | [04](./notes/04-rebase.md) |
| rebase 후 원격에 올리기 | `git push --force-with-lease` | [03](./notes/03-remote.md) |
| 원격이 rebase 되어 내 로컬이 어긋날 때 | `git fetch origin && git reset --hard origin/<브랜치>` | [03](./notes/03-remote.md) |
| 충돌이 났을 때 | `git status` 로 목록 확인 후 해결 | [02](./notes/02-branch-and-merge.md) |

### 문제가 생겼을 때

| 상황 | 명령어 | 문서 |
|---|---|---|
| 방금 한 조작을 되돌리고 싶다 | `git reflog` 로 이전 위치 찾기 | [05](./notes/05-undo.md) |
| 진행 중인 병합/rebase 를 취소 | `git merge --abort`, `git rebase --abort` | [02](./notes/02-branch-and-merge.md), [04](./notes/04-rebase.md) |
| 어느 커밋부터 고장났는지 찾기 | `git bisect` | [06](./notes/06-inspect.md) |
| 이 코드를 누가 왜 넣었는지 | `git blame`, `git log -S"문자열"` | [06](./notes/06-inspect.md) |
| 추적되지 않는 파일 정리 | `git clean -n` 으로 확인 후 `-fd` | [05](./notes/05-undo.md) |
