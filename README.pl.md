# 🛡️ Galeria-Blokada: Niezniszczalna Przynęta

<p align="center">
  <strong>Skrypt PowerShell "ustaw i zapomnij", który tworzy stałą, niezniszczalną blokadę drogową, aby zablokować złośliwe oprogramowanie <code>Gallery.exe</code> i zapobiec ponownej infekcji.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-5.1+-blue.svg" alt="Wersja PowerShell">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="Licencja">
  <img src="https://img.shields.io/badge/Platform-Windows-lightgrey.svg" alt="Platforma">
  <img src="https://img.shields.io/badge/Status-Active-brightgreen.svg" alt="Status">
</p>

---

## Problem: Irytujący Wirus `Gallery.exe`

Czy jesteś zmęczony usuwaniem złośliwego oprogramowania `Gallery.exe`, tylko po to, by pojawiło się ono ponownie po ponownym uruchomieniu? Ten powszechny wirus działa poprzez umieszczanie swojego pliku wykonywalnego w określonych folderach użytkownika i systemowych. Nawet po wyczyszczeniu systemu, często powraca, ponieważ oryginalne źródło infekcji (takie jak zaplanowane zadanie lub inny ukryty proces) próbuje go odtworzyć.

## Rozwiązanie: Cyfrowa Twierdza

**Galeria-Blokada** nie tylko usuwa wirusa; buduje na jego miejscu stałą twierdzę. Skrypt tworzy pliki-przynęty o zerowej wielkości (puste) o nazwie `Gallery.exe` w dokładnych lokalizacjach, na które celuje złośliwe oprogramowanie. Następnie stosuje niezwykle rygorystyczne uprawnienia bezpieczeństwa (ACL), które sprawiają, że te przynęty są **niemożliwe do nadpisania lub usunięcia przez złośliwe oprogramowanie**.

Wynik? Próba ponownego zainfekowania systemu przez złośliwe oprogramowanie jest blokowana na poziomie systemu operacyjnego, za każdym razem.

---

## 🚀 Kluczowe Funkcje

| Funkcja | Opis |
| :--- | :--- |
| ✅ **Eliminuje Istniejące Infekcje** | Automatycznie znajduje i usuwa wszelkie bieżące pliki `Gallery.exe` ze znanych lokalizacji złośliwego oprogramowania. |
| 🛡️ **Tworzy Niezmienne Przynęty** | Generuje puste pliki zastępcze i blokuje je. |
| 🔒 **Zaawansowane Wzmacnianie ACL** | Używa list kontroli dostępu (ACL) do `ODMAWIANIA` wszystkich uprawnień wszystkim, w tym administratorom. Tylko podstawowe konto `SYSTEM` zachowuje kontrolę. |
| 🕵️ **Ukryty i Niewidoczny** | Pliki-przynęty są ustawiane jako pliki `Ukryte` i `Systemowe`, co czyni je niewidocznymi podczas normalnego użytkowania. |
| 📈 **Jasne i Informacyjne Logowanie** | Zapewnia kolorowe, bieżące informacje zwrotne w konsoli dla każdej podjętej akcji. |
| 📦 **Zero Zależności** | Samodzielny skrypt PowerShell, który działa na każdym nowoczesnym systemie Windows bez potrzeby dodatkowych instalacji. |

---

## 🛠️ Jak Używać: 2-minutowy Przewodnik

Dla maksymalnej skuteczności skrypt musi być uruchomiony jako `SYSTEM`. Jest to najwyższy poziom uprawnień w systemie Windows, nawet wyższy niż Administrator.

### Zalecana Metoda: Uruchom jako SYSTEM za pomocą PsExec

Jest to **najbezpieczniejsza metoda** i gwarantuje, że skrypt może zastosować swoje najsilniejsze zabezpieczenia.

1.  **Pobierz PsExec:**
    *   Pobierz oficjalny **Sysinternals Suite** od firmy Microsoft: [**Pobierz Tutaj**](https://learn.microsoft.com/en-us/sysinternals/downloads/psexec).
    *   Wypakuj plik ZIP do prostej lokalizacji, takiej jak `C:\Sysinternals`.

2.  **Otwórz Terminal Administratora:**
    *   Naciśnij `Win + X` i wybierz **Terminal (Admin)** lub **Windows PowerShell (Admin)**.

3.  **Przejdź do Folderu PsExec:**
    *   W terminalu przejdź do katalogu, w którym wypakowałeś PsExec.
      ```powershell
      cd C:\Sysinternals
      ```

4.  **Uruchom PowerShell na Poziomie SYSTEM:**
    *   Uruchom następujące polecenie. Otworzy się nowe okno PowerShell z uprawnieniami `SYSTEM`.
      ```powershell
      .\PsExec64.exe -i -s powershell.exe
      ```

5.  **Uruchom Skrypt Galeria-Blokada:**
    *   W **nowym oknie SYSTEM**, przejdź do miejsca, w którym zapisałeś `Gallery-Lock.ps1`.
    *   Najpierw ustaw politykę wykonywania dla tej pojedynczej sesji, a następnie uruchom skrypt.
      ```powershell
      # Zezwalaj na uruchamianie skryptu tylko w tym oknie
      Set-ExecutionPolicy Bypass -Scope Process -Force

      # Uruchom skrypt (użyj poprawnej ścieżki)
      .\Gallery-Lock.ps1
      ```

**To wszystko!** Pliki-przynęty są teraz na miejscu i wzmocnione. Możesz zamknąć wszystkie okna.

<details>
  <summary><strong>Alternatywna Metoda: Uruchom jako Administrator (Mniej Bezpieczna)</strong></summary>

  > [!NOTE]
  > Ta metoda działa, ale ochrona plików nie jest tak silna, ponieważ Administrator może łatwiej przejąć własność. Jest zalecana tylko wtedy, gdy nie możesz użyć PsExec.

  1. **Kliknij prawym przyciskiem myszy** na plik skryptu `Gallery-Lock.ps1`.
  2. Wybierz **"Uruchom za pomocą PowerShell"**.
  3. Jeśli zostaniesz o to poproszony, zatwierdź monit UAC (Kontrola konta użytkownika), aby przyznać mu uprawnienia administratora.

  Skrypt poinformuje Cię, że działa jako Administrator, a nie SYSTEM.
</details>

---

## 🗺️ Chronione Lokalizacje Plików

Skrypt tworzy i chroni przynęty w następujących standardowych ścieżkach złośliwego oprogramowania:

| Typ Profilu | Ścieżka |
| :--- | :--- |
| **Profil Użytkownika** | `%APPDATA%\Gallery.exe` |
| **Profil Systemowy** | `C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe` |

---

## 🧱 Jak To Działa: Analiza Techniczna

Skuteczność skryptu wynika z wielowarstwowej strategii bezpieczeństwa:

1.  **🔍 Skanuj i Czyść:** Najpierw sprawdza i usuwa wszelkie istniejące pliki `Gallery.exe` w docelowych lokalizacjach, zapewniając czysty start.
2.  **📝 Utwórz Przynętę:** Tworzony jest pusty plik o wielkości 0 bajtów o nazwie `Gallery.exe`. Jest nieszkodliwy i не занимает места.
3.  **🛡️ Zbuduj Twierdzę (Wzmacnianie ACL):** To jest najważniejszy krok. Skrypt modyfikuje listę kontroli dostępu (ACL) pliku:
    *   **Blokuje Dziedziczenie:** Zapobiega dziedziczeniu uprawnień przez plik z folderu nadrzędnego. Izoluje to go od wszelkich przyszłych zmian w zabezpieczeniach.
    *   **Odmów Wszystkim:** Dodaje jawną regułę `Deny FullControl` dla grupy `Wszyscy`. W systemie Windows jawna reguła `Deny` zawsze ma pierwszeństwo przed wszelkimi regułami `Allow`. Oznacza to, że żaden użytkownik, **nawet Administrator**, nie może pisać, modyfikować ani usuwać pliku.
    *   **Przyznaj Kontrolę SYSTEMOWI:** Zapewnia, że tylko konto `NT AUTHORITY\SYSTEM` lub `TrustedInstaller` ma `FullControl`. Jest to konieczne dla integralności systemu, ale jest to konto, którego złośliwe oprogramowanie (i użytkownicy) не могут легко использовать.
4.  **👻 Stań się Niewidzialny:** Na koniec ustawia atrybuty pliku na `Ukryty` i `Systemowy`, ukrywając go przed standardowym widokiem w Eksploratorze plików, aby zapobiec przypadkowemu odkryciu lub manipulacji.

---

## ⚠️ Ważne Ostrzeżenia i Jak Cofnąć

> [!WARNING]
> **Ten skrypt tworzy plik, który jest *celowo* trudny do usunięcia, nawet dla Ciebie.** Nie uruchamiaj tego na żadnym pliku, do którego możesz potrzebować dostępu później. Jest specjalnie zaprojektowany do blokowania znanych ścieżek złośliwego oprogramowania.

### Jak Ręcznie Usunąć Zablokowany Plik-Przynętę

Jeśli kiedykolwiek będziesz musiał usunąć przynęty, musisz ręcznie odwrócić ochronę jako **Administrator**.

1.  **Otwórz Terminal Administratora** (`Win + X` > Terminal (Admin)).
2.  **Przejmij Własność** pliku. Zastąp ścieżkę poprawną.
    *Dla pliku użytkownika:*
    ```cmd
    takeown /f "%APPDATA%\Gallery.exe"
    ```
    *Dla pliku systemowego:*
    ```cmd
    takeown /f "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe"
    ```
3.  **Zresetuj Uprawnienia**, aby dziedziczyły z folderu nadrzędnego.
    *Dla pliku użytkownika:*
    ```cmd
    icacls "%APPDATA%\Gallery.exe" /reset
    ```
    *Dla pliku systemowego:*
    ```cmd
    icacls "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe" /reset
    ```
4.  Teraz możesz normalnie **usunąć plik**.
    ```powershell
    Remove-Item -Path "$env:APPDATA\Gallery.exe" -Force
    ```

---

## 🔎 Rozwiązywanie Problemów i Często Zadawane Pytania

| Objaw / Pytanie | Rozwiązanie / Wyjaśnienie |
| :--- | :--- |
| ❌ **Błąd "Odmowa dostępu" podczas wykonywania skryptu.** | Jest to oczekiwane, jeśli uruchamiasz go jako Administrator zamiast SYSTEM. Skrypt nie może ustawić `SYSTEM` jako właściciela. **Użyj metody PsExec dla pełnej ochrony.** |
| 📜 **Błąd "Uruchamianie skryptów jest wyłączone w tym systemie".** | Jest to błąd polityki wykonywania PowerShell. Możesz go ominąć dla bieżącego procesu, uruchamiając `Set-ExecutionPolicy Bypass -Scope Process -Force` przed uruchomieniem głównego skryptu. |
| 🪟 **Nie widzę pliku `Gallery.exe` w Eksploratorze plików.** | To jest celowe. Plik jest ukryty. Aby go zobaczyć, przejdź do Eksploratora plików > `Widok` > `Opcje` > karta `Widok`, i zaznacz **"Pokaż ukryte pliki..."** i odznacz **"Ukryj chronione pliki systemu operacyjnego"**. |
| 🗑️ **Nie mogę usunąć pliku, nawet jako Administrator!** | To oznacza, że skrypt działa poprawnie! Jest zaprojektowany, aby blokować wszystkich, w tym Ciebie. Postępuj zgodnie z krokami w sekcji **[Jak Cofnąć](#️-ważne-ostrzeżenia-i-jak-cofnąć)**, aby go usunąć. |
| 🤔 **Dlaczego tak ważne jest uruchamianie jako `SYSTEM`?** | Konto `SYSTEM` jest ostatecznym autorytetem w systemie Windows. Uczynienie `SYSTEM` właścicielem przynęty zapobiega nawet Administratorowi łatwemu modyfikowaniu go bez uprzedniego jawnego przejęcia własności. Złośliwe oprogramowanie działające z uprawnieniami administratora zostanie zablokowane, co jest ogromnym zwycięstwem w dziedzinie bezpieczeństwa. |

---

## 📜 Licencja

Ten projekt jest open-source i jest dystrybuowany na podstawie [Licencji MIT](https://github.com/i-am-aka/readme-assets/blob/main/LICENSE). Możesz go swobodnie używać, udostępniać i modyfikować.

---

## 📥 Pobierz Oryginalny README

```bash
curl -o README.md https://raw.githubusercontent.com/i-am-aka/Gallery-Lock/main/README.md
```
