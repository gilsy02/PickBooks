# YES24 중계 서버 배포 (Cloudflare Workers, 무료 요금제)

왜 필요한가: YES24 안내상 API 키는 클라이언트(앱) 코드에 넣으면 안 되고, 앱 사용자마다 키를 받게 할 수도 없다.
그래서 키는 이 서버에만 두고 앱은 이 서버를 거쳐 검색한다.

## 1회 배포 (PC에서, 약 10분)
1. https://dash.cloudflare.com 가입 (무료)
2. Node.js 설치 후 이 폴더에서:
   ```
   npx wrangler login
   npx wrangler secret put YES24_API_KEY     # 발급받은 YES24 키 붙여 넣기
   npx wrangler deploy
   ```
3. 출력된 주소(예: https://pickbooks-yes24-proxy.<계정>.workers.dev)를 복사
4. GitHub 저장소 Settings > Secrets and variables > Actions > Variables 탭 > New repository variable
   - 이름: YES24_PROXY_URL, 값: 위 주소
5. 다음 빌드부터 앱은 키 입력 없이 이 서버로 검색한다.

## 한계
- X-PickBooks-App 헤더는 앱을 뜯어 보면 알 수 있어 완전한 보호는 아니다. 남용이 보이면 Cloudflare 대시보드의 Rate limiting 규칙을 추가한다.
- YES24 일일 한도(계정 기준 2만 회)는 모든 사용자가 나눠 쓴다. 캐시로 같은 검색은 하루 1회만 호출한다.
