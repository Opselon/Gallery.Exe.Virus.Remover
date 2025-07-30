# 🛡️ Gallery-Lock: L'Esca Indistruttibile

<p align="center">
  <strong>Uno script PowerShell "imposta e dimentica" che crea un blocco stradale permanente e indistruttibile per bloccare il malware <code>Gallery.exe</code> e prevenire la reinfezione.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-5.1+-blue.svg" alt="Versione PowerShell">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="Licenza">
  <img src="https://img.shields.io/badge/Platform-Windows-lightgrey.svg" alt="Piattaforma">
  <img src="https://img.shields.io/badge/Status-Active-brightgreen.svg" alt="Stato">
</p>

---

## Il Problema: Il Fastidioso Virus `Gallery.exe`

Sei stanco di rimuovere il malware `Gallery.exe`, solo per vederlo riapparire dopo un riavvio? Questo virus comune funziona inserendo il suo eseguibile in cartelle specifiche dell'utente e di sistema. Anche dopo aver pulito il sistema, spesso ritorna perché la fonte di infezione originale (come un'attività pianificata o un altro processo nascosto) tenta di ricrearlo.

## La Soluzione: Una Fortezza Digitale

**Gallery-Lock** non si limita a eliminare il virus; costruisce una fortezza permanente al suo posto. Lo script crea file esca a zero byte (vuoti) chiamati `Gallery.exe` nelle posizioni esatte prese di mira dal malware. Applica quindi autorizzazioni di sicurezza (ACL) estremamente rigide che rendono queste esche **impossibili da sovrascrivere o eliminare per il malware**.

Il risultato? Il tentativo del malware di reinfettare il sistema viene bloccato a livello di sistema operativo, ogni singola volta.

---

## 🚀 Caratteristiche Principali

| Caratteristica | Descrizione |
| :--- | :--- |
| ✅ **Eradica le Infezioni Esistenti** | Trova ed elimina automaticamente qualsiasi file `Gallery.exe` corrente dalle posizioni note del malware. |
| 🛡️ **Crea Esche Immobili** | Genera file segnaposto vuoti e li blocca. |
| 🔒 **Rinforzo ACL Avanzato** | Utilizza elenchi di controllo di accesso (ACL) per `NEGARE` tutte le autorizzazioni a tutti, inclusi gli amministratori. Solo l'account `SYSTEM` principale mantiene il controllo. |
| 🕵️ **Furtivo e Invisibile** | I file esca sono impostati come file `nascosti` e di `sistema`, rendendoli invisibili durante il normale utilizzo. |
| 📈 **Registrazione Chiara e Informativa** | Fornisce un feedback in tempo reale e con codice colore nella console for ogni azione intrapresa. |
| 📦 **Zero Dipendenze** | Uno script PowerShell autonomo che funziona su qualsiasi sistema Windows moderno senza bisogno di installazioni aggiuntive. |

---

## 🛠️ Come Usare: La Guida di 2 Minuti

Per la massima efficacia, lo script deve essere eseguito come `SYSTEM`. Questo è il livello di autorità più alto su Windows, anche al di sopra dell'amministratore.

### Metodo Consigliato: Esegui come SYSTEM con PsExec

Questo è il **metodo più sicuro** e garantisce che lo script possa applicare le sue protezioni più forti.

1.  **Scarica PsExec:**
    *   Scarica la **Suite Sysinternals** ufficiale da Microsoft: [**Scarica Qui**](https://learn.microsoft.com/en-us/sysinternals/downloads/psexec).
    *   Estrai il file ZIP in una posizione semplice, come `C:\Sysinternals`.

2.  **Apri un Terminale da Amministratore:**
    *   Premi `Win + X` e seleziona **Terminale (Admin)** o **Windows PowerShell (Admin)**.

3.  **Vai alla Cartella di PsExec:**
    *   Nel terminale, vai alla directory in cui hai estratto PsExec.
      ```powershell
      cd C:\Sysinternals
      ```

4.  **Avvia una PowerShell a Livello di SYSTEM:**
    *   Esegui il seguente comando. Si aprirà una nuova finestra di PowerShell con i privilegi di `SYSTEM`.
      ```powershell
      .\PsExec64.exe -i -s powershell.exe
      ```

5.  **Esegui lo Script Gallery-Lock:**
    *   Nella **nuova finestra di SYSTEM**, vai a dove hai salvato `Gallery-Lock.ps1`.
    *   Innanzitutto, imposta la politica di esecuzione per questa singola sessione, quindi esegui lo script.
      ```powershell
      # Consenti l'esecuzione dello script solo in questa finestra
      Set-ExecutionPolicy Bypass -Scope Process -Force

      # Esegui lo script (usa il percorso corretto)
      .\Gallery-Lock.ps1
      ```

**Ecco fatto!** I file esca sono ora al loro posto e rinforzati. Puoi chiudere tutte le finestre.

<details>
  <summary><strong>Metodo Alternativo: Esegui come Amministratore (Meno Sicuro)</strong></summary>

  > [!NOTE]
  > Questo metodo funziona, ma la protezione dei file non è altrettanto forte perché un amministratore può comunque prenderne possesso più facilmente. È consigliato solo se non puoi usare PsExec.

  1. **Fai clic con il pulsante destro del mouse** sul file dello script `Gallery-Lock.ps1`.
  2. Seleziona **"Esegui con PowerShell"**.
  3. Se richiesto, approva la richiesta UAC (Controllo Account Utente) per concedergli i diritti di amministratore.

  Lo script ti avviserà che è in esecuzione come amministratore e non come SYSTEM.
</details>

---

## 🗺️ Posizioni dei File Protetti

Lo script crea e protegge esche nei seguenti percorsi malware standard:

| Tipo di Profilo | Percorso |
| :--- | :--- |
| **Profilo Utente** | `%APPDATA%\Gallery.exe` |
| **Profilo di Sistema** | `C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe` |

---

## 🧱 Come Funziona: Un'Analisi Tecnica

L'efficacia dello script deriva da una strategia di sicurezza a più livelli:

1.  **🔍 Scansiona e Pulisci:** Per prima cosa controlla ed elimina eventuali file `Gallery.exe` esistenti nelle posizioni di destinazione, garantendo una tabula rasa.
2.  **📝 Crea l'Esca:** Viene creato un file vuoto da 0 byte chiamato `Gallery.exe`. È innocuo e non occupa spazio.
3.  **🛡️ Costruisci la Fortezza (Rinforzo ACL):** Questo è il passaggio più critico. Lo script modifica l'Elenco di Controllo di Accesso (ACL) del file:
    *   **Blocca l'Ereditarietà:** Impedisce al file di ereditare le autorizzazioni dalla sua cartella principale. Questo lo isola da eventuali future modifiche alla sicurezza.
    *   **Nega a Tutti:** Aggiunge una regola esplicita `Deny FullControl` per il gruppo `Everyone`. In Windows, una regola esplicita `Deny` prevale sempre su qualsiasi regola `Allow`. Ciò significa che nessun utente, **nemmeno un amministratore**, può scrivere, modificare o eliminare il file.
    *   **Concede il Controllo a SYSTEM:** Assicura che solo l'account `NT AUTHORITY\SYSTEM` o `TrustedInstaller` abbia `FullControl`. Ciò è necessario per l'integrità del sistema ma è un account che malware (e utenti) non possono usare facilmente.
4.  **👻 Diventa Invisibile:** Infine, imposta gli attributi del file su `Nascosto` e `Sistema`, nascondendolo dalla visualizzazione standard in Esplora File per prevenire scoperte o manomissioni accidentali.

---

## ⚠️ Avvertenze Importanti e Come Annullare

> [!WARNING]
> **Questo script crea un file che è *intenzionalmente* difficile da rimuovere, anche per te.** Non eseguire questo script su alcun file a cui potresti dover accedere in seguito. È progettato specificamente per bloccare percorsi malware noti.

### Come Rimuovere Manualmente un File Esca Bloccato

Se mai avessi bisogno di rimuovere le esche, devi invertire manualmente la protezione come **Amministratore**.

1.  **Apri un Terminale da Amministratore** (`Win + X` > Terminale (Admin)).
2.  **Prendi Possesso** del file. Sostituisci il percorso con quello corretto.
    *Per il file utente:*
    ```cmd
    takeown /f "%APPDATA%\Gallery.exe"
    ```
    *Per il file di sistema:*
    ```cmd
    takeown /f "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe"
    ```
3.  **Reimposta le Autorizzazioni** per ereditare dalla cartella principale.
    *Per il file utente:*
    ```cmd
    icacls "%APPDATA%\Gallery.exe" /reset
    ```
    *Per il file di sistema:*
    ```cmd
    icacls "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe" /reset
    ```
4.  Ora puoi **eliminare il file** normalmente.
    ```powershell
    Remove-Item -Path "$env:APPDATA\Gallery.exe" -Force
    ```

---

## 🔎 Risoluzione dei Problemi e Domande Frequenti

| Sintomo / Domanda | Soluzione / Spiegazione |
| :--- | :--- |
| ❌ **Errore "Accesso negato" durante l'esecuzione dello script.** | Questo è previsto se lo si esegue come amministratore anziché come SYSTEM. Lo script non può impostare `SYSTEM` come proprietario. **Usa il metodo PsExec per una protezione completa.** |
| 📜 **Errore "L'esecuzione di script è disabilitata su questo sistema".** | Questo è un errore di Criterio di Esecuzione di PowerShell. Puoi aggirarlo per il processo corrente eseguendo `Set-ExecutionPolicy Bypass -Scope Process -Force` prima di eseguire lo script principale. |
| 🪟 **Non riesco a vedere il file `Gallery.exe` in Esplora File.** | Questo è intenzionale. Il file è nascosto. Per visualizzarlo, vai su Esplora File > `Visualizza` > `Opzioni` > scheda `Visualizzazione`, e seleziona **"Mostra file nascosti..."** e deseleziona **"Nascondi i file protetti di sistema"**. |
| 🗑️ **Non riesco a eliminare il file, nemmeno come amministratore!** | Questo significa che lo script funziona correttamente! È progettato per bloccare tutti, te compreso. Segui i passaggi nella sezione **[Come Annullare](#️-avvertenze-importanti-e-come-annullare)** per rimuoverlo. |
| 🤔 **Perché è così importante eseguire come `SYSTEM`?** | L'account `SYSTEM` è l'autorità suprema su Windows. Rendendo `SYSTEM` il proprietario dell'esca, si impedisce anche a un amministratore di modificarla facilmente senza prima prenderne esplicitamente possesso. Il malware in esecuzione con diritti di amministratore verrà bloccato, il che è un'enorme vittoria per la sicurezza. |

---

## 📜 Licenza

Questo progetto è open source e distribuito sotto la [Licenza MIT](https://github.com/i-am-aka/readme-assets/blob/main/LICENSE). Sei libero di usarlo, condividerlo e modificarlo.

---

## 📥 Scarica il README Originale

```bash
curl -o README.md https://raw.githubusercontent.com/i-am-aka/Gallery-Lock/main/README.md
```
