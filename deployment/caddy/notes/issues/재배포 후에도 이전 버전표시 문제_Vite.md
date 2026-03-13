## 이슈: 사이트 재배포 후에도 이전 버전이 표시됨 (Vite + Caddy 캐시 설정)

**환경:** Vite(프론트엔드 빌드) + Caddy(웹서버)

---

### 원인

브라우저(및 WebView)는 서버에서 받은 리소스를 로컬 디스크에 캐시한다. 서버에서 사이트를 재배포하더라도, 클라이언트가 캐시된 이전 파일을 그대로 사용하면 변경 사항이 반영되지 않는다.

---

### 해결 전략

Vite는 빌드 시 JS/CSS 파일명에 콘텐츠 해시를 자동으로 붙인다. 예를 들어 `app-3a8f2c.js`, `style-b4d1e7.css`처럼 파일 내용이 바뀌면 해시도 달라져서 파일명 자체가 변경된다. 이 특성을 이용해 `index.html`과 정적 파일의 캐시 정책을 분리한다.

**`index.html` → `Cache-Control: no-cache`**

`no-cache`는 캐시를 아예 사용하지 않는다는 뜻이 아니다. 클라이언트가 캐시를 저장하되, 매 요청마다 서버에 "내가 가진 버전이 아직 유효한가?"를 확인(ETag 기반 검증)하라는 의미다. 서버가 변경이 없다고 판단하면 본문 없이 `304 Not Modified`만 응답하므로 속도 저하가 거의 없고, 변경됐으면 새 HTML을 내려준다.

**`assets/*` → `Cache-Control: public, max-age=31536000, immutable`**

Vite 빌드 결과물은 파일명에 해시가 포함되어 있어서, 내용이 바뀌면 아예 다른 URL이 된다. 따라서 1년(31536000초)짜리 장기 캐시를 걸어도 안전하다. `immutable`은 이 리소스가 절대 변경되지 않으니 유효성 재검증도 하지 말라는 의미다.

---

### 재배포 시 동작 흐름

1. 클라이언트가 `index.html`을 요청한다
2. `no-cache` 정책에 따라 서버에 변경 여부를 확인한다
3. 재배포로 HTML이 바뀌었으면 새 `index.html`을 받는다 (200 OK)
4. 새 HTML 안에 `app-ccc333.js` 같은 새 해시 파일명이 적혀있다
5. 해당 파일은 캐시에 없으므로 서버에서 새로 받는다
6. 재배포하지 않았으면 3단계에서 `304 Not Modified`를 받고 기존 캐시를 그대로 사용한다

핵심은 `index.html`만 신선도를 검증하면, 나머지는 해시 변경에 의해 자동으로 갱신된다는 점이다.

---

### Caddy 설정 적용

```caddy
handle /app* {
    root * /var/www/html
    try_files {path} {path}/ /app/index.html

    # index.html 및 SPA 진입점 - 매번 서버에 변경 여부 확인
    @html path */index.html /app/ /app
    header @html Cache-Control "no-cache"

    # Vite 빌드 결과물 (해시 포함) - 장기 캐시
    @assets path /app/assets/*
    header @assets Cache-Control "public, max-age=31536000, immutable"

    file_server
}
```

SPA 경로가 여러 개인 경우, 각 `handle` 블록마다 matcher 이름을 다르게 지정해야 한다. Caddy는 같은 스코프 내에서 matcher 이름 중복을 허용하지 않기 때문이다.

```caddy
handle /admin* {
    root * /var/www/html
    try_files {path} {path}/ /admin/index.html

    # matcher 이름을 @html2, @assets2로 변경
    @html2 path */index.html /admin/ /admin
    header @html2 Cache-Control "no-cache"

    @assets2 path /admin/assets/*
    header @assets2 Cache-Control "public, max-age=31536000, immutable"

    file_server
}
```

---

### 참고: 이전 캐시 정리

더 이상 참조되지 않는 이전 해시 파일(`app-aaa111.js` 등)은 클라이언트 캐시에 남아있지만, 브라우저가 자체적으로 용량 상한을 관리하며 LRU(가장 오래 사용하지 않은 것부터) 방식으로 자동 정리한다. Vite 빌드 결과물 크기를 감안하면 별도 정리 없이도 실무에서 문제가 될 수준은 아니다.
