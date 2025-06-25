## 🌐 Gzip 웹서버 압축 정리

### ✅ Gzip이란?

- Gzip은 텍스트 기반 리소스(JS, CSS, HTML 등)를 **압축하여 전송량을 줄이는 방식**
- HTTP/1.1부터 `Content-Encoding: gzip` 헤더로 지원
- 브라우저가 `Accept-Encoding: gzip`을 보낼 경우 서버는 압축된 콘텐츠 응답 가능

---

### ✅ Gzip 압축의 장점

| 항목                  | 설명                                          |
| --------------------- | --------------------------------------------- |
| 📦 전송량 감소        | 파일 크기를 70\~90% 줄일 수 있음              |
| 🚀 로딩 속도 향상     | 네트워크 전송 시간 단축 → 사용자 경험 향상    |
| 🔧 설정 간단          | 대부분의 웹서버에서 설정만으로 쉽게 사용 가능 |
| 🧠 브라우저 자동 해제 | 별도 코드 없이 브라우저가 압축 해제 처리      |

---

### ✅ CSS/JS 전송 성능 향상 효과

- JS, CSS는 일반적으로 텍스트 기반이라 **압축 효율이 매우 높음** (최대 90% 이상 감소)
- 예: `app.js`가 1.5MB인 경우, Gzip 적용 시 250\~300KB 수준으로 감소
- **압축 전송 + 브라우저 해제**는 보통 수십 ms 단위로 이뤄져, 실제 사용자는 더 빠른 로딩을 체감함
- 특히 모바일이나 느린 네트워크 환경에서는 효과가 큼
- [Google Web Fundamentals](https://developers.google.com/web/fundamentals/performance/optimizing-content-efficiency/http-compression)에서도 권장

---

### ⚙️ 웹서버별 Gzip 설정

#### 📁 Nginx

```nginx
gzip on;
gzip_types text/plain text/css application/javascript application/json application/xml;
gzip_min_length 1024;
gzip_comp_level 5;
gzip_static on; # .gz 파일이 있으면 직접 서빙
```

#### 🖥 Apache

```apache
# mod_deflate 모듈 필요
<IfModule mod_deflate.c>
  AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css application/javascript application/json
</IfModule>
```

#### 🟦 Express.js (Node.js)

```ts
import compression from "compression";
app.use(compression());
```

---

### 📁 사전 압축 파일 (.gz) 서빙

#### 1. 빌드 시 압축 파일 생성 (Vite 기준)

```bash
npm install --save-dev vite-plugin-compression
```

```ts
// vite.config.ts
import compression from "vite-plugin-compression";

export default defineConfig({
  plugins: [
    compression({
      algorithm: "gzip",
      ext: ".gz",
      deleteOriginFile: false,
    }),
  ],
});
```

#### 2. Nginx에서 gzip_static 사용

```nginx
gzip_static on; # dist/assets/*.js.gz 파일 자동 서빙
```

---

### ⚠️ 주의사항

- 너무 작은 파일(<1KB)은 오히려 압축 오버헤드 발생 가능
- 실시간 압축(`gzip on`)은 서버 CPU 부담이 클 수 있음 → `.gz` 파일 사전 생성 권장
- 브라우저는 자동 해제하므로 별도 처리 필요 없음

---

### ✅ 결론

> Gzip 압축은 **파일 크기 감소 + 전송 속도 향상**이라는 큰 장점이 있으며,
> 특히 JS/CSS 파일은 압축 효과가 극대화되며,
> 사전 압축 파일을 서빙하는 방식(`gzip_static`)이 가장 성능과 안정성 모두 우수함.
