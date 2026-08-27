# 08. 설정과 협업 흐름

---

## 1. `git config`

### 적용 범위

| 범위 | 옵션 | 파일 위치 | 우선순위 |
|---|---|---|---|
| 시스템 | `--system` | Git 설치 경로 | 낮음 |
| 사용자 | `--global` | 사용자 홈의 `.gitconfig` | 중간 |
| 저장소 | `--local` (기본) | 저장소의 `.git/config` | 높음 |

```bash
git config --list --show-origin           # 어떤 값이 어디서 왔는지
git config user.email                     # 현재 적용값 조회
git config --global --edit                # 편집기로 직접 수정
```

### 기본 설정

```bash
git config --global user.name "이름"
git config --global user.email "메일주소"
git config --global init.defaultBranch main
git config --global core.editor "code --wait"
```

회사 저장소와 개인 저장소의 계정이 다르면 저장소별로 지정합니다.

```bash
git config --local user.email "업무용 메일주소"
```

### 줄바꿈 처리

| 환경 | 설정 | 동작 |
|---|---|---|
| Windows | `git config --global core.autocrlf true` | 체크아웃 시 CRLF, 커밋 시 LF |
| macOS / Linux | `git config --global core.autocrlf input` | 커밋 시에만 LF 로 변환 |

팀 단위로는 저장소에 `.gitattributes` 를 두는 편이 확실합니다.

```gitattributes
* text=auto
*.sh text eol=lf
*.bat text eol=crlf
*.png binary
```

### 권장 설정

```bash
git config --global pull.rebase true          # pull 을 rebase 로. 불필요한 병합 커밋 방지
git config --global fetch.prune true          # 삭제된 원격 브랜치 자동 정리
git config --global rebase.autosquash true    # fixup 커밋 자동 배치
git config --global rebase.autostash true     # rebase 전 자동 stash
git config --global rerere.enabled true       # 같은 충돌의 해결 내용 재사용
git config --global push.autoSetupRemote true # 첫 push 에서 upstream 자동 설정
git config --global diff.colorMoved zebra     # 이동한 코드를 다른 색으로 표시
```

### 별칭

```bash
git config --global alias.st "status -sb"
git config --global alias.lg "log --oneline --graph --all --decorate"
git config --global alias.last "log -1 --stat"
git config --global alias.unstage "restore --staged"
git config --global alias.pushf "push --force-with-lease --force-if-includes"
```

---

## 2. 인증

### SSH

```bash
ssh-keygen -t ed25519 -C "메일주소"
# 생성된 공개키를 GitLab/GitHub 계정의 SSH Keys 에 등록
ssh -T git@gitlab.example.com             # 연결 확인
```

### 자격 증명 저장

```bash
git config --global credential.helper manager   # Windows (Git Credential Manager)
git config --global credential.helper osxkeychain
git config --global credential.helper "cache --timeout=3600"
```

토큰을 `git config` 나 원격 URL 에 직접 넣지 않습니다. URL 에 넣으면 `.git/config` 에 평문으로 남습니다.

---

## 3. 브랜치 전략

### GitHub Flow (단순, 지속 배포에 적합)

```
main ──────●────────●────────●──   항상 배포 가능한 상태
            \      /  \      /
             기능A       기능B
```

- `main` 하나와 짧게 사는 기능 브랜치만 사용
- 머지 요청으로 검토 후 `main` 에 병합하고 즉시 배포
- 브랜치는 병합 직후 삭제

### Git Flow (릴리스 주기가 있는 제품)

| 브랜치 | 역할 | 수명 |
|---|---|---|
| `main` | 배포된 버전 | 영구 |
| `develop` | 다음 릴리스 통합 | 영구 |
| `feature/*` | 기능 개발 | 병합까지 |
| `release/*` | 릴리스 준비와 안정화 | 릴리스까지 |
| `hotfix/*` | 운영 긴급 수정 | 수정까지 |

단계가 많아 관리 비용이 크므로, 버전을 명시적으로 관리해야 하는 제품이 아니면 GitHub Flow 쪽이 무난합니다.

### 브랜치 이름

```
feature/로그인-소셜연동
fix/재고수량-음수처리
hotfix/결제-타임아웃
chore/의존성-갱신
```

---

## 4. 머지 요청 흐름

### 작업 시작부터 병합까지

```bash
# 1. 최신 기준에서 브랜치 생성
git switch main
git pull
git switch -c feature/재고조회-개선

# 2. 작업하고 커밋 (의미 단위로 나눠서)
git add -p
git commit -m "feat: 재고 조회에 창고 필터 추가"

# 3. 올리기
git push -u origin feature/재고조회-개선

# 4. 검토 의견 반영
git add <file>
git commit -m "fix: 검토 의견 반영 - 빈 값 처리"
git push

# 5. 병합 직전, 최신 main 위로 정리
git fetch origin
git rebase -i origin/main        # 잡다한 커밋 정리
git push --force-with-lease

# 6. 병합 후 정리
git switch main
git pull --prune
git branch -d feature/재고조회-개선
```

### 병합 방식 선택

| 방식 | 결과 | 적합한 경우 |
|---|---|---|
| Merge commit | 병합 커밋이 남고 분기 구조 보존 | 기능 단위 이력을 남기고 싶을 때 |
| Squash | 커밋 하나로 압축 | 작업 커밋이 잡다할 때 |
| Fast-forward | 일직선, 병합 커밋 없음 | 이력을 단순하게 유지하는 정책 |

Fast-forward 정책에서는 소스 브랜치가 뒤처지면 병합이 막히므로 rebase 가 필요합니다. [04. Rebase](./04-rebase.md) 참고.

### 검토받기 좋은 머지 요청

- 하나의 목적만 담습니다. 리팩터링과 기능 추가를 섞지 않습니다.
- 커밋을 의미 단위로 나눕니다. 검토자가 커밋별로 따라 읽을 수 있어야 합니다.
- 무엇을 왜 바꿨는지 설명을 답니다. 어떻게 바꿨는지는 코드가 말합니다.
- 올리기 전에 스스로 확인합니다.

  ```bash
  git diff origin/main...HEAD               # 검토자가 보게 될 전체 변경
  git log --oneline origin/main..HEAD       # 담길 커밋 목록
  git diff --check                          # 공백 오류와 충돌 마커 잔재
  ```

---

## 5. 훅 (`hooks`)

`.git/hooks/` 의 스크립트가 특정 시점에 실행됩니다. `.git` 은 공유되지 않으므로 팀 단위로 쓰려면 별도 도구나 설정이 필요합니다.

| 훅 | 시점 | 용도 |
|---|---|---|
| `pre-commit` | 커밋 직전 | 린트, 포맷 검사 |
| `commit-msg` | 메시지 작성 후 | 메시지 규칙 검사 |
| `pre-push` | 푸시 직전 | 테스트 실행 |

저장소에 포함해 공유하려면 훅 디렉토리를 옮깁니다.

```bash
git config --local core.hooksPath .githooks
```

훅을 건너뛰려면 `--no-verify` 를 쓸 수 있지만, 검사가 막는 이유를 확인하지 않고 우회하는 것이므로 권장하지 않습니다.

---

## 6. 팀에서 지키면 좋은 것

- **공유 브랜치는 rebase 하지 않습니다.** 강제 푸시는 혼자 쓰는 브랜치에서만 합니다.
- **`--force` 대신 `--force-with-lease`** 를 씁니다.
- **자격 증명과 비밀 값은 커밋하지 않습니다.** `.gitignore` 에 넣고, 예시 파일(`.env.example`)만 공유합니다. 실수로 올렸다면 이력에서 지우는 것과 별개로 반드시 폐기하고 재발급합니다.
- **큰 바이너리는 넣지 않습니다.** 필요하면 Git LFS 나 별도 저장소를 사용합니다.
- **병합된 브랜치는 삭제합니다.** 목록이 길어지면 무엇이 살아 있는지 알 수 없습니다.
