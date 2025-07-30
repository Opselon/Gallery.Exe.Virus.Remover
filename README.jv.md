# 🛡️ Galeri-Kunci: Pancingan sing Ora Bisa Dirusak

<p align="center">
  <strong>Skrip PowerShell "setel-lan-lali" sing nggawe alangan dalan sing permanen lan ora bisa dirusak kanggo mblokir malware <code>Gallery.exe</code> lan nyegah infeksi maneh.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-5.1+-blue.svg" alt="Versi PowerShell">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="Lisensi">
  <img src="https://img.shields.io/badge/Platform-Windows-lightgrey.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Status-Active-brightgreen.svg" alt="Status">
</p>

---

## Masalah: Virus `Gallery.exe` sing Ngganggu

Apa sampeyan bosen mbusak malware `Gallery.exe`, mung kanggo katon maneh sawise urip maneh? Virus umum iki kerjane kanthi nyelehake file sing bisa dieksekusi ing folder pangguna lan sistem tartamtu. Sanajan sawise ngresiki sistem sampeyan, asring bali amarga sumber infeksi asli (kayata tugas sing dijadwalake utawa proses sing didhelikake liyane) nyoba nggawe maneh.

## Solusi: Benteng Digital

**Galeri-Kunci** ora mung mbusak virus; nggawe bèntèng permanen ing panggonane. Skrip kasebut nggawe file pancingan nol-byte (kosong) kanthi jeneng `Gallery.exe` ing lokasi sing pas sing ditargetake malware. Banjur ngetrapake ijin keamanan (ACL) sing ketat banget sing nggawe pancingan kasebut **ora mungkin ditimpa utawa dibusak dening malware**.

Hasile? Upaya malware kanggo nginfeksi maneh sistem sampeyan diblokir ing tingkat sistem operasi, saben wektu.

---

## 🚀 Fitur Utama

| Fitur | Deskripsi |
| :--- | :--- |
| ✅ **Mbrastha Infèksi sing Ana** | Kanthi otomatis nemokake lan mbusak file `Gallery.exe` saiki saka lokasi malware sing dikenal. |
| 🛡️ **Nggawe Pancingan sing Ora Bisa Diowahi** | Ngasilake file placeholder kosong lan ngunci. |
| 🔒 **Pengerasan ACL Lanjut** | Nggunakake Dhaptar Kontrol Akses (ACL) kanggo `NOLAK` kabeh ijin kanggo kabeh wong, kalebu Administrator. Mung akun inti `SYSTEM` sing nahan kontrol. |
| 🕵️ **Siluman & Ora Katon** | File pancingan disetel minangka file `Didhelikake` lan `Sistem`, dadi ora katon sajrone panggunaan normal. |
| 📈 **Logging sing Cetha & Informatif** | Nyedhiyakake umpan balik wektu nyata kanthi kode warna ing konsol kanggo saben tumindak sing ditindakake. |
| 📦 **Nol Dependensi** | Skrip PowerShell mandiri sing mlaku ing sistem Windows modern tanpa mbutuhake instalasi tambahan. |

---

## 🛠️ Cara Nggunakake: Pandhuan 2 Menit

Kanggo efektifitas maksimal, skrip kudu dilakokno minangka `SYSTEM`. Iki minangka tingkat wewenang paling dhuwur ing Windows, malah ing ndhuwur Administrator.

### Metode sing Disaranake: Jalanake minangka SYSTEM karo PsExec

Iki minangka **cara paling aman** lan njamin skrip bisa ngetrapake proteksi sing paling kuat.

1.  **Ngundhuh PsExec:**
    *   Ngundhuh **Sysinternals Suite** resmi saka Microsoft: [**Ngundhuh Kene**](https://learn.microsoft.com/en-us/sysinternals/downloads/psexec).
    *   Ekstrak file ZIP menyang lokasi sing prasaja, kayata `C:\Sysinternals`.

2.  **Mbukak Terminal Administrator:**
    *   Pencet `Win + X` banjur pilih **Terminal (Admin)** utawa **Windows PowerShell (Admin)**.

3.  **Navigasi menyang Folder PsExec:**
    *   Ing terminal, pindhah menyang direktori ngendi sampeyan ngekstrak PsExec.
      ```powershell
      cd C:\Sysinternals
      ```

4.  **Miwiti PowerShell Tingkat SISTEM:**
    *   Jalanake printah ing ngisor iki. Jendhela PowerShell anyar bakal mbukak kanthi hak istimewa `SYSTEM`.
      ```powershell
      .\PsExec64.exe -i -s powershell.exe
      ```

5.  **Jalanake Skrip Galeri-Kunci:**
    *   Ing **jendhela SISTEM anyar**, navigasi menyang ngendi sampeyan nyimpen `Gallery-Lock.ps1`.
    *   Pisanan, setel kabijakan eksekusi kanggo sesi siji iki, banjur jalanake skrip kasebut.
      ```powershell
      # Ngidini skrip mlaku mung ing jendhela iki
      Set-ExecutionPolicy Bypass -Scope Process -Force

      # Jalanake skrip (gunakake path sing bener)
      .\Gallery-Lock.ps1
      ```

**Mekaten!** File pancingan saiki wis ana lan dikerasake. Sampeyan bisa nutup kabeh jendhela.

<details>
  <summary><strong>Metode Alternatif: Jalanake minangka Administrator (Kurang Aman)</strong></summary>

  > [!NOTE]
  > Cara iki bisa digunakake, nanging proteksi file ora kuwat amarga Administrator isih bisa njupuk kepemilikan kanthi luwih gampang. Iki mung disaranake yen sampeyan ora bisa nggunakake PsExec.

  1. **Klik-tengen** ing file skrip `Gallery-Lock.ps1`.
  2. Pilih **"Jalanake karo PowerShell"**.
  3. Yen dijaluk, setujoni pituduh UAC (Kontrol Akun Pangguna) kanggo menehi hak administrator.

  Skrip kasebut bakal menehi notifikasi yen lagi mlaku minangka Administrator lan dudu SISTEM.
</details>

---

## 🗺️ Lokasi File sing Dilindhungi

Skrip nggawe lan nglindhungi pancingan ing path malware standar ing ngisor iki:

| Jinis Profil | Path |
| :--- | :--- |
| **Profil Pangguna** | `%APPDATA%\Gallery.exe` |
| **Profil Sistem** | `C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe` |

---

## 🧱 Cara Kerjane: Rincian Teknis

Efektivitas skrip kasebut asale saka strategi keamanan multi-lapisan:

1.  **🔍 Pindai & Resik:** Pisanan mriksa lan mbusak file `Gallery.exe` sing ana ing lokasi target, kanggo mesthekake kahanan sing resik.
2.  **📝 Nggawe Pancingan:** File kosong 0-byte kanthi jeneng `Gallery.exe` digawe. Iku ora mbebayani lan ora njupuk papan.
3.  **🛡️ Mbangun Benteng (Pengerasan ACL):** Iki minangka langkah sing paling kritis. Skrip kasebut ngowahi Dhaptar Kontrol Akses (ACL) file:
    *   **Mblokir Warisan:** Iki nyegah file kasebut marisi ijin saka folder induk. Iki ngisolasi saka owah-owahan keamanan ing mangsa ngarep.
    *   **Nolak Kabeh Wong:** Iki nambahake aturan `Deny FullControl` sing jelas kanggo grup `Everyone`. Ing Windows, aturan `Deny` sing jelas mesthi ngalahake aturan `Allow`. Iki tegese ora ana pangguna, **sanajan Administrator**, sing bisa nulis, ngowahi, utawa mbusak file kasebut.
    *   **Menehi Kontrol menyang SISTEM:** Iki mesthekake yen mung akun `NT AUTHORITY\SYSTEM` utawa `TrustedInstaller` sing duwe `FullControl`. Iki perlu kanggo integritas sistem nanging minangka akun sing ora bisa digunakake kanthi gampang dening malware (lan pangguna).
4.  **👻 Dadi Ora Katon:** Pungkasan, nyetel atribut file dadi `Didhelikake` lan `Sistem`, ndhelikake saka tampilan standar ing File Explorer kanggo nyegah panemuan utawa tampering sing ora disengaja.

---

## ⚠️ Pènget Penting & Cara Mbalekake

> [!WARNING]
> **Skrip iki nggawe file sing *sengaja* angel dibusak, sanajan kanggo sampeyan.** Aja mbukak iki ing file apa wae sing sampeyan butuhake akses mengko. Iki dirancang khusus kanggo mblokir path malware sing dikenal.

### Cara Mbusak File Pancingan sing Dikunci Kanthi Manual

Yen sampeyan perlu mbusak pancingan, sampeyan kudu mbalikke proteksi kanthi manual minangka **Administrator**.

1.  **Mbukak Terminal Administrator** (`Win + X` > Terminal (Admin)).
2.  **Jupuk Kepemilikan** file kasebut. Ganti path karo sing bener.
    *Kanggo file pangguna:*
    ```cmd
    takeown /f "%APPDATA%\Gallery.exe"
    ```
    *Kanggo file sistem:*
    ```cmd
    takeown /f "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe"
    ```
3.  **Reset Ijin** kanggo marisi saka folder induk.
    *Kanggo file pangguna:*
    ```cmd
    icacls "%APPDATA%\Gallery.exe" /reset
    ```
    *Kanggo file sistem:*
    ```cmd
    icacls "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe" /reset
    ```
4.  Sampeyan saiki bisa **mbusak file** kanthi normal.
    ```powershell
    Remove-Item -Path "$env:APPDATA\Gallery.exe" -Force
    ```

---

## 🔎 Ngatasi Masalah & Pitakonan sing Sering Ditakokake

| Gejala / Pitakonan | Solusi / Panjelasan |
| :--- | :--- |
| ❌ **Kesalahan "Akses ditolak" sajrone eksekusi skrip.** | Iki dikarepake yen sampeyan mlaku minangka Administrator tinimbang SISTEM. Skrip kasebut ora bisa nyetel `SYSTEM` minangka pemilik. **Gunakake metode PsExec kanggo proteksi lengkap.** |
| 📜 **Kesalahan "Njalankake skrip dipatèni ing sistem iki".** | Iki minangka kesalahan Kebijakan Eksekusi PowerShell. Sampeyan bisa ngliwati kanggo proses saiki kanthi mbukak `Set-ExecutionPolicy Bypass -Scope Process -Force` sadurunge mbukak skrip utama. |
| 🪟 **Aku ora bisa ndeleng file `Gallery.exe` ing File Explorer.** | Iki disengaja. File kasebut didhelikake. Kanggo ndeleng, pindhah menyang File Explorer > `Deleng` > `Pilihan` > tab `Deleng`, lan priksa **"Tampilake file sing didhelikake..."** lan busak centhang **"Ndhelikake file sistem operasi sing dilindhungi"**. |
| 🗑️ **Aku ora bisa mbusak file, sanajan minangka Admin!** | Iki tegese skrip kasebut mlaku kanthi bener! Iki dirancang kanggo mblokir kabeh wong, kalebu sampeyan. Tindakake langkah-langkah ing bagean **[Cara Mbalekake](#️-pènget-penting--cara-mbalekake)** kanggo mbusak. |
| 🤔 **Napa penting banget kanggo mbukak minangka `SYSTEM`?** | Akun `SYSTEM` minangka wewenang paling dhuwur ing Windows. Kanthi nggawe `SYSTEM` dadi pemilik pancingan, iki nyegah sanajan Administrator ngowahi kanthi gampang tanpa njupuk kepemilikan kanthi jelas dhisik. Malware sing mlaku kanthi hak admin bakal diblokir, sing dadi kemenangan keamanan gedhe. |

---

## 📜 Lisensi

Proyek iki open-source lan disebarake miturut [Lisensi MIT](https://github.com/i-am-aka/readme-assets/blob/main/LICENSE). Sampeyan bebas nggunakake, nuduhake, lan ngowahi.

---

## 📥 Ngundhuh README Asli

```bash
curl -o README.md https://raw.githubusercontent.com/i-am-aka/Gallery-Lock/main/README.md
```
