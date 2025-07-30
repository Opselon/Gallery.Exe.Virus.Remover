# 🛡️ Gallery-Lock: Der unzerstörbare Köder

<p align="center">
  <strong>Ein "Set-and-Forget"-PowerShell-Skript, das eine dauerhafte, unzerstörbare Straßensperre errichtet, um die <code>Gallery.exe</code>-Malware zu blockieren und eine Neuinfektion zu verhindern.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-5.1+-blue.svg" alt="PowerShell-Version">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="Lizenz">
  <img src="https://img.shields.io/badge/Platform-Windows-lightgrey.svg" alt="Plattform">
  <img src="https://img.shields.io/badge/Status-Active-brightgreen.svg" alt="Status">
</p>

---

## Das Problem: Der nervige `Gallery.exe`-Virus

Sind Sie es leid, die `Gallery.exe`-Malware zu entfernen, nur damit sie nach einem Neustart wieder erscheint? Dieser verbreitete Virus platziert seine ausführbare Datei in bestimmten Benutzer- und Systemordnern. Selbst nach der Reinigung Ihres Systems kehrt er oft zurück, weil die ursprüngliche Infektionsquelle (wie eine geplante Aufgabe oder ein anderer versteckter Prozess) versucht, ihn neu zu erstellen.

## Die Lösung: Eine digitale Festung

**Gallery-Lock** löscht den Virus nicht nur; es baut eine dauerhafte Festung an seiner Stelle. Das Skript erstellt null-Byte (leere) Köderdateien mit dem Namen `Gallery.exe` an den genauen Orten, die die Malware anvisiert. Anschließend wendet es extrem strenge Sicherheitsberechtigungen (ACLs) an, die es der Malware **unmöglich machen, diese Köder zu überschreiben oder zu löschen**.

Das Ergebnis? Der Versuch der Malware, Ihr System neu zu infizieren, wird auf Betriebssystemebene blockiert, jedes einzelne Mal.

---

## 🚀 Hauptmerkmale

| Merkmal | Beschreibung |
| :--- | :--- |
| ✅ **Beseitigt bestehende Infektionen** | Findet und löscht automatisch alle aktuellen `Gallery.exe`-Dateien von bekannten Malware-Speicherorten. |
| 🛡️ **Erstellt unveränderliche Köder** | Erzeugt leere Platzhalterdateien und sperrt sie. |
| 🔒 **Erweiterte ACL-Härtung** | Verwendet Zugriffskontrolllisten (ACLs), um allen, einschließlich Administratoren, alle Berechtigungen zu `VERWEIGERN`. Nur das zentrale `SYSTEM`-Konto behält die Kontrolle. |
| 🕵️ **Heimlich & unsichtbar** | Köderdateien werden als `versteckte` und `System`-Dateien festgelegt, wodurch sie bei normaler Verwendung unsichtbar sind. |
| 📈 **Klare & informative Protokollierung** | Bietet farbcodiertes Echtzeit-Feedback in der Konsole für jede durchgeführte Aktion. |
| 📦 **Keine Abhängigkeiten** | Ein eigenständiges PowerShell-Skript, das auf jedem modernen Windows-System ohne zusätzliche Installationen ausgeführt wird. |

---

## 🛠️ Wie man es benutzt: Die 2-Minuten-Anleitung

Für maximale Wirksamkeit muss das Skript als `SYSTEM` ausgeführt werden. Dies ist die höchste Autoritätsstufe unter Windows, sogar über dem Administrator.

### Empfohlene Methode: Als SYSTEM mit PsExec ausführen

Dies ist die **sicherste Methode** und garantiert, dass das Skript seine stärksten Schutzmaßnahmen anwenden kann.

1.  **PsExec herunterladen:**
    *   Laden Sie die offizielle **Sysinternals Suite** von Microsoft herunter: [**Hier herunterladen**](https://learn.microsoft.com/en-us/sysinternals/downloads/psexec).
    *   Extrahieren Sie die ZIP-Datei an einen einfachen Ort, wie `C:\Sysinternals`.

2.  **Ein Administrator-Terminal öffnen:**
    *   Drücken Sie `Win + X` und wählen Sie **Terminal (Admin)** oder **Windows PowerShell (Admin)**.

3.  **Zum PsExec-Ordner navigieren:**
    *   Navigieren Sie im Terminal zu dem Verzeichnis, in das Sie PsExec extrahiert haben.
      ```powershell
      cd C:\Sysinternals
      ```

4.  **Ein PowerShell auf SYSTEM-Ebene starten:**
    *   Führen Sie den folgenden Befehl aus. Ein neues PowerShell-Fenster wird mit `SYSTEM`-Berechtigungen geöffnet.
      ```powershell
      .\PsExec64.exe -i -s powershell.exe
      ```

5.  **Das Gallery-Lock-Skript ausführen:**
    *   Navigieren Sie im **neuen SYSTEM-Fenster** dorthin, wo Sie `Gallery-Lock.ps1` gespeichert haben.
    *   Legen Sie zuerst die Ausführungsrichtlinie für diese einzelne Sitzung fest und führen Sie dann das Skript aus.
      ```powershell
      # Skriptausführung nur in diesem Fenster zulassen
      Set-ExecutionPolicy Bypass -Scope Process -Force

      # Skript ausführen (den richtigen Pfad verwenden)
      .\Gallery-Lock.ps1
      ```

**Das ist alles!** Die Köderdateien sind jetzt vorhanden und gehärtet. Sie können alle Fenster schließen.

<details>
  <summary><strong>Alternative Methode: Als Administrator ausführen (weniger sicher)</strong></summary>

  > [!NOTE]
  > Diese Methode funktioniert, aber der Dateischutz ist nicht so stark, da ein Administrator leichter die Besitzrechte übernehmen kann. Sie wird nur empfohlen, wenn Sie PsExec nicht verwenden können.

  1. **Klicken Sie mit der rechten Maustaste** auf die Skriptdatei `Gallery-Lock.ps1`.
  2. Wählen Sie **"Mit PowerShell ausführen"**.
  3. Wenn Sie dazu aufgefordert werden, genehmigen Sie die UAC-Eingabeaufforderung (Benutzerkontensteuerung), um Administratorrechte zu gewähren.

  Das Skript benachrichtigt Sie, dass es als Administrator und nicht als SYSTEM ausgeführt wird.
</details>

---

## 🗺️ Geschützte Dateispeicherorte

Das Skript erstellt und schützt Köder in den folgenden Standard-Malware-Pfaden:

| Profiltyp | Pfad |
| :--- | :--- |
| **Benutzerprofil** | `%APPDATA%\Gallery.exe` |
| **Systemprofil** | `C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe` |

---

## 🧱 Wie es funktioniert: Eine technische Aufschlüsselung

Die Wirksamkeit des Skripts beruht auf einer mehrschichtigen Sicherheitsstrategie:

1.  **🔍 Scannen & Bereinigen:** Es prüft und löscht zunächst alle vorhandenen `Gallery.exe`-Dateien an den Zielorten, um einen sauberen Zustand zu gewährleisten.
2.  **📝 Den Köder erstellen:** Eine leere 0-Byte-Datei mit dem Namen `Gallery.exe` wird erstellt. Sie ist harmlos und nimmt keinen Platz ein.
3.  **🛡️ Die Festung bauen (ACL-Härtung):** Dies ist der kritischste Schritt. Das Skript ändert die Zugriffskontrollliste (ACL) der Datei:
    *   **Vererbung blockieren:** Es verhindert, dass die Datei Berechtigungen von ihrem übergeordneten Ordner erbt. Dies isoliert sie von zukünftigen Sicherheitsänderungen.
    *   **Allen verweigern:** Es fügt eine explizite `Deny FullControl`-Regel für die Gruppe `Jeder` hinzu. Unter Windows überschreibt eine explizite `Deny`-Regel immer alle `Allow`-Regeln. Das bedeutet, dass kein Benutzer, **nicht einmal ein Administrator**, die Datei schreiben, ändern oder löschen kann.
    *   **SYSTEM die Kontrolle gewähren:** Es stellt sicher, dass nur das Konto `NT AUTHORITY\SYSTEM` oder `TrustedInstaller` `FullControl` hat. Dies ist für die Systemintegrität notwendig, aber es ist ein Konto, das Malware (und Benutzer) nicht einfach verwenden können.
4.  **👻 Unsichtbar werden:** Schließlich setzt es die Dateiattribute auf `Versteckt` und `System`, wodurch sie in der Standardansicht im Datei-Explorer ausgeblendet wird, um eine versehentliche Entdeckung oder Manipulation zu verhindern.

---

## ⚠️ Wichtige Warnungen & Wie man es rückgängig macht

> [!WARNING]
> **Dieses Skript erstellt eine Datei, die *absichtlich* schwer zu entfernen ist, sogar für Sie.** Führen Sie dies nicht auf einer Datei aus, auf die Sie möglicherweise später zugreifen müssen. Es ist speziell dafür konzipiert, bekannte Malware-Pfade zu blockieren.

### Wie man eine gesperrte Köderdatei manuell entfernt

Wenn Sie die Köder jemals entfernen müssen, müssen Sie den Schutz als **Administrator** manuell umkehren.

1.  **Ein Administrator-Terminal öffnen** (`Win + X` > Terminal (Admin)).
2.  **Besitz übernehmen** der Datei. Ersetzen Sie den Pfad durch den richtigen.
    *Für die Benutzerdatei:*
    ```cmd
    takeown /f "%APPDATA%\Gallery.exe"
    ```
    *Für die Systemdatei:*
    ```cmd
    takeown /f "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe"
    ```
3.  **Berechtigungen zurücksetzen**, um sie vom übergeordneten Ordner zu erben.
    *Für die Benutzerdatei:*
    ```cmd
    icacls "%APPDATA%\Gallery.exe" /reset
    ```
    *Für die Systemdatei:*
    ```cmd
    icacls "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe" /reset
    ```
4.  Sie können die Datei jetzt normal **löschen**.
    ```powershell
    Remove-Item -Path "$env:APPDATA\Gallery.exe" -Force
    ```

---

## 🔎 Fehlerbehebung & FAQ

| Symptom / Frage | Lösung / Erklärung |
| :--- | :--- |
| ❌ **"Zugriff verweigert"-Fehler während der Skriptausführung.** | Dies ist zu erwarten, wenn Sie als Administrator anstelle von SYSTEM ausführen. Das Skript kann `SYSTEM` nicht als Besitzer festlegen. **Verwenden Sie die PsExec-Methode für vollständigen Schutz.** |
| 📜 **"Das Ausführen von Skripts ist auf diesem System deaktiviert."-Fehler.** | Dies ist ein Fehler der PowerShell-Ausführungsrichtlinie. Sie können ihn für den aktuellen Prozess umgehen, indem Sie `Set-ExecutionPolicy Bypass -Scope Process -Force` ausführen, bevor Sie das Hauptskript ausführen. |
| 🪟 **Ich kann die `Gallery.exe`-Datei im Datei-Explorer nicht sehen.** | Das ist beabsichtigt. Die Datei ist versteckt. Um sie anzuzeigen, gehen Sie zum Datei-Explorer > `Ansicht` > `Optionen` > Registerkarte `Ansicht` und aktivieren Sie **"Versteckte Dateien anzeigen..."** und deaktivieren Sie **"Geschützte Systemdateien ausblenden"**. |
| 🗑️ **Ich kann die Datei nicht löschen, selbst als Administrator!** | Das bedeutet, dass das Skript korrekt funktioniert! Es ist so konzipiert, dass es jeden blockiert, auch Sie. Befolgen Sie die Schritte im Abschnitt **[Wie man es rückgängig macht](#️-wichtige-warnungen--wie-man-es-rückgängig-macht)**, um es zu entfernen. |
| 🤔 **Warum ist es so wichtig, als `SYSTEM` auszuführen?** | Das `SYSTEM`-Konto ist die ultimative Autorität unter Windows. Indem `SYSTEM` zum Besitzer des Köders gemacht wird, wird verhindert, dass selbst ein Administrator ihn leicht ändern kann, ohne zuvor explizit den Besitz zu übernehmen. Malware, die mit Administratorrechten ausgeführt wird, wird blockiert, was ein großer Sicherheitsgewinn ist. |

---

## 📜 Lizenz

Dieses Projekt ist Open Source und wird unter der [MIT-Lizenz](https://github.com/i-am-aka/readme-assets/blob/main/LICENSE) vertrieben. Sie können es frei verwenden, teilen und ändern.

---

## 📥 Original-README herunterladen

```bash
curl -o README.md https://raw.githubusercontent.com/i-am-aka/Gallery-Lock/main/README.md
```
