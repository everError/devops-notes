# 06. 조회와 추적

---

## 1. `git log`

### 자주 쓰는 형태

```bash
git log --oneline --graph --all --decorate    # 브랜치 구조를 한눈에
git log --oneline -10                          # 최근 10개
git log -p <file>                              # 파일의 변경 내역을 diff 와 함께
git log --stat                                 # 커밋별 변경 파일과 증감 줄 수
git log --follow <file>                        # 이름이 바뀐 이력까지 추적
```

### 범위 지정

| 표기 | 의미 |
|---|---|
| `A..B` | B 에는 있고 A 에는 없는 커밋 |
| `A...B` | 양쪽 중 한쪽에만 있는 커밋 (공통 조상 이후 갈라진 부분 전체) |
| `origin/main..HEAD` | 내가 아직 올리지 않은 커밋 |
| `HEAD..origin/main` | 내가 아직 받지 않은 커밋 |
| `-- <경로>` | 해당 경로를 건드린 커밋만 |

```bash
git log --oneline origin/main..HEAD            # 이번 머지 요청에 담길 커밋
git log --oneline main..feature -- src/api/    # 특정 폴더 변경분만
```

### 필터

```bash
git log --author="이름"
git log --since="2 weeks ago" --until="yesterday"
git log --grep="로그인"                         # 커밋 메시지 검색
git log -S"functionName"                       # 그 문자열의 등장 횟수가 바뀐 커밋 (추가/삭제 시점)
git log -G"regex"                              # diff 내용이 정규식과 일치하는 커밋
git log --merges
git log --no-merges
```

`-S` 는 **코드가 언제 들어왔고 언제 사라졌는지** 를 찾는 가장 빠른 방법입니다.

### 출력 형식

```bash
git log --format="%h %ad %an %s" --date=short
```

| 지정자 | 의미 |
|---|---|
| `%h` / `%H` | 짧은 / 전체 해시 |
| `%s` | 제목 줄 |
| `%an` / `%ae` | 작성자 이름 / 메일 |
| `%ad` / `%ar` | 작성 일시 / 상대 시간 |
| `%d` | 브랜치·태그 표시 |

자주 쓰는 형태는 별칭으로 등록해 둡니다. 등록 방법은 [08. 설정과 협업 흐름](./08-config-and-workflow.md) 참고.

---

## 2. `git diff`

```bash
git diff                      # 작업 트리 vs 인덱스 (아직 스테이징 안 한 변경)
git diff --staged             # 인덱스 vs HEAD (스테이징한 변경). --cached 와 동일
git diff HEAD                 # 작업 트리 vs HEAD (둘 다 합친 전체 변경)
git diff <커밋A> <커밋B>
git diff main...feature       # 공통 조상 기준. 머지 요청에서 보게 될 변경분
git diff <브랜치> -- <경로>
```

| 옵션 | 동작 |
|---|---|
| `--stat` | 파일별 증감 요약만 |
| `--name-only` | 변경된 파일 이름만 |
| `--name-status` | 이름과 변경 종류(A/M/D) |
| `-w` | 공백 변경 무시 |
| `--word-diff` | 줄 단위가 아닌 단어 단위 비교. 문서 검토에 유용 |
| `--check` | 공백 오류와 충돌 마커 잔재 검사 |

`A..B` 와 `A...B` 의 의미가 `log` 와 다르므로 주의합니다.

- `git diff A B` : 두 커밋의 **최종 상태 차이**
- `git diff A...B` : **공통 조상부터 B 까지의 변경**. 머지 요청 화면이 보여주는 것과 같음

---

## 3. `git show`

```bash
git show <sha>                            # 커밋 메시지와 diff
git show <sha> --stat
git show <sha>:<경로>                      # 그 커밋 시점의 파일 내용 출력
git show HEAD~2:src/app.ts > old-app.ts   # 과거 버전을 파일로 추출
git show <태그>
```

---

## 4. `git blame` (줄 단위 추적)

```bash
git blame <file>
git blame -L 40,60 <file>                 # 40~60줄만
git blame -w <file>                       # 공백 변경 무시
git blame -C <file>                       # 다른 파일에서 옮겨온 줄까지 원본 추적
git blame <sha> -- <file>                 # 특정 시점 기준
```

`-w -C -C -C` 처럼 겹쳐 주면 이동되거나 복사된 코드의 원래 출처까지 따라갑니다.

대규모 포맷팅 커밋 때문에 blame 결과가 무의미해진 경우, 그 커밋 해시를 `.git-blame-ignore-revs` 에 적고 아래 설정을 하면 건너뜁니다.

```bash
git config --global blame.ignoreRevsFile .git-blame-ignore-revs
```

---

## 5. `git bisect` (고장난 커밋 찾기)

정상이던 시점과 고장난 시점을 알려주면 이진 탐색으로 원인 커밋을 찾아줍니다. 커밋 1000개도 10회 정도면 좁혀집니다.

```bash
git bisect start
git bisect bad                # 현재 상태가 고장남
git bisect good <sha>         # 정상이던 커밋 지정

# Git 이 중간 커밋을 체크아웃하면 확인 후 판정
git bisect good
git bisect bad

# 반복하면 "<sha> is the first bad commit" 이 출력됨
git bisect reset              # 원래 브랜치로 복귀
```

### 자동화

판정을 스크립트로 대신할 수 있습니다. 종료 코드 0이면 정상, 1~127(125 제외)이면 고장으로 판정합니다.

```bash
git bisect start HEAD <정상sha>
git bisect run npm test
```

---

## 6. 그 밖의 조회 명령

```bash
git shortlog -sn                          # 작성자별 커밋 수
git shortlog -sn --since="3 months ago"

git grep "패턴"                            # 작업 트리에서 검색 (무시 대상 제외)
git grep -n "패턴" <sha>                   # 특정 커밋 시점에서 검색

git describe --tags                       # 최근 태그 기준의 현재 위치
git describe --tags --always --dirty      # 예: v1.2.0-3-ga1b2c3d

git rev-parse HEAD                        # 현재 커밋의 전체 해시
git rev-parse --abbrev-ref HEAD           # 현재 브랜치 이름. 스크립트에서 자주 사용
git rev-list --count HEAD                 # 커밋 개수. 빌드 번호로 활용

git branch --contains <sha>               # 이 커밋을 포함한 브랜치
git tag --contains <sha>                  # 이 커밋이 처음 포함된 태그. 릴리스 확인에 사용
```
