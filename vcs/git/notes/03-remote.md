# 03. 원격 저장소

---

## 🎯 원격 추적 브랜치

로컬에는 세 종류의 이름이 있습니다. 이 구분이 `fetch` 와 `pull` 의 차이를 설명합니다.

| 이름 | 예 | 의미 |
|---|---|---|
| 로컬 브랜치 | `main` | 내가 커밋하는 대상 |
| 원격 추적 브랜치 | `origin/main` | **마지막으로 통신했을 때** 원격이 어디였는지 기록한 캐시 |
| 원격의 실제 상태 | 서버의 `main` | 통신해야만 알 수 있음 |

`origin/main` 은 자동으로 갱신되지 않습니다. `fetch` 하기 전까지는 오래된 값입니다.

---

## 1. 원격 등록

```bash
git remote -v                             # 등록된 원격과 URL
git remote add origin <url>
git remote set-url origin <새url>          # URL 변경 (HTTPS ↔ SSH 전환 등)
git remote rename origin upstream
git remote remove <이름>
git remote show origin                    # 원격 브랜치와 추적 관계 상세
```

---

## 2. 받아오기

### `git fetch` — 받되 병합하지 않음

```bash
git fetch                     # 현재 원격의 갱신분을 받아 origin/* 를 최신화
git fetch --all               # 모든 원격
git fetch --prune             # 원격에서 삭제된 브랜치의 추적 정보를 정리
git fetch origin main         # 특정 브랜치만
git fetch --tags              # 태그까지
```

작업 트리를 건드리지 않으므로 **언제 실행해도 안전**합니다. 원격 상태를 확인만 하고 싶을 때의 기본 명령입니다.

```bash
git fetch
git log --oneline HEAD..origin/main       # 내가 아직 안 받은 커밋 확인
git diff HEAD origin/main                 # 내용 차이 확인
```

### `git pull` — fetch + 통합

```bash
git pull                      # fetch 후 merge (기본)
git pull --rebase             # fetch 후 rebase
git pull --ff-only            # fast-forward 로만 진행, 아니면 실패
git pull --prune
```

`pull` 은 기본이 merge 이므로, 내 로컬 커밋이 있으면 병합 커밋이 자동으로 생깁니다. 이력이 지저분해지는 주된 원인이라 아래 설정을 권장합니다.

```bash
git config --global pull.rebase true      # pull 을 항상 rebase 로
# 또는 자동 통합을 막고 명시적으로 처리
git config --global pull.ff only
```

---

## 3. 올리기 (`git push`)

```bash
git push                                  # upstream 이 설정된 경우
git push -u origin <브랜치>                # 첫 푸시 + upstream 연결
git push origin <로컬>:<원격>              # 다른 이름으로 올리기
git push origin --delete <브랜치>          # 원격 브랜치 삭제
git push --tags                           # 태그 전송
git push --force-with-lease               # 안전한 강제 푸시
```

### 강제 푸시

rebase 나 `--amend` 로 커밋 해시가 바뀌면 일반 push 는 거부됩니다. 이때 강제 푸시가 필요합니다.

| 명령 | 동작 | 권장 |
|---|---|---|
| `git push --force` | 원격 상태를 확인하지 않고 덮어씀. 내가 fetch 한 뒤 남이 올린 커밋이 있으면 **말없이 사라짐** | ✗ |
| `git push --force-with-lease` | 원격이 내가 알고 있는 그 위치일 때만 덮어씀. 아니면 거부 | ✓ |
| `git push --force-if-includes` | 위 조건에 더해, 원격의 최신 커밋을 내가 실제로 반영했는지까지 확인 (Git 2.30+) | ✓✓ |

```bash
git config --global alias.pushf 'push --force-with-lease --force-if-includes'
```

**강제 푸시는 혼자 쓰는 브랜치에서만** 합니다. 공유 브랜치에서는 다른 사람의 로컬 이력이 어긋납니다.

---

## 4. upstream (추적 연결)

```bash
git branch -vv                                    # 연결 상태 확인
git push -u origin <브랜치>                        # 푸시하면서 연결
git branch --set-upstream-to=origin/main main     # 나중에 연결
git branch --unset-upstream
```

upstream 이 설정되어 있으면 `git pull` / `git push` 를 인자 없이 쓸 수 있고, `git status` 가 "2 commits ahead, 1 behind" 처럼 대비 상태를 알려줍니다.

```bash
git config --global push.default current
# 현재 브랜치를 같은 이름의 원격 브랜치로 푸시. -u 없이 첫 푸시가 가능해짐
git config --global push.autoSetupRemote true     # Git 2.37+, 첫 푸시 시 upstream 자동 설정
```

---

## 5. 자주 겪는 상황

### 원격이 rebase 되어 로컬과 어긋날 때

GitLab 의 Rebase 버튼을 눌렀거나 다른 사람이 force push 한 경우입니다. 로컬 커밋 중 안 올린 것이 없다면 원격 기준으로 맞추는 것이 가장 단순합니다.

```bash
git fetch origin
git reset --hard origin/<브랜치>
```

올리지 않은 로컬 작업이 있다면 먼저 치워둡니다.

```bash
git stash push -u -m "reset 전 임시 보관"
git fetch origin && git reset --hard origin/<브랜치>
git stash pop
```

### 브랜치가 없어졌는데 목록에 계속 보일 때

```bash
git fetch --prune
git config --global fetch.prune true       # 매번 자동 정리
```

### 로컬 브랜치 일괄 정리

```bash
git branch --merged main | grep -v -E '^\*|main' | xargs -r git branch -d
```

### 원격 URL 을 HTTPS 에서 SSH 로

```bash
git remote set-url origin git@gitlab.example.com:group/project.git
```
