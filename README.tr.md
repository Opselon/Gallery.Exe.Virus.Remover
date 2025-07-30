# 🛡️ Galeri Kilidi: Yok Edilemez Yem

<p align="center">
  <strong><code>Gallery.exe</code> kötü amaçlı yazılımını engellemek ve yeniden bulaşmayı önlemek için kalıcı, yok edilemez bir barikat oluşturan "ayarla ve unut" bir PowerShell betiği.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-5.1+-blue.svg" alt="PowerShell Sürümü">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="Lisans">
  <img src="https://img.shields.io/badge/Platform-Windows-lightgrey.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Status-Active-brightgreen.svg" alt="Durum">
</p>

---

## Sorun: Sinir Bozucu `Gallery.exe` Virüsü

`Gallery.exe` kötü amaçlı yazılımını kaldırmaktan bıktınız mı, sadece yeniden başlattıktan sonra tekrar ortaya çıkması için mi? Bu yaygın virüs, yürütülebilir dosyasını belirli kullanıcı ve sistem klasörlerine yerleştirerek çalışır. Sisteminizi temizledikten sonra bile, genellikle geri döner çünkü orijinal enfeksiyon kaynağı (zamanlanmış bir görev veya başka bir gizli işlem gibi) onu yeniden oluşturmaya çalışır.

## Çözüm: Dijital Bir Kale

**Galeri Kilidi** sadece virüsü silmez; yerine kalıcı bir kale inşa eder. Betik, kötü amaçlı yazılımın hedeflediği tam konumlarda `Gallery.exe` adında sıfır baytlık (boş) yem dosyaları oluşturur. Ardından, bu yemlerin kötü amaçlı yazılım tarafından **üzerine yazılmasını veya silinmesini imkansız** kılan son derece katı güvenlik izinleri (ACL'ler) uygular.

Sonuç? Kötü amaçlı yazılımın sisteminize yeniden bulaşma girişimi, işletim sistemi düzeyinde her seferinde engellenir.

---

## 🚀 Temel Özellikler

| Özellik | Açıklama |
| :--- | :--- |
| ✅ **Mevcut Enfeksiyonları Yok Eder** | Bilinen kötü amaçlı yazılım konumlarından mevcut `Gallery.exe` dosyalarını otomatik olarak bulur ve siler. |
| 🛡️ **Değiştirilemez Yemler Oluşturur** | Boş yer tutucu dosyalar oluşturur ve bunları kilitler. |
| 🔒 **Gelişmiş ACL Sertleştirmesi** | Yöneticiler de dahil olmak üzere herkese tüm izinleri `REDDETMEK` için Erişim Kontrol Listeleri (ACL'ler) kullanır. Yalnızca çekirdek `SYSTEM` hesabı kontrolü elinde tutar. |
| 🕵️ **Gizli ve Görünmez** | Yem dosyaları `Gizli` ve `Sistem` dosyaları olarak ayarlanır, bu da onları normal kullanım sırasında görünmez kılar. |
| 📈 **Net ve Bilgilendirici Günlük Kaydı** | Gerçekleştirilen her eylem için konsolda renk kodlu, gerçek zamanlı geri bildirim sağlar. |
| 📦 **Sıfır Bağımlılık** | Ek kurulum gerektirmeden herhangi bir modern Windows sisteminde çalışan bağımsız bir PowerShell betiği. |

---

## 🛠️ Nasıl Kullanılır: 2 Dakikalık Kılavuz

Maksimum etkinlik için, betik `SYSTEM` olarak çalıştırılmalıdır. Bu, Windows'taki en yüksek yetki seviyesidir, hatta Yöneticiden bile yüksektir.

### Önerilen Yöntem: PsExec ile SYSTEM Olarak Çalıştırma

Bu **en güvenli yöntemdir** ve betiğin en güçlü korumalarını uygulayabilmesini garanti eder.

1.  **PsExec'i İndirin:**
    *   Microsoft'tan resmi **Sysinternals Suite**'i indirin: [**Buradan İndirin**](https://learn.microsoft.com/en-us/sysinternals/downloads/psexec).
    *   ZIP dosyasını `C:\Sysinternals` gibi basit bir konuma çıkarın.

2.  **Bir Yönetici Terminali Açın:**
    *   `Win + X` tuşlarına basın ve **Terminal (Yönetici)** veya **Windows PowerShell (Yönetici)** seçeneğini belirleyin.

3.  **PsExec Klasörüne Gidin:**
    *   Terminalde, PsExec'i çıkardığınız dizine gidin.
      ```powershell
      cd C:\Sysinternals
      ```

4.  **Bir SYSTEM Düzeyinde PowerShell Başlatın:**
    *   Aşağıdaki komutu çalıştırın. `SYSTEM` ayrıcalıklarına sahip yeni bir PowerShell penceresi açılacaktır.
      ```powershell
      .\PsExec64.exe -i -s powershell.exe
      ```

5.  **Galeri Kilidi Betiğini Çalıştırın:**
    *   **Yeni SYSTEM penceresinde**, `Gallery-Lock.ps1`'i kaydettiğiniz yere gidin.
    *   Önce, bu tek oturum için yürütme ilkesini ayarlayın, ardından betiği çalıştırın.
      ```powershell
      # Betiğin yalnızca bu pencerede çalışmasına izin ver
      Set-ExecutionPolicy Bypass -Scope Process -Force

      # Betiği çalıştır (doğru yolu kullan)
      .\Gallery-Lock.ps1
      ```

**İşte bu kadar!** Yem dosyaları şimdi yerinde ve sertleştirilmiş durumda. Tüm pencereleri kapatabilirsiniz.

<details>
  <summary><strong>Alternatif Yöntem: Yönetici Olarak Çalıştırma (Daha Az Güvenli)</strong></summary>

  > [!NOTE]
  > Bu yöntem işe yarar, ancak dosya koruması o kadar güçlü değildir çünkü bir Yönetici sahipliği daha kolay alabilir. Yalnızca PsExec'i kullanamıyorsanız önerilir.

  1. `Gallery-Lock.ps1` betik dosyasına **sağ tıklayın**.
  2. **"PowerShell ile Çalıştır"**ı seçin.
  3. İstenirse, yönetici hakları vermek için UAC (Kullanıcı Hesabı Denetimi) istemini onaylayın.

  Betik, SYSTEM olarak değil, Yönetici olarak çalıştığını size bildirecektir.
</details>

---

## 🗺️ Korunan Dosya Konumları

Betik, aşağıdaki standart kötü amaçlı yazılım yollarında yemler oluşturur ve korur:

| Profil Türü | Yol |
| :--- | :--- |
| **Kullanıcı Profili** | `%APPDATA%\Gallery.exe` |
| **Sistem Profili** | `C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe` |

---

## 🧱 Nasıl Çalışır: Teknik Bir Döküm

Betiğin etkinliği, çok katmanlı bir güvenlik stratejisinden gelir:

1.  **🔍 Tara ve Temizle:** Önce hedef konumlardaki mevcut `Gallery.exe` dosyalarını kontrol eder ve siler, temiz bir başlangıç sağlar.
2.  **📝 Yem Oluştur:** `Gallery.exe` adında boş bir 0 baytlık dosya oluşturulur. Zararsızdır ve yer kaplamaz.
3.  **🛡️ Kaleyi İnşa Et (ACL Sertleştirmesi):** Bu en kritik adımdır. Betik, dosyanın Erişim Kontrol Listesini (ACL) değiştirir:
    *   **Miras Almayı Engeller:** Dosyanın üst klasöründen izinleri miras almasını engeller. Bu, onu gelecekteki herhangi bir güvenlik değişikliğinden izole eder.
    *   **Herkesi Reddediyor:** `Everyone` grubu için açık bir `Deny FullControl` kuralı ekler. Windows'ta, açık bir `Deny` kuralı her zaman herhangi bir `Allow` kuralını geçersiz kılar. Bu, hiçbir kullanıcının, **bir Yöneticinin bile**, dosyayı yazamayacağı, değiştiremeyeceği veya silemeyeceği anlamına gelir.
    *   **SYSTEM'e Kontrol Verir:** Yalnızca `NT AUTHORITY\SYSTEM` veya `TrustedInstaller` hesabının `FullControl` sahibi olmasını sağlar. Bu, sistem bütünlüğü için gereklidir, ancak kötü amaçlı yazılımların (ve kullanıcıların) kolayca kullanamayacağı bir hesaptır.
4.  **👻 Görünmez Ol:** Son olarak, dosya özniteliklerini `Gizli` ve `Sistem` olarak ayarlar, kazara keşfedilmesini veya kurcalanmasını önlemek için Dosya Gezgini'ndeki standart görünümden gizler.

---

## ⚠️ Önemli Uyarılar ve Geri Alma

> [!WARNING]
> **Bu betik, sizin için bile kaldırılması *kasıtlı olarak* zor olan bir dosya oluşturur.** Bunu daha sonra erişmeniz gerekebilecek herhangi bir dosyada çalıştırmayın. Özellikle bilinen kötü amaçlı yazılım yollarını engellemek için tasarlanmıştır.

### Kilitli Bir Yem Dosyasını Manuel Olarak Kaldırma

Yemleri kaldırmanız gerekirse, korumayı bir **Yönetici** olarak manuel olarak tersine çevirmeniz gerekir.

1.  **Bir Yönetici Terminali Açın** (`Win + X` > Terminal (Yönetici)).
2.  Dosyanın **sahipliğini alın**. Yolu doğru olanla değiştirin.
    *Kullanıcı dosyası için:*
    ```cmd
    takeown /f "%APPDATA%\Gallery.exe"
    ```
    *Sistem dosyası için:*
    ```cmd
    takeown /f "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe"
    ```
3.  Üst klasörden miras almak için **izinleri sıfırlayın**.
    *Kullanıcı dosyası için:*
    ```cmd
    icacls "%APPDATA%\Gallery.exe" /reset
    ```
    *Sistem dosyası için:*
    ```cmd
    icacls "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe" /reset
    ```
4.  Artık dosyayı normal şekilde **silebilirsiniz**.
    ```powershell
    Remove-Item -Path "$env:APPDATA\Gallery.exe" -Force
    ```

---

## 🔎 Sorun Giderme ve SSS

| Belirti / Soru | Çözüm / Açıklama |
| :--- | :--- |
| ❌ **Betik yürütülürken "Erişim engellendi" hatası.** | SYSTEM yerine Yönetici olarak çalıştırıyorsanız bu beklenir. Betik, `SYSTEM`'i sahip olarak ayarlayamaz. **Tam koruma için PsExec yöntemini kullanın.** |
| 📜 **"Bu sistemde betiklerin çalıştırılması devre dışı bırakıldı." hatası.** | Bu bir PowerShell Yürütme İlkesi hatasıdır. Ana betiği çalıştırmadan önce `Set-ExecutionPolicy Bypass -Scope Process -Force` çalıştırarak mevcut işlem için bunu atlayabilirsiniz. |
| 🪟 **Dosya Gezgini'nde `Gallery.exe` dosyasını göremiyorum.** | Bu kasıtlıdır. Dosya gizlidir. Görüntülemek için Dosya Gezgini > `Görünüm` > `Seçenekler` > `Görünüm` sekmesine gidin ve **"Gizli dosyaları göster..."** seçeneğini işaretleyin ve **"Korunan işletim sistemi dosyalarını gizle"** seçeneğinin işaretini kaldırın. |
| 🗑️ **Yönetici olmama rağmen dosyayı silemiyorum!** | Bu, betiğin doğru çalıştığı anlamına gelir! Sizi de dahil olmak üzere herkesi engellemek için tasarlanmıştır. Kaldırmak için **[Geri Alma](#️-önemli-uyarılar-ve-geri-alma)** bölümündeki adımları izleyin. |
| 🤔 **`SYSTEM` olarak çalıştırmak neden bu kadar önemli?** | `SYSTEM` hesabı, Windows'taki nihai yetkidir. `SYSTEM`'i yemin sahibi yaparak, bir Yöneticinin bile önce açıkça sahiplik almadan onu kolayca değiştirmesini engeller. Yönetici haklarıyla çalışan kötü amaçlı yazılımlar engellenecektir, bu da büyük bir güvenlik kazancıdır. |

---

## 📜 Lisans

Bu proje açık kaynaklıdır ve [MIT Lisansı](https://github.com/i-am-aka/readme-assets/blob/main/LICENSE) altında dağıtılmaktadır. Kullanmakta, paylaşmakta ve değiştirmekte özgürsünüz.

---

## 📥 Orijinal README'yi İndirin

```bash
curl -o README.md https://raw.githubusercontent.com/i-am-aka/Gallery-Lock/main/README.md
```
