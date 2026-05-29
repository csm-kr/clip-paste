# clip-paste

**원격(SSH)·devcontainer 환경에서 Claude Code 에 클립보드 이미지를 `Ctrl+Shift+V` 한 번으로 붙여넣기.**

로컬에서 Claude Code 를 돌릴 땐 `Ctrl+V` 로 이미지가 그냥 붙습니다. 하지만 **Windows → 원격 Linux → Docker 컨테이너** 처럼 경계를 넘으면, 클립보드 이미지는 터미널/SSH 를 못 넘어가서 `Ctrl+V` 가 안 됩니다. 이 플러그인은 그 간극을 메웁니다:

```
[캡처도구 Ctrl+C]  → Windows 클립보드
[Ctrl+Shift+V]     → AutoHotkey 가 가로챔
      ├ 클립보드 이미지를 PNG 로 저장
      ├ scp 로 원격 드롭 폴더에 전송
      └ Claude 프롬프트에 "/paste" 자동 입력
[/paste]           → 드롭 폴더의 최신 이미지를 Claude 가 읽음
```

`Ctrl+V`(텍스트 붙여넣기)는 건드리지 않습니다. 이미지는 `Ctrl+Shift+V` 전용.

---

## 구성 요소
- `commands/paste.md` — `/paste` 슬래시 명령. 드롭 폴더(`$CLIP_DROP`)의 최신 이미지를 읽음.
- `scripts/clip-paste.ahk` — Windows AutoHotkey v2 스크립트(템플릿). `Ctrl+Shift+V` 가로채서 전송.

## 사전 요구
- Windows + [AutoHotkey v2](https://www.autohotkey.com)
- 원격 호스트로 **비밀번호 없는 SSH 키** (VS Code Remote-SSH 가 되면 보통 키가 이미 있음)
- 원격(컨테이너)에서 Claude Code 사용 중

---

## 설치

### 1) 플러그인 설치 (Claude Code)
이 저장소를 마켓플레이스로 추가한 뒤 설치:
```
/plugin marketplace add <github-user>/clip-paste
/plugin install clip-paste
```
또는 `commands/paste.md` 를 `~/.claude/commands/` 에 복사해도 `/paste` 가 전역으로 동작합니다.

### 2) 드롭 폴더 정하기 (원격/컨테이너 쪽)
이미지가 도착할 폴더를 정하고, Claude 가 쓰는 쉘에 환경변수로 지정합니다. **컨테이너에서 공유·영속되는 경로**여야 합니다 (예: `~/.claude` 하위는 보통 호스트와 bind-mount 됨):
```bash
mkdir -p ~/.claude/clip-drop
echo 'export CLIP_DROP="$HOME/.claude/clip-drop"' >> ~/.bashrc   # 또는 ~/.zshrc
```
> `CLIP_DROP` 을 안 정하면 `/paste` 는 현재 프로젝트의 `_drop/` 을 봅니다.

### 3) AHK 스크립트 설정 (Windows 쪽)
`scripts/clip-paste.ahk` 를 Windows 로 받아서(VS Code 탐색기 → 우클릭 → 다운로드), 맨 위 3개 값을 채웁니다:
```ahk
SSH_USER_HOST := "you@1.2.3.4"                 ; 비번 없이 ssh 되는 계정@호스트
REMOTE_DROP   := "/home/you/.claude/clip-drop" ; 위 CLIP_DROP 의 "호스트 절대경로"
TERMINAL_EXE  := "Code.exe"                     ; VS Code 통합 터미널이면 그대로
```
> ⚠️ `REMOTE_DROP` 은 **호스트 절대경로**입니다. 컨테이너 경로(`/workspace/...`)가 아니라, 그 폴더가 호스트에 실제로 있는 위치예요. 컨테이너 안에서 `cat /proc/self/mountinfo | grep .claude` 로 호스트 경로를 알 수 있습니다.

### 4) 비밀번호 없는 SSH 키 (없으면)
Windows PowerShell:
```powershell
ssh-keygen -t ed25519 -f $env:USERPROFILE\.ssh\id_ed25519     # passphrase 는 Enter 로 비움
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh you@1.2.3.4 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
ssh you@1.2.3.4 "echo OK"                                      # 비번 없이 OK 나오면 성공
```

### 5) 실행 / 자동 시작
- `clip-paste.ahk` 더블클릭 → 트레이에 초록 H 아이콘.
- 부팅 시 자동 실행: `Win+R` → `shell:startup` → 그 폴더에 `clip-paste.ahk` 바로가기 넣기.

---

## 사용법
- **텍스트**: `Ctrl+C` → `Ctrl+V` (그대로)
- **이미지**: 캡처 `Ctrl+C` → Claude 프롬프트에서 **`Ctrl+Shift+V`** → 끝
  - `Ctrl+Shift+V` 누르면 ①~⑥ 말풍선으로 진행 단계가 보입니다. 멈춘 번호로 어디가 막혔는지 알 수 있어요.

## 문제 해결
| 증상 | 원인 / 해결 |
|---|---|
| 말풍선 전혀 안 뜸 | AHK 미실행, 또는 `TERMINAL_EXE` 가 실제 창과 안 맞음 |
| ② 이미지 없음 | 캡처도구가 클립보드에 복사를 안 함 (Ctrl+C 확인) |
| ⑤ scp 실패 | SSH 키 미설정(비번 요구) 또는 `REMOTE_DROP` 경로 오류 |
| ⑥ 떴는데 /paste 가 빈손 | `CLIP_DROP` 과 `REMOTE_DROP` 이 같은 폴더를 안 가리킴 |
