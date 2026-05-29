---
description: 클립보드 드롭 폴더의 가장 최근 이미지를 찾아 읽어들인다 (원격 환경 Ctrl+V 우회 붙여넣기)
allowed-tools: Bash(ls:*), Read
---

드롭 폴더에서 **가장 최근에 수정된 이미지 파일**(png/jpg/jpeg/webp/gif)을 찾아 Read 로 읽는다.

드롭 폴더는 환경변수 `CLIP_DROP` 로 지정한다. 없으면 `_drop`(현재 작업 폴더 기준) 을 쓴다.

순서:
1. 다음으로 최신 이미지 경로를 구한다:
   `DROP="${CLIP_DROP:-_drop}"; ls -t "$DROP"/*.png "$DROP"/*.jpg "$DROP"/*.jpeg "$DROP"/*.webp "$DROP"/*.gif 2>/dev/null | head -1`
2. 결과가 없으면 "드롭 폴더(`$CLIP_DROP` 또는 `_drop`)에 이미지가 없습니다. 캡처 후 Ctrl+Shift+V 했는지 확인하세요." 라고 알리고 멈춘다.
3. 있으면 그 파일을 Read 로 읽고, 무엇이 보이는지 한 줄로 요약한 뒤 이어지는 작업에 활용한다.

사용자가 `/paste` 뒤에 추가 지시를 붙였다면($ARGUMENTS) 그 지시를 이미지에 대해 수행한다.
