# Windows Docker 레이어 손상(layerchain.json) 복구 기록

## 1. 발생 상황

Windows 서버에서 Windows 컨테이너 모드로 운영 중인 서비스를 `docker compose`로 재배포하던 중 아래 오류가 발생했다.

```
Error response from daemon: failed to unmarshal layerchain JSON: invalid character '\x00' looking for beginning of value
```

이미지 pull, 컨테이너 생성 등 이미지 레이어를 읽는 모든 동작에서 같은 오류가 반복됐다.

## 2. 원인

### 2-1. layerchain.json이란

Docker는 이미지를 여러 개의 레이어로 나눠 저장한다. Windows 컨테이너 모드에서는 각 레이어가 `C:\ProgramData\docker\windowsfilter\<레이어ID>\` 폴더 하나로 저장되고, 그 안의 `layerchain.json` 파일에 "이 레이어의 부모 레이어들이 무엇인지"가 JSON 배열로 기록된다. Docker 데몬은 이미지를 조립할 때 이 파일을 읽어 레이어를 순서대로 쌓는다.

### 2-2. 손상 원인

오류 메시지의 `invalid character '\x00'`은 파일 첫 바이트가 NUL(0x00)이라는 뜻이다. 즉 `layerchain.json`이 정상 JSON 텍스트가 아니라 0으로 채워진 상태였다. NTFS는 파일을 쓸 때 공간을 먼저 할당하고 내용은 나중에 flush하는데, 그 사이에 정전·강제 재부팅·블루스크린·디스크 부족 같은 비정상 종료가 발생하면 파일 크기는 잡혀 있지만 내용은 0으로 남는다. 이미지 pull이나 build 도중 이런 일이 생기면 정확히 이 형태의 손상이 만들어진다.

Linux 컨테이너(WSL2) 모드는 저장 방식이 다르기 때문에 이 오류는 Windows 컨테이너 모드에서만 발생한다.

## 3. Docker 저장소 구조 이해

복구 과정에서 `C:\ProgramData\docker` 아래 폴더들이 서로 어떻게 연결되는지 파악하는 것이 핵심이었다.

**windowsfilter**
이미지와 컨테이너 레이어의 실제 파일이 들어 있는 곳. `docker images`에 보이는 이미지의 실체다. Windows 베이스 이미지는 OS 파일 트리를 통째로 담고 있어 레이어 하나가 수 GB에 이르고, 내부 경로도 매우 길다.

**image**
이미지 메타데이터 저장소. 어떤 이미지가 어떤 레이어 ID들로 구성되는지를 기록한다. `windowsfilter`의 레이어 ID를 참조하므로 두 폴더는 항상 세트로 취급해야 한다. 하나만 초기화하면 "레이어가 없다" 또는 "이미지가 없다"는 새 오류가 생긴다.

**containers**
컨테이너별 설정(config.v2.json), 로그, 마운트 정보가 들어 있다. 각 컨테이너는 자기가 어떤 이미지·레이어 위에서 도는지를 참조한다. 이미지 저장소를 초기화했는데 이 폴더를 남기면 존재하지 않는 레이어를 가리키는 유령 컨테이너가 생긴다.

**volumes**
named volume의 실제 데이터. 이미지·컨테이너와 독립적이므로 위 세 폴더를 초기화해도 영향을 받지 않는다. 절대 건드리지 않아야 할 폴더다.

## 4. 해결 과정

### 4-1. 접근 방식 선택

손상된 레이어 폴더만 찾아 삭제하는 방법과 이미지 저장소 전체를 초기화하는 방법이 있다. 손상 레이어는 다음 명령으로 찾을 수 있다.

```powershell
Get-ChildItem "C:\ProgramData\docker\windowsfilter" -Recurse -Filter layerchain.json |
  Where-Object { (Get-Content $_.FullName -Raw) -match "\x00" -or $_.Length -eq 0 }
```

이번에는 배포 서버 특성상 이미지는 레지스트리에서 다시 받을 수 있고 데이터는 볼륨에 있었으므로, 손상 범위를 일일이 확인하는 대신 전체 초기화를 택했다.

### 4-2. 삭제 시도와 실패

```powershell
Stop-Service docker
Remove-Item "C:\ProgramData\docker\windowsfilter" -Recurse -Force
```

실행하자 `경로의 일부를 찾을 수 없습니다` 오류가 수백 건 쏟아지며 중단됐다. 원인은 두 가지다.

- **경로 길이 제한**: Windows API의 MAX_PATH(260자) 제한. 레이어 안의 `Files\Windows\System32\CatRoot\{GUID}\Product-onecore__...cat` 같은 경로가 이를 초과한다. PowerShell의 `Remove-Item`은 이 제한을 우회하지 못한다.
- **파일 권한**: 레이어 안의 OS 파일들은 TrustedInstaller 소유라 관리자 권한으로도 바로 지워지지 않는다.

삭제가 중간에 멈추면서 `windowsfilter`가 반쯤 지워진 상태가 됐다. 이 상태로 Docker를 켜면 또 다른 오류가 나므로 끝까지 정리해야 했다.

### 4-3. 이름 변경으로 초기화

삭제 대신 폴더 이름을 바꾸는 방식으로 전환했다.

```powershell
Stop-Service docker
Rename-Item "C:\ProgramData\docker\windowsfilter" "_windowsfilter"
Rename-Item "C:\ProgramData\docker\image" "_image"
Start-Service docker
```

Docker 데몬은 시작할 때 필요한 폴더가 없으면 새로 만들기 때문에, 이름만 바꿔도 깨끗한 저장소로 시작하는 효과가 난다. 경로 길이나 권한 문제를 피할 수 있고, 문제가 생기면 이름을 되돌려 원복할 여지도 남는다.

### 4-4. 컨테이너 메타데이터 잔존 문제

Docker 재시작 후 `docker compose up`을 실행하자 새 오류가 나타났다.

```
✘ Container 545954503c85   Error while Stopping
Error response from daemon: No such container: 545954503c85bdd2...
```

컨테이너 이름이 사람이 붙인 이름이 아니라 ID로 표시되는 것 자체가 메타데이터가 깨졌다는 신호였다. `containers` 폴더의 옛 컨테이너 정보가 이미 사라진 레이어를 참조하고 있어, compose가 기존 컨테이너를 정리하려다 실패한 것이다. 같은 방식으로 처리했다.

```powershell
Stop-Service docker
Rename-Item "C:\ProgramData\docker\containers" "_containers"
Start-Service docker
docker ps -a    # 비어 있음 확인
```

이후 `docker compose up`이 정상적으로 이미지를 받고 컨테이너를 생성했다. 볼륨은 그대로 유지되어 서비스 데이터 손실은 없었다.

## 5. 정리

**이미지·컨테이너 폴더는 세트다.** `windowsfilter`, `image`, `containers`는 서로 ID로 참조하는 관계라 하나만 초기화하면 연쇄적으로 다른 오류가 난다. 초기화할 때는 세 폴더를 함께 처리하고 `volumes`만 남긴다.

**데이터는 볼륨에 둔다.** 이번 복구가 데이터 손실 없이 끝난 이유는 서비스 데이터가 named volume에 있었기 때문이다. 컨테이너 내부에 직접 쓴 파일은 이런 초기화에서 함께 사라진다.

**Windows 레이어는 일반 명령으로 삭제되지 않는다.** 경로 길이와 권한 문제 때문에 `Remove-Item`은 실패한다. 삭제가 필요하면 `cmd /c rd /s /q "\\?\경로"`(경로 길이 우회) 또는 Microsoft가 이 용도로 만든 `docker-ci-zap` 도구를 쓰고, 급할 때는 이름 변경이 가장 빠르고 안전하다.

**이미지는 재생성 가능한 자원으로 관리한다.** 레지스트리나 Dockerfile로 언제든 다시 만들 수 있게 해두면, 저장소가 손상돼도 초기화 한 번으로 복구할 수 있다.
