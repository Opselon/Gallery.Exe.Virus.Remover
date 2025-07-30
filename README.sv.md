# 🛡️ Galleri-Lås: Det Oförstörbara Lockbetet

<p align="center">
  <strong>Ett "ställ in och glöm"-PowerShell-skript som skapar en permanent, oförstörbar vägspärr för att blockera <code>Gallery.exe</code>-skadeprogrammet och förhindra återinfektion.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-5.1+-blue.svg" alt="PowerShell-version">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="Licens">
  <img src="https://img.shields.io/badge/Platform-Windows-lightgrey.svg" alt="Plattform">
  <img src="https://img.shields.io/badge/Status-Active-brightgreen.svg" alt="Status">
</p>

---

## Problemet: Det Irriterande `Gallery.exe`-Viruset

Är du trött på att ta bort `Gallery.exe`-skadeprogrammet, bara för att det ska dyka upp igen efter en omstart? Detta vanliga virus fungerar genom att placera sin körbara fil i specifika användar- och systemmappar. Även efter att du har rensat ditt system kommer det ofta tillbaka eftersom den ursprungliga infektionskällan (som en schemalagd uppgift eller en annan dold process) försöker återskapa det.

## Lösningen: En Digital Fästning

**Galleri-Lås** tar inte bara bort viruset; det bygger en permanent fästning i dess ställe. Skriptet skapar noll-byte (tomma) lockbetesfiler med namnet `Gallery.exe` på de exakta platserna som skadeprogrammet riktar in sig på. Det tillämpar sedan extremt strikta säkerhetsbehörigheter (ACL) som gör dessa lockbeten **omöjliga för skadeprogrammet att skriva över eller ta bort**.

Resultatet? Skadeprogrammets försök att återinfektera ditt system blockeras på operativsystemsnivå, varje gång.

---

## 🚀 Nyckelfunktioner

| Funktion | Beskrivning |
| :--- | :--- |
| ✅ **Utrotar Befintliga Infektioner** | Hittar och tar automatiskt bort alla nuvarande `Gallery.exe`-filer från kända skadeprogramsplatser. |
| 🛡️ **Skapar Oföränderliga Lockbeten** | Genererar tomma platshållarfiler och låser dem. |
| 🔒 **Avancerad ACL-Härdning** | Använder åtkomstkontrollistor (ACL) för att `NEKA` alla behörigheter till alla, inklusive administratörer. Endast kärn-`SYSTEM`-kontot behåller kontrollen. |
| 🕵️ **Smygande & Osynlig** | Lockbetesfiler ställs in som `Dolda` och `System`-filer, vilket gör dem osynliga vid normal användning. |
| 📈 **Tydlig & Informativ Loggning** | Ger färgkodad, realtidsfeedback i konsolen för varje åtgärd som vidtas. |
| 📦 **Noll Beroenden** | Ett fristående PowerShell-skript som körs på alla moderna Windows-system utan att behöva extra installationer. |

---

## 🛠️ Hur man Använder: 2-Minutersguiden

För maximal effektivitet måste skriptet köras som `SYSTEM`. Detta är den högsta behörighetsnivån på Windows, till och med över administratör.

### Rekommenderad Metod: Kör som SYSTEM med PsExec

Detta är den **säkraste metoden** och garanterar att skriptet kan tillämpa sina starkaste skydd.

1.  **Ladda ner PsExec:**
    *   Ladda ner den officiella **Sysinternals Suite** från Microsoft: [**Ladda ner Här**](https://learn.microsoft.com/en-us/sysinternals/downloads/psexec).
    *   Extrahera ZIP-filen till en enkel plats, som `C:\Sysinternals`.

2.  **Öppna en Administratörsterminal:**
    *   Tryck på `Win + X` och välj **Terminal (Admin)** eller **Windows PowerShell (Admin)**.

3.  **Navigera till PsExec-mappen:**
    *   I terminalen, gå till katalogen där du extraherade PsExec.
      ```powershell
      cd C:\Sysinternals
      ```

4.  **Starta en PowerShell på SYSTEM-nivå:**
    *   Kör följande kommando. Ett nytt PowerShell-fönster öppnas med `SYSTEM`-privilegier.
      ```powershell
      .\PsExec64.exe -i -s powershell.exe
      ```

5.  **Kör Galleri-Lås-skriptet:**
    *   I det **nya SYSTEM-fönstret**, navigera till där du sparade `Gallery-Lock.ps1`.
    *   Ställ först in exekveringspolicyn för denna enskilda session, kör sedan skriptet.
      ```powershell
      # Tillåt att skriptet körs endast i detta fönster
      Set-ExecutionPolicy Bypass -Scope Process -Force

      # Kör skriptet (använd rätt sökväg)
      .\Gallery-Lock.ps1
      ```

**Det är allt!** Lockbetesfilerna är nu på plats och härdade. Du kan stänga alla fönster.

<details>
  <summary><strong>Alternativ Metod: Kör som Administratör (Mindre Säker)</strong></summary>

  > [!NOTE]
  > Denna metod fungerar, men filskyddet är inte lika starkt eftersom en administratör fortfarande kan ta äganderätt lättare. Det rekommenderas endast om du inte kan använda PsExec.

  1. **Högerklicka** på `Gallery-Lock.ps1`-skriptfilen.
  2. Välj **"Kör med PowerShell"**.
  3. Om du uppmanas, godkänn UAC-prompten (User Account Control) för att ge den administratörsbehörighet.

  Skriptet kommer att meddela dig att det körs som administratör och inte som SYSTEM.
</details>

---

## 🗺️ Skyddade Filplatser

Skriptet skapar och skyddar lockbeten i följande standardvägar för skadeprogram:

| Profiltyp | Sökväg |
| :--- | :--- |
| **Användarprofil** | `%APPDATA%\Gallery.exe` |
| **Systemprofil** | `C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe` |

---

## 🧱 Hur Det Fungerar: En Teknisk Genomgång

Skriptets effektivitet kommer från en flerskiktad säkerhetsstrategi:

1.  **🔍 Skanna & Rensa:** Det kontrollerar och tar först bort alla befintliga `Gallery.exe`-filer på målplatserna, vilket säkerställer en ren start.
2.  **📝 Skapa Lockbetet:** En tom 0-byte-fil med namnet `Gallery.exe` skapas. Den är ofarlig och tar ingen plats.
3.  **🛡️ Bygg Fästningen (ACL-Härdning):** Detta är det mest kritiska steget. Skriptet ändrar filens åtkomstkontrollista (ACL):
    *   **Blockerar Arv:** Det hindrar filen från att ärva behörigheter från sin överordnade mapp. Detta isolerar den från framtida säkerhetsändringar.
    *   **Nekar Alla:** Det lägger till en explicit `Deny FullControl`-regel för `Alla`-gruppen. I Windows åsidosätter en explicit `Deny`-regel alltid alla `Allow`-regler. Detta innebär att ingen användare, **inte ens en administratör**, kan skriva, ändra eller ta bort filen.
    *   **Ger SYSTEM Kontroll:** Det säkerställer att endast `NT AUTHORITY\SYSTEM`- eller `TrustedInstaller`-kontot har `FullControl`. Detta är nödvändigt för systemintegriteten men är ett konto som skadeprogram (och användare) inte lätt kan använda.
4.  **👻 Bli Osynlig:** Slutligen ställer det in filattributen till `Dold` och `System`, vilket döljer den från standardvyn i Utforskaren för att förhindra oavsiktlig upptäckt eller manipulering.

---

## ⚠️ Viktiga Varningar & Hur man Ångrar

> [!WARNING]
> **Detta skript skapar en fil som är *avsiktligt* svår att ta bort, även för dig.** Kör inte detta på någon fil som du kan behöva komma åt senare. Det är specifikt utformat för att blockera kända skadeprogramsvägar.

### Hur man Manuellt Tar Bort en Låst Lockbetesfil

Om du någonsin behöver ta bort lockbetena måste du manuellt vända skyddet som **administratör**.

1.  **Öppna en Administratörsterminal** (`Win + X` > Terminal (Admin)).
2.  **Ta Äganderätt** över filen. Ersätt sökvägen med den korrekta.
    *För användarfilen:*
    ```cmd
    takeown /f "%APPDATA%\Gallery.exe"
    ```
    *För systemfilen:*
    ```cmd
    takeown /f "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe"
    ```
3.  **Återställ Behörigheter** för att ärva från den överordnade mappen.
    *För användarfilen:*
    ```cmd
    icacls "%APPDATA%\Gallery.exe" /reset
    ```
    *För systemfilen:*
    ```cmd
    icacls "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe" /reset
    ```
4.  Du kan nu **ta bort filen** normalt.
    ```powershell
    Remove-Item -Path "$env:APPDATA\Gallery.exe" -Force
    ```

---

## 🔎 Felsökning & Vanliga Frågor

| Symptom / Fråga | Lösning / Förklaring |
| :--- | :--- |
| ❌ **"Åtkomst nekad"-fel under skriptkörning.** | Detta är förväntat om du kör som administratör istället för SYSTEM. Skriptet kan inte ställa in `SYSTEM` som ägare. **Använd PsExec-metoden för fullständigt skydd.** |
| 📜 **"Körning av skript är inaktiverat på detta system."-fel.** | Detta är ett PowerShell-exekveringspolicyfel. Du kan kringgå det för den aktuella processen genom att köra `Set-ExecutionPolicy Bypass -Scope Process -Force` innan du kör huvudskriptet. |
| 🪟 **Jag kan inte se `Gallery.exe`-filen i Utforskaren.** | Detta är avsiktligt. Filen är dold. För att se den, gå till Utforskaren > `Visa` > `Alternativ` > fliken `Visa`, och markera **"Visa dolda filer..."** och avmarkera **"Dölj skyddade operativsystemfiler"**. |
| 🗑️ **Jag kan inte ta bort filen, inte ens som administratör!** | Detta innebär att skriptet fungerar korrekt! Det är utformat för att blockera alla, inklusive dig. Följ stegen i avsnittet **[Hur man Ångrar](#️-viktiga-varningar--hur-man-ångrar)** för att ta bort den. |
| 🤔 **Varför är det så viktigt att köra som `SYSTEM`?** | `SYSTEM`-kontot är den ultimata auktoriteten på Windows. Genom att göra `SYSTEM` till ägare av lockbetet förhindrar det även en administratör från att enkelt ändra det utan att först uttryckligen ta äganderätt. Skadeprogram som körs med administratörsbehörighet kommer att blockeras, vilket är en enorm säkerhetsvinst. |

---

## 📜 Licens

Detta projekt är öppen källkod och distribueras under [MIT-licensen](https://github.com/i-am-aka/readme-assets/blob/main/LICENSE). Du är fri att använda, dela och ändra det.

---

## 📥 Ladda ner Original-README

```bash
curl -o README.md https://raw.githubusercontent.com/i-am-aka/Gallery-Lock/main/README.md
```
