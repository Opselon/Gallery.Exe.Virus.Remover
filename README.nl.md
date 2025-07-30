# 🛡️ Galerij-Slot: Het Onverwoestbare Lokaas

<p align="center">
  <strong>Een "instellen en vergeten" PowerShell-script dat een permanente, onverwoestbare wegversperring creëert om de <code>Gallery.exe</code>-malware te blokkeren en herinfectie te voorkomen.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-5.1+-blue.svg" alt="PowerShell Versie">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="Licentie">
  <img src="https://img.shields.io/badge/Platform-Windows-lightgrey.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Status-Active-brightgreen.svg" alt="Status">
</p>

---

## Het Probleem: Het Vervelende `Gallery.exe`-Virus

Ben je het zat om de `Gallery.exe`-malware te verwijderen, om het vervolgens na een herstart weer te zien verschijnen? Dit veelvoorkomende virus werkt door zijn uitvoerbare bestand in specifieke gebruikers- en systeemmappen te plaatsen. Zelfs na het opschonen van je systeem, keert het vaak terug omdat de oorspronkelijke infectiebron (zoals een geplande taak of een ander verborgen proces) het probeert opnieuw aan te maken.

## De Oplossing: Een Digitale Vesting

**Galerij-Slot** verwijdert niet alleen het virus; het bouwt een permanente vesting op zijn plaats. Het script maakt nul-byte (lege) lokbestanden genaamd `Gallery.exe` op de exacte locaties die de malware target. Vervolgens past het extreem strikte beveiligingsmachtigingen (ACL's) toe die het voor de malware **onmogelijk maken om deze lokazen te overschrijven of te verwijderen**.

Het resultaat? De poging van de malware om je systeem opnieuw te infecteren wordt op het niveau van het besturingssysteem geblokkeerd, elke keer weer.

---

## 🚀 Belangrijkste Kenmerken

| Kenmerk | Beschrijving |
| :--- | :--- |
| ✅ **Roeit Bestaande Infecties Uit** | Vindt en verwijdert automatisch alle huidige `Gallery.exe`-bestanden van bekende malwarelocaties. |
| 🛡️ **Creëert Onveranderlijke Lokazen** | Genereert lege placeholder-bestanden en vergrendelt ze. |
| 🔒 **Geavanceerde ACL-Verharding** | Gebruikt Toegangscontrolelijsten (ACL's) om alle machtigingen voor iedereen, inclusief Beheerders, te `WEIGEREN`. Alleen het kern-`SYSTEM`-account behoudt de controle. |
| 🕵️ **Stiekem & Onzichtbaar** | Lokaasbestanden worden ingesteld als `Verborgen` en `Systeem`-bestanden, waardoor ze onzichtbaar zijn tijdens normaal gebruik. |
| 📈 **Duidelijke & Informatieve Logboekregistratie** | Biedt kleurgecodeerde, realtime feedback in de console voor elke ondernomen actie. |
| 📦 **Geen Afhankelijkheden** | Een op zichzelf staand PowerShell-script dat draait op elk modern Windows-systeem zonder extra installaties. |

---

## 🛠️ Hoe te Gebruiken: De 2-Minuten Gids

Voor maximale effectiviteit moet het script worden uitgevoerd als `SYSTEM`. Dit is het hoogste autoriteitsniveau op Windows, zelfs boven Beheerder.

### Aanbevolen Methode: Uitvoeren als SYSTEM met PsExec

Dit is de **meest veilige methode** en garandeert dat het script zijn sterkste bescherming kan toepassen.

1.  **Download PsExec:**
    *   Download de officiële **Sysinternals Suite** van Microsoft: [**Hier Downloaden**](https://learn.microsoft.com/en-us/sysinternals/downloads/psexec).
    *   Pak het ZIP-bestand uit naar een eenvoudige locatie, zoals `C:\Sysinternals`.

2.  **Open een Beheerdersterminal:**
    *   Druk op `Win + X` en selecteer **Terminal (Admin)** of **Windows PowerShell (Admin)**.

3.  **Navigeer naar de PsExec-map:**
    *   Ga in de terminal naar de map waar je PsExec hebt uitgepakt.
      ```powershell
      cd C:\Sysinternals
      ```

4.  **Start een PowerShell op SYSTEEM-niveau:**
    *   Voer het volgende commando uit. Er wordt een nieuw PowerShell-venster geopend met `SYSTEM`-rechten.
      ```powershell
      .\PsExec64.exe -i -s powershell.exe
      ```

5.  **Voer het Galerij-Slot Script uit:**
    *   Navigeer in het **nieuwe SYSTEM-venster** naar de locatie waar je `Gallery-Lock.ps1` hebt opgeslagen.
    *   Stel eerst het uitvoeringsbeleid in voor deze enkele sessie, en voer dan het script uit.
      ```powershell
      # Sta toe dat het script alleen in dit venster wordt uitgevoerd
      Set-ExecutionPolicy Bypass -Scope Process -Force

      # Voer het script uit (gebruik het juiste pad)
      .\Gallery-Lock.ps1
      ```

**Dat is alles!** De lokbestanden zijn nu op hun plaats en verhard. Je kunt alle vensters sluiten.

<details>
  <summary><strong>Alternatieve Methode: Uitvoeren als Beheerder (Minder Veilig)</strong></summary>

  > [!NOTE]
  > Deze methode werkt, maar de bestandsbescherming is niet zo sterk omdat een Beheerder nog steeds gemakkelijker eigendom kan nemen. Het wordt alleen aanbevolen als je PsExec niet kunt gebruiken.

  1. **Klik met de rechtermuisknop** op het `Gallery-Lock.ps1`-scriptbestand.
  2. Selecteer **"Uitvoeren met PowerShell"**.
  3. Keur desgevraagd de UAC-prompt (User Account Control) goed om beheerdersrechten te verlenen.

  Het script zal je op de hoogte stellen dat het als Beheerder draait en niet als SYSTEM.
</details>

---

## 🗺️ Beschermde Bestandslocaties

Het script creëert en beschermt lokazen in de volgende standaard malwarepaden:

| Profieltype | Pad |
| :--- | :--- |
| **Gebruikersprofiel** | `%APPDATA%\Gallery.exe` |
| **Systeemprofiel** | `C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe` |

---

## 🧱 Hoe Het Werkt: Een Technische Uiteenzetting

De effectiviteit van het script komt voort uit een meerlaagse beveiligingsstrategie:

1.  **🔍 Scan & Ruim op:** Het controleert en verwijdert eerst alle bestaande `Gallery.exe`-bestanden op de doellocaties, wat zorgt voor een schone lei.
2.  **📝 Creëer het Lokaas:** Er wordt een leeg 0-byte bestand genaamd `Gallery.exe` gemaakt. Het is onschadelijk en neemt geen ruimte in beslag.
3.  **🛡️ Bouw de Vesting (ACL-Verharding):** Dit is de meest kritieke stap. Het script wijzigt de Toegangscontrolelijst (ACL) van het bestand:
    *   **Blokkeert Overerving:** Het voorkomt dat het bestand machtigingen erft van de bovenliggende map. Dit isoleert het van eventuele toekomstige beveiligingswijzigingen.
    *   **Weigert Iedereen:** Het voegt een expliciete `Deny FullControl`-regel toe voor de `Everyone`-groep. In Windows overschrijft een expliciete `Deny`-regel altijd alle `Allow`-regels. Dit betekent dat geen enkele gebruiker, **zelfs geen Beheerder**, het bestand kan schrijven, wijzigen of verwijderen.
    *   **Verleent Controle aan SYSTEM:** Het zorgt ervoor dat alleen het `NT AUTHORITY\SYSTEM`- of `TrustedInstaller`-account `FullControl` heeft. Dit is noodzakelijk voor de systeemintegriteit, maar het is een account dat malware (en gebruikers) niet gemakkelijk kunnen gebruiken.
4.  **👻 Ga Onzichtbaar:** Ten slotte stelt het de bestandsattributen in op `Verborgen` en `Systeem`, waardoor het wordt verborgen in de standaardweergave in Verkenner om onbedoelde ontdekking of sabotage te voorkomen.

---

## ⚠️ Belangrijke Waarschuwingen & Hoe Ongedaan te Maken

> [!WARNING]
> **Dit script maakt een bestand dat *opzettelijk* moeilijk te verwijderen is, zelfs voor jou.** Voer dit niet uit op een bestand waartoe je later mogelijk toegang nodig hebt. Het is specifiek ontworpen om bekende malwarepaden te blokkeren.

### Hoe een Vergrendeld Lokaasbestand Handmatig te Verwijderen

Als je ooit de lokazen moet verwijderen, moet je de bescherming handmatig ongedaan maken als **Beheerder**.

1.  **Open een Beheerdersterminal** (`Win + X` > Terminal (Admin)).
2.  **Neem Eigendom** van het bestand. Vervang het pad door het juiste.
    *Voor het gebruikersbestand:*
    ```cmd
    takeown /f "%APPDATA%\Gallery.exe"
    ```
    *Voor het systeembestand:*
    ```cmd
    takeown /f "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe"
    ```
3.  **Reset Machtigingen** om te erven van de bovenliggende map.
    *Voor het gebruikersbestand:*
    ```cmd
    icacls "%APPDATA%\Gallery.exe" /reset
    ```
    *Voor het systeembestand:*
    ```cmd
    icacls "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe" /reset
    ```
4.  Je kunt nu het bestand normaal **verwijderen**.
    ```powershell
    Remove-Item -Path "$env:APPDATA\Gallery.exe" -Force
    ```

---

## 🔎 Probleemoplossing & Veelgestelde Vragen

| Symptoom / Vraag | Oplossing / Uitleg |
| :--- | :--- |
| ❌ **"Toegang geweigerd"-fout tijdens scriptuitvoering.** | Dit is te verwachten als je het als Beheerder uitvoert in plaats van als SYSTEM. Het script kan `SYSTEM` niet als eigenaar instellen. **Gebruik de PsExec-methode voor volledige bescherming.** |
| 📜 **"Het uitvoeren van scripts is uitgeschakeld op dit systeem."-fout.** | Dit is een PowerShell Uitvoeringsbeleid-fout. Je kunt dit omzeilen voor het huidige proces door `Set-ExecutionPolicy Bypass -Scope Process -Force` uit te voeren voordat je het hoofdscript uitvoert. |
| 🪟 **Ik kan het `Gallery.exe`-bestand niet zien in Verkenner.** | Dit is de bedoeling. Het bestand is verborgen. Om het te bekijken, ga naar Verkenner > `Beeld` > `Opties` > tabblad `Weergave`, en vink **"Verborgen bestanden weergeven..."** aan en vink **"Beveiligde besturingssysteembestanden verbergen"** uit. |
| 🗑️ **Ik kan het bestand niet verwijderen, zelfs niet als Beheerder!** | Dit betekent dat het script correct werkt! Het is ontworpen om iedereen te blokkeren, inclusief jou. Volg de stappen in de sectie **[Hoe Ongedaan te Maken](#️-belangrijke-waarschuwingen--hoe-ongedaan-te-maken)** om het te verwijderen. |
| 🤔 **Waarom is het zo belangrijk om als `SYSTEM` uit te voeren?** | Het `SYSTEM`-account is de ultieme autoriteit op Windows. Door `SYSTEM` eigenaar te maken van het lokaas, wordt voorkomen dat zelfs een Beheerder het gemakkelijk kan wijzigen zonder eerst expliciet eigendom te nemen. Malware die met beheerdersrechten draait, wordt geblokkeerd, wat een enorme beveiligingsoverwinning is. |

---

## 📜 Licentie

Dit project is open-source en wordt gedistribueerd onder de [MIT-licentie](https://github.com/i-am-aka/readme-assets/blob/main/LICENSE). Je bent vrij om het te gebruiken, te delen en te wijzigen.

---

## 📥 Download de Originele README

```bash
curl -o README.md https://raw.githubusercontent.com/i-am-aka/Gallery-Lock/main/README.md
```
