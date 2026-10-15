# upstream-watch

커머스24 전문가용 도구(Pixel24·Screen24·Paper24·Reel24·Vector24·Write24·Slide24·CAD24·Sheet24)의 원본(ArtCraft) 저장소에
새 릴리스가 나오면 알려주는 점검 저장소입니다.

- 매일 09:00 KST에 `.github/workflows/watch.yml`이 `versions.json`(우리가 쓰는 원본 버전)과 원본의 최신 릴리스를 비교합니다.
- 새 버전이 있으면 **이슈**(label `upstream-update`)를 하나 열고 `versions.json`을 갱신합니다(같은 버전은 한 번만).
- 원본 저장소를 읽을 수 없으면(삭제·비공개) label `upstream-unreachable` 이슈를 엽니다.
- 도구를 실제로 새 버전으로 올렸을 때는 `versions.json`의 `current`를 맞춰 두면 됩니다(이슈가 먼저 갱신해 두므로 보통 그대로).

수동 실행: Actions → Upstream watch → Run workflow.
