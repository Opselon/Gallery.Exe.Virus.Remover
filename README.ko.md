# 🛡️ Gallery-Lock: 파괴 불가능한 미끼

<p align="center">
  <strong><code>Gallery.exe</code> 맬웨어를 차단하고 재감염을 방지하기 위해 영구적이고 파괴 불가능한 장애물을 만드는 "설정하고 잊어버리는" PowerShell 스크립트입니다.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-5.1+-blue.svg" alt="PowerShell 버전">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="라이선스">
  <img src="https://img.shields.io/badge/Platform-Windows-lightgrey.svg" alt="플랫폼">
  <img src="https://img.shields.io/badge/Status-Active-brightgreen.svg" alt="상태">
</p>

---

## 문제: 성가신 `Gallery.exe` 바이러스

`Gallery.exe` 맬웨어를 제거하고 나면 재부팅 후 다시 나타나는 것에 지치셨나요? 이 일반적인 바이러스는 특정 사용자 및 시스템 폴더에 실행 파일을 배치하여 작동합니다. 시스템을 정리한 후에도 원래 감염원(예: 예약된 작업 또는 다른 숨겨진 프로세스)이 다시 만들려고 시도하기 때문에 종종 다시 나타납니다.

## 해결책: 디지털 요새

**Gallery-Lock**은 단순히 바이러스를 삭제하는 것이 아니라 그 자리에 영구적인 요새를 구축합니다. 이 스크립트는 맬웨어가 대상으로 하는 정확한 위치에 `Gallery.exe`라는 이름의 0바이트(빈) 미끼 파일을 만듭니다. 그런 다음 매우 엄격한 보안 권한(ACL)을 적용하여 맬웨어가 이러한 미끼를 **덮어쓰거나 삭제할 수 없도록** 만듭니다.

결과는? 맬웨어가 시스템을 다시 감염시키려는 시도는 운영 체제 수준에서 매번 차단됩니다.

---

## 🚀 주요 기능

| 기능 | 설명 |
| :--- | :--- |
| ✅ **기존 감염 근절** | 알려진 맬웨어 위치에서 현재 `Gallery.exe` 파일을 자동으로 찾아 삭제합니다. |
| 🛡️ **불변의 미끼 생성** | 빈 자리 표시자 파일을 생성하고 잠급니다. |
| 🔒 **고급 ACL 강화** | 액세스 제어 목록(ACL)을 사용하여 관리자를 포함한 모든 사람에게 모든 권한을 `거부`합니다. 핵심 `SYSTEM` 계정만 제어권을 유지합니다. |
| 🕵️ **은밀하고 보이지 않음** | 미끼 파일은 `숨김` 및 `시스템` 파일로 설정되어 정상적인 사용 중에는 보이지 않습니다. |
| 📈 **명확하고 유익한 로깅** | 수행된 모든 작업에 대해 콘솔에서 색상으로 구분된 실시간 피드백을 제공합니다. |
| 📦 **종속성 없음** | 추가 설치 없이 최신 Windows 시스템에서 실행되는 독립형 PowerShell 스크립트입니다. |

---

## 🛠️ 사용 방법: 2분 가이드

최대의 효과를 위해 스크립트는 `SYSTEM`으로 실행해야 합니다. 이는 Windows에서 관리자보다 높은 최고 권한 수준입니다.

### 권장 방법: PsExec을 사용하여 SYSTEM으로 실행

이것은 **가장 안전한 방법**이며 스크립트가 가장 강력한 보호를 적용할 수 있도록 보장합니다.

1.  **PsExec 다운로드:**
    *   Microsoft에서 공식 **Sysinternals Suite**를 다운로드하십시오: [**여기에서 다운로드**](https://learn.microsoft.com/en-us/sysinternals/downloads/psexec).
    *   ZIP 파일을 `C:\Sysinternals`와 같은 간단한 위치에 추출하십시오.

2.  **관리자 터미널 열기:**
    *   `Win + X`를 누르고 **터미널(관리자)** 또는 **Windows PowerShell(관리자)**을 선택하십시오.

3.  **PsExec 폴더로 이동:**
    *   터미널에서 PsExec을 추출한 디렉터리로 이동하십시오.
      ```powershell
      cd C:\Sysinternals
      ```

4.  **SYSTEM 수준 PowerShell 시작:**
    *   다음 명령을 실행하십시오. `SYSTEM` 권한을 가진 새 PowerShell 창이 열립니다.
      ```powershell
      .\PsExec64.exe -i -s powershell.exe
      ```

5.  **Gallery-Lock 스크립트 실행:**
    *   **새 SYSTEM 창**에서 `Gallery-Lock.ps1`을 저장한 위치로 이동하십시오.
    *   먼저 이 단일 세션에 대한 실행 정책을 설정한 다음 스크リプト를 실행하십시오.
      ```powershell
      # 이 창에서만 스크립트 실행 허용
      Set-ExecutionPolicy Bypass -Scope Process -Force

      # 스크립트 실행 (올바른 경로 사용)
      .\Gallery-Lock.ps1
      ```

**이게 다입니다!** 이제 미끼 파일이 제자리에 있고 강화되었습니다. 모든 창을 닫을 수 있습니다.

<details>
  <summary><strong>대체 방법: 관리자로 실행(덜 안전함)</strong></summary>

  > [!NOTE]
  > 이 방법은 작동하지만 관리자가 더 쉽게 소유권을 가져갈 수 있기 때문에 파일 보호가 그다지 강력하지 않습니다. PsExec을 사용할 수 없는 경우에만 권장됩니다.

  1. `Gallery-Lock.ps1` 스크립트 파일을 **마우스 오른쪽 버튼으로 클릭**하십시오.
  2. **"PowerShell로 실행"**을 선택하십시오.
  3. 메시지가 표시되면 UAC(사용자 계정 컨트롤) 프롬프트를 승인하여 관리자 권한을 부여하십시오.

  스크립트는 SYSTEM이 아닌 관리자로 실행 중임을 알려줍니다.
</details>

---

## 🗺️ 보호된 파일 위치

스크립트는 다음 표준 맬웨어 경로에 미끼를 만들고 보호합니다.

| 프로필 유형 | 경로 |
| :--- | :--- |
| **사용자 프로필** | `%APPDATA%\Gallery.exe` |
| **시스템 프로필** | `C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe` |

---

## 🧱 작동 방식: 기술적 분석

스크립트의 효과는 다층적인 보안 전략에서 비롯됩니다.

1.  **🔍 스캔 및 정리:** 먼저 대상 위치에 있는 기존 `Gallery.exe` 파일을 확인하고 삭제하여 깨끗한 상태를 보장합니다.
2.  **📝 미끼 만들기:** `Gallery.exe`라는 이름의 빈 0바이트 파일이 생성됩니다. 무해하며 공간을 차지하지 않습니다.
3.  **🛡️ 요새 구축(ACL 강화):** 이것이 가장 중요한 단계입니다. 스크립트는 파일의 액세스 제어 목록(ACL)을 수정합니다.
    *   **상속 차단:** 파일이 부모 폴더에서 권한을 상속하는 것을 방지합니다. 이렇게 하면 향후 보안 변경으로부터 격리됩니다.
    *   **모두 거부:** `Everyone` 그룹에 대해 명시적인 `Deny FullControl` 규칙을 추가합니다. Windows에서 명시적인 `Deny` 규칙은 항상 `Allow` 규칙보다 우선합니다. 즉, 관리자를 포함한 **어떤 사용자도** 파일을 쓰거나 수정하거나 삭제할 수 없습니다.
    *   **SYSTEM에 제어 권한 부여:** `NT AUTHORITY\SYSTEM` 또는 `TrustedInstaller` 계정만 `FullControl`을 갖도록 보장합니다. 이는 시스템 무결성을 위해 필요하지만 맬웨어(및 사용자)가 쉽게 사용할 수 없는 계정입니다.
4.  **👻 보이지 않게 하기:** 마지막으로 파일 속성을 `숨김` 및 `시스템`으로 설정하여 파일 탐색기의 표준 보기에서 숨겨 우발적인 발견이나 조작을 방지합니다.

---

## ⚠️ 중요한 경고 및 실행 취소 방법

> [!WARNING]
> **이 스크립트는 사용자조차도 제거하기 *의도적으로* 어려운 파일을 만듭니다.** 나중에 액세스해야 할 수 있는 파일에서는 이 스크립트를 실행하지 마십시오. 알려진 맬웨어 경로를 차단하도록 특별히 설계되었습니다.

### 잠긴 미끼 파일을 수동으로 제거하는 방법

미끼를 제거해야 하는 경우 **관리자**로서 수동으로 보호를 되돌려야 합니다.

1.  **관리자 터미널 열기** (`Win + X` > 터미널(관리자)).
2.  파일의 **소유권 가져오기**. 경로를 올바른 것으로 바꾸십시오.
    *사용자 파일의 경우:*
    ```cmd
    takeown /f "%APPDATA%\Gallery.exe"
    ```
    *시스템 파일의 경우:*
    ```cmd
    takeown /f "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe"
    ```
3.  부모 폴더에서 상속하도록 **권한 재설정**.
    *사용자 파일의 경우:*
    ```cmd
    icacls "%APPDATA%\Gallery.exe" /reset
    ```
    *시스템 파일의 경우:*
    ```cmd
    icacls "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe" /reset
    ```
4.  이제 정상적으로 **파일을 삭제**할 수 있습니다.
    ```powershell
    Remove-Item -Path "$env:APPDATA\Gallery.exe" -Force
    ```

---

## 🔎 문제 해결 및 FAQ

| 증상/질문 | 해결책/설명 |
| :--- | :--- |
| ❌ **스크립트 실행 중 "액세스 거부" 오류.** | SYSTEM이 아닌 관리자로 실행하는 경우 예상되는 현상입니다. 스크립트는 `SYSTEM`을 소유자로 설정할 수 없습니다. **완전한 보호를 위해 PsExec 방법을 사용하십시오.** |
| 📜 **"이 시스템에서 스크립트 실행이 비활성화되었습니다." 오류.** | PowerShell 실행 정책 오류입니다. 주 스크립트를 실행하기 전에 `Set-ExecutionPolicy Bypass -Scope Process -Force`를 실행하여 현재 프로세스에 대해 이를 우회할 수 있습니다. |
| 🪟 **파일 탐색기에서 `Gallery.exe` 파일을 볼 수 없습니다.** | 의도된 것입니다. 파일이 숨겨져 있습니다. 보려면 파일 탐색기 > `보기` > `옵션` > `보기` 탭으로 이동하여 **"숨김 파일 표시..."**를 선택하고 **"보호된 운영 체제 파일 숨기기"**를 선택 취소하십시오. |
| 🗑️ **관리자인데도 파일을 삭제할 수 없습니다!** | 스크립트가 제대로 작동하고 있다는 의미입니다! 사용자를 포함한 모든 사람을 차단하도록 설계되었습니다. 제거하려면 **[실행 취소 방법](#️-중요한-경고-및-실행-취소-방법)** 섹션의 단계를 따르십시오. |
| 🤔 **`SYSTEM`으로 실행하는 것이 왜 그렇게 중요한가요?** | `SYSTEM` 계정은 Windows의 최종 권한입니다. `SYSTEM`을 미끼의 소유자로 만들면 관리자조차도 명시적으로 소유권을 가져가지 않고는 쉽게 수정할 수 없습니다. 관리자 권한으로 실행되는 맬웨어는 차단되어 보안에 큰 이점이 됩니다. |

---

## 📜 라이선스

이 프로젝트는 오픈 소스이며 [MIT 라이선스](https://github.com/i-am-aka/readme-assets/blob/main/LICENSE)에 따라 배포됩니다. 자유롭게 사용, 공유 및 수정할 수 있습니다.

---

## 📥 원본 README 다운로드

```bash
curl -o README.md https://raw.githubusercontent.com/i-am-aka/Gallery-Lock/main/README.md
```
