# 07. 심화 도구

---

## 1. `git stash` (작업을 잠시 치워두기)

커밋하기는 이르지만 브랜치를 옮겨야 할 때 사용합니다.

```bash
git stash push -m "메모"                   # 현재 변경을 저장하고 작업 트리를 정리
git stash push -u -m "메모"                # 추적되지 않는 새 파일까지 포함
git stash push -- src/app.ts               # 특정 경로만
git stash push -p                          # 덩어리 단위로 선택

git stash list                             # 목록
git stash show -p stash@{0}                # 내용 확인
git stash pop                              # 최근 항목을 적용하고 목록에서 제거
git stash apply stash@{1}                  # 적용하되 목록에 남김
git stash drop stash@{0}
git stash clear                            # 전부 삭제. 복구가 어려움
git stash branch <새브랜치>                 # stash 시점 기준으로 브랜치를 만들어 적용
```

| 옵션 | 동작 |
|---|---|
| `-u` | 새로 만든 파일도 함께 저장. 지정하지 않으면 남겨져서 브랜치 전환 시 섞임 |
| `-a` | 무시된 파일까지 전부 |
| `-k` | 스테이징한 내용은 작업 트리에 남겨둠 |
| `-p` | 선택적으로 저장 |

`pop` 은 충돌이 나면 항목을 지우지 않고 남깁니다. 반대로 성공하면 즉시 사라지므로, 잘못 적용할 여지가 있으면 `apply` 로 확인한 뒤 `drop` 하는 편이 안전합니다.

---

## 2. `git cherry-pick` (커밋 골라 가져오기)

다른 브랜치의 커밋을 내용만 복사해서 현재 브랜치에 새 커밋으로 얹습니다.

```bash
git cherry-pick <sha>
git cherry-pick <sha1> <sha2>
git cherry-pick <sha1>^..<sha2>            # 범위. sha1 포함
git cherry-pick -x <sha>                   # 원본 커밋 해시를 메시지에 기록
git cherry-pick -n <sha>                   # 커밋하지 않고 인덱스에만 반영
git cherry-pick -e <sha>                   # 메시지 편집
git cherry-pick --continue
git cherry-pick --skip
git cherry-pick --abort
```

주 용도는 **핫픽스 이식** 입니다. main 에서 고친 버그를 릴리스 브랜치에도 넣을 때 `-x` 를 붙이면 출처가 남아 추적이 쉽습니다.

같은 변경이 두 브랜치에 각각 다른 해시로 존재하게 되므로, 나중에 두 브랜치를 병합하면 충돌할 수 있습니다. 이미 이식된 커밋은 아래로 확인합니다.

```bash
git cherry -v main release/1.0             # + 표시는 아직 반영되지 않은 커밋
```

---

## 3. `git tag` (릴리스 표시)

```bash
git tag                                    # 목록
git tag -l "v1.*"
git tag -a v1.2.0 -m "릴리스 1.2.0"        # 주석 태그. 작성자와 일시, 메시지가 보존됨
git tag v1.2.0                             # 경량 태그. 단순 포인터
git tag -a v1.2.0 <sha>                    # 과거 커밋에 태그
git tag -d v1.2.0                          # 로컬 삭제

git push origin v1.2.0                     # 태그는 자동으로 전송되지 않음
git push origin --tags                     # 전부 전송
git push origin --delete v1.2.0            # 원격 태그 삭제

git show v1.2.0
git checkout v1.2.0                        # 분리된 HEAD 로 해당 시점 확인
```

배포 산출물의 버전 문자열은 태그에서 생성하는 것이 일반적입니다.

```bash
git describe --tags --always --dirty       # 예: v1.2.0-3-ga1b2c3d
```

---

## 4. `git worktree` (한 저장소를 여러 디렉토리에서)

같은 저장소를 여러 브랜치로 동시에 열어둘 수 있습니다. 긴 빌드를 돌리는 중에 급한 수정을 하거나 두 브랜치를 나란히 비교할 때 stash 없이 처리됩니다.

```bash
git worktree list
git worktree add ../hotfix hotfix/urgent                      # 기존 브랜치를 새 디렉토리에
git worktree add -b review/mr-42 ../review origin/feature-x   # 새 브랜치와 함께
git worktree remove ../hotfix
git worktree prune                                            # 사라진 등록 정보 정리
```

`.git` 디렉토리를 공유하므로 클론을 하나 더 받는 것보다 훨씬 가볍습니다. 같은 브랜치를 두 곳에서 동시에 체크아웃하는 것은 막혀 있습니다.

---

## 5. `git submodule` (저장소 안의 저장소)

다른 저장소를 특정 커밋에 고정해서 포함합니다.

```bash
git submodule add <url> libs/shared
git submodule status

git clone --recurse-submodules <url>               # 클론과 동시에 내려받기
git submodule update --init --recursive            # 이미 클론한 경우

git submodule update --remote                      # 각 서브모듈을 원격 최신으로
```

서브모듈은 커밋 해시를 가리키므로, 서브모듈 안에서 커밋한 뒤 부모 저장소에서도 그 포인터 변경을 커밋해야 합니다. 관리 부담이 크므로 패키지 매니저로 해결할 수 있으면 그 편이 낫습니다.

```bash
git config --global submodule.recurse true         # pull/checkout 시 자동 동기화
```

---

## 6. 대용량 저장소 다루기

### `git sparse-checkout`

거대한 저장소에서 필요한 경로만 작업 트리에 두는 기능입니다.

```bash
git sparse-checkout init --cone
git sparse-checkout set apps/web libs/shared
git sparse-checkout list
git sparse-checkout disable
```

### 얕은 클론의 이력 회수

```bash
git fetch --unshallow                              # --depth 로 받은 저장소의 전체 이력 회수
```

---

## 7. 이력 전체 다시 쓰기

```bash
git filter-repo --path secrets.env --invert-paths  # 특정 파일을 이력 전체에서 제거
```

`filter-repo` 는 별도 설치가 필요한 도구이며 구식 `filter-branch` 를 대체합니다. 실행하면 **모든 커밋 해시가 바뀝니다.** 유출된 자격 증명 제거처럼 다른 수단이 없을 때만 사용하고, 실행 전에 팀 합의와 재클론 안내가 필요합니다.

무엇보다 **노출된 자격 증명은 이력에서 지우는 것과 별개로 반드시 폐기하고 재발급해야 합니다.** 이미 클론한 사람이나 캐시에 남아 있을 수 있기 때문입니다.
