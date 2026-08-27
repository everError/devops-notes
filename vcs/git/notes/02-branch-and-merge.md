# 02. 브랜치와 병합

---

## 🎯 브랜치란

브랜치는 **커밋 하나를 가리키는 이름표**입니다. 파일을 복사하는 것이 아니라 포인터를 하나 만드는 것이므로 생성 비용이 사실상 없습니다. 커밋할 때마다 현재 브랜치의 포인터가 새 커밋으로 따라 이동합니다.

---

## 1. 브랜치 다루기

### 조회

```bash
git branch                    # 로컬 브랜치 목록
git branch -a                 # 원격 추적 브랜치까지
git branch -v                 # 마지막 커밋 요약과 함께
git branch -vv                # upstream 연결 상태까지
git branch --merged           # 현재 브랜치에 이미 병합된 브랜치 (삭제 후보)
git branch --no-merged        # 아직 병합되지 않은 브랜치
```

### 생성·전환·삭제

```bash
git switch <브랜치>            # 전환
git switch -c <새브랜치>       # 생성 후 전환
git switch -c <새브랜치> origin/main   # 특정 기준점에서 생성
git switch -                  # 직전 브랜치로 되돌아가기
git switch --detach <sha>     # 특정 커밋을 분리된 HEAD 로 확인

git branch -m <새이름>         # 현재 브랜치 이름 변경
git branch -d <브랜치>         # 병합된 브랜치 삭제 (안전)
git branch -D <브랜치>         # 병합 여부 무시하고 삭제 (강제)
```

`switch` / `restore` 는 `checkout` 의 역할을 목적별로 나눈 명령어(Git 2.23+)입니다. `checkout` 은 브랜치 전환과 파일 복원을 모두 담당해 혼동이 잦았으므로, 새로 익힐 때는 아래처럼 나눠 쓰는 편이 명확합니다.

| 목적 | 옛 방식 | 권장 |
|---|---|---|
| 브랜치 전환 | `git checkout <브랜치>` | `git switch <브랜치>` |
| 브랜치 생성 후 전환 | `git checkout -b <브랜치>` | `git switch -c <브랜치>` |
| 파일 되돌리기 | `git checkout -- <file>` | `git restore <file>` |

---

## 2. 병합 (`git merge`)

### fast-forward 와 병합 커밋

분기 이후 대상 브랜치에 새 커밋이 없으면, Git 은 포인터만 앞으로 옮깁니다. 이것이 **fast-forward** 입니다.

```
fast-forward 가능              fast-forward 불가 → 병합 커밋 생성
main ──A──B                    main ──A──B──E──────M
            \                              \      /
     feature ──C──D             feature     ──C──D
     → main 을 D 로 이동만
```

```bash
git merge <브랜치>             # 가능하면 fast-forward, 아니면 병합 커밋
git merge --no-ff <브랜치>     # 항상 병합 커밋 생성 (기능 단위 이력 보존)
git merge --ff-only <브랜치>   # fast-forward 가 아니면 실패시킴
git merge --squash <브랜치>    # 변경 내용만 인덱스에 모으고 커밋은 직접 (이력 한 줄로 압축)
git merge --abort              # 충돌 중인 병합을 취소하고 병합 전 상태로
```

| 옵션 | 언제 쓰는가 | 결과 이력 |
|---|---|---|
| 기본 | 특별한 정책이 없을 때 | 상황에 따라 다름 |
| `--no-ff` | "이 기능이 언제 들어왔는지" 를 이력에 남기고 싶을 때 | 병합 커밋이 항상 남음 |
| `--ff-only` | 일직선 이력을 강제하는 정책일 때 | 병합 커밋 없음, 뒤처져 있으면 실패 |
| `--squash` | 지저분한 작업 커밋을 하나로 눌러 넣을 때 | 커밋 1개, 원본 브랜치와의 연결은 끊김 |

`--squash` 는 병합으로 기록되지 않으므로, 이후 같은 브랜치를 다시 병합하면 Git 이 중복 변경으로 인식해 충돌이 날 수 있습니다. 압축 병합한 브랜치는 병합 직후 삭제하는 것이 안전합니다.

---

## 3. 충돌 해결

### 절차

```bash
git merge feature
# CONFLICT (content): Merge conflict in src/app.ts

git status                    # 충돌 파일 목록 확인 (both modified)
# 1) 파일을 열어 마커를 없애고 원하는 최종 형태로 편집
# 2)
git add src/app.ts            # 해결했음을 표시
git commit                    # 병합 커밋 완성 (메시지는 자동 생성됨)
```

### 충돌 마커 읽는 법

```
<<<<<<< HEAD
현재 브랜치(내가 서 있는 쪽)의 내용
=======
가져오는 브랜치의 내용
>>>>>>> feature
```

### 한쪽을 통째로 선택

```bash
git checkout --ours <file>    # 현재 브랜치 쪽 내용 채택
git checkout --theirs <file>  # 가져오는 브랜치 쪽 내용 채택
git add <file>
```

> **주의**: `rebase` 중에는 ours/theirs 의 의미가 뒤바뀝니다. rebase 는 대상 브랜치 위에 내 커밋을 다시 얹는 방식이므로, **ours = 올라탈 기준 브랜치**, **theirs = 재적용 중인 내 커밋** 입니다. [04. Rebase](./04-rebase.md) 참고.

### 도구와 재사용

```bash
git mergetool                 # 설정된 3-way 병합 도구 실행
git config --global rerere.enabled true
```

`rerere`(reuse recorded resolution)를 켜두면 같은 충돌을 다시 만났을 때 이전 해결 내용을 자동 적용합니다. 긴 브랜치를 여러 번 rebase 할 때 특히 효과가 큽니다.

---

## 4. merge 와 rebase 선택 기준

| 기준 | merge | rebase |
|---|---|---|
| 이력 모양 | 분기와 합류가 그대로 남음 | 일직선 |
| 커밋 해시 | 유지됨 | 새로 만들어짐 |
| 공유된 브랜치 | 안전 | 사용 금지 |
| 충돌 해결 | 한 번에 | 커밋 단위로 반복될 수 있음 |
| 원격 반영 | 일반 push | force push 필요 |

**실무 조합**: 내 기능 브랜치를 최신 main 위로 정리할 때는 rebase, 기능 브랜치를 main 에 넣을 때는 merge(또는 프로젝트 정책에 따라 fast-forward). 자세한 내용은 [04. Rebase](./04-rebase.md).
