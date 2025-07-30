# 🛡️ Gallery-Lock: Mồi nhử không thể phá hủy

<p align="center">
  <strong>Một tập lệnh PowerShell "cài đặt và quên" tạo ra một rào cản vĩnh viễn, không thể phá hủy để chặn phần mềm độc hại <code>Gallery.exe</code> và ngăn ngừa tái nhiễm.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-5.1+-blue.svg" alt="Phiên bản PowerShell">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="Giấy phép">
  <img src="https://img.shields.io/badge/Platform-Windows-lightgrey.svg" alt="Nền tảng">
  <img src="https://img.shields.io/badge/Status-Active-brightgreen.svg" alt="Trạng thái">
</p>

---

## Vấn đề: Virus `Gallery.exe` phiền phức

Bạn có mệt mỏi với việc loại bỏ phần mềm độc hại `Gallery.exe`, chỉ để nó xuất hiện trở lại sau khi khởi động lại? Loại virus phổ biến này hoạt động bằng cách đặt tệp thực thi của nó vào các thư mục người dùng và hệ thống cụ thể. Ngay cả sau khi làm sạch hệ thống của bạn, nó thường quay trở lại vì nguồn lây nhiễm ban đầu (như một tác vụ đã lên lịch hoặc một quy trình ẩn khác) cố gắng tạo lại nó.

## Giải pháp: Một pháo đài kỹ thuật số

**Gallery-Lock** không chỉ xóa virus; nó xây dựng một pháo đài vĩnh viễn ở vị trí của nó. Tập lệnh tạo ra các tệp mồi nhử không byte (trống) có tên `Gallery.exe` ở các vị trí chính xác mà phần mềm độc hại nhắm đến. Sau đó, nó áp dụng các quyền bảo mật (ACL) cực kỳ nghiêm ngặt khiến cho phần mềm độc hại **không thể ghi đè hoặc xóa** những mồi nhử này.

Kết quả? Nỗ lực của phần mềm độc hại nhằm tái nhiễm hệ thống của bạn bị chặn ở cấp hệ điều hành, mọi lúc.

---

## 🚀 Các tính năng chính

| Tính năng | Mô tả |
| :--- | :--- |
| ✅ **Loại bỏ các lây nhiễm hiện có** | Tự động tìm và xóa mọi tệp `Gallery.exe` hiện tại khỏi các vị trí phần mềm độc hại đã biết. |
| 🛡️ **Tạo mồi nhử bất biến** | Tạo các tệp giữ chỗ trống và khóa chúng lại. |
| 🔒 **Tăng cường ACL nâng cao** | Sử dụng Danh sách kiểm soát truy cập (ACL) để `TỪ CHỐI` tất cả các quyền cho mọi người, kể cả Quản trị viên. Chỉ có tài khoản `SYSTEM` cốt lõi mới giữ quyền kiểm soát. |
| 🕵️ **Lén lút & Vô hình** | Các tệp mồi nhử được đặt làm tệp `Ẩn` và `Hệ thống`, khiến chúng không thể nhìn thấy trong quá trình sử dụng bình thường. |
| 📈 **Ghi nhật ký rõ ràng & nhiều thông tin** | Cung cấp phản hồi thời gian thực, được mã hóa màu trong bảng điều khiển cho mọi hành động được thực hiện. |
| 📦 **Không có phụ thuộc** | Một tập lệnh PowerShell độc lập chạy trên mọi hệ thống Windows hiện đại mà không cần cài đặt thêm. |

---

## 🛠️ Cách sử dụng: Hướng dẫn 2 phút

Để có hiệu quả tối đa, tập lệnh phải được chạy với tư cách `SYSTEM`. Đây là cấp thẩm quyền cao nhất trên Windows, thậm chí còn cao hơn cả Quản trị viên.

### Phương pháp được đề xuất: Chạy với tư cách SYSTEM bằng PsExec

Đây là **phương pháp an toàn nhất** và đảm bảo rằng tập lệnh có thể áp dụng các biện pháp bảo vệ mạnh nhất của nó.

1.  **Tải xuống PsExec:**
    *   Tải xuống **Sysinternals Suite** chính thức từ Microsoft: [**Tải xuống tại đây**](https://learn.microsoft.com/en-us/sysinternals/downloads/psexec).
    *   Giải nén tệp ZIP vào một vị trí đơn giản, như `C:\Sysinternals`.

2.  **Mở một Terminal của Quản trị viên:**
    *   Nhấn `Win + X` và chọn **Terminal (Admin)** hoặc **Windows PowerShell (Admin)**.

3.  **Điều hướng đến Thư mục PsExec:**
    *   Trong terminal, đi đến thư mục bạn đã giải nén PsExec.
      ```powershell
      cd C:\Sysinternals
      ```

4.  **Khởi chạy PowerShell cấp SYSTEM:**
    *   Chạy lệnh sau. Một cửa sổ PowerShell mới sẽ mở ra với các đặc quyền `SYSTEM`.
      ```powershell
      .\PsExec64.exe -i -s powershell.exe
      ```

5.  **Chạy tập lệnh Gallery-Lock:**
    *   Trong **cửa sổ SYSTEM mới**, điều hướng đến nơi bạn đã lưu `Gallery-Lock.ps1`.
    *   Đầu tiên, hãy đặt chính sách thực thi cho phiên duy nhất này, sau đó chạy tập lệnh.
      ```powershell
      # Cho phép tập lệnh chỉ chạy trong cửa sổ này
      Set-ExecutionPolicy Bypass -Scope Process -Force

      # Chạy tập lệnh (sử dụng đúng đường dẫn)
      .\Gallery-Lock.ps1
      ```

**Thế là xong!** Các tệp mồi nhử hiện đã được đặt và tăng cường. Bạn có thể đóng tất cả các cửa sổ.

<details>
  <summary><strong>Phương pháp thay thế: Chạy với tư cách Quản trị viên (Kém an toàn hơn)</strong></summary>

  > [!NOTE]
  > Phương pháp này hoạt động, nhưng việc bảo vệ tệp không mạnh bằng vì Quản trị viên vẫn có thể dễ dàng chiếm quyền sở hữu hơn. Nó chỉ được khuyến nghị nếu bạn không thể sử dụng PsExec.

  1. **Nhấp chuột phải** vào tệp tập lệnh `Gallery-Lock.ps1`.
  2. Chọn **"Chạy bằng PowerShell"**.
  3. Nếu được nhắc, hãy chấp thuận lời nhắc UAC (Kiểm soát tài khoản người dùng) để cấp cho nó quyền quản trị.

  Tập lệnh sẽ thông báo cho bạn rằng nó đang chạy với tư cách Quản trị viên chứ không phải SYSTEM.
</details>

---

## 🗺️ Vị trí tệp được bảo vệ

Tập lệnh tạo và bảo vệ các mồi nhử trong các đường dẫn phần mềm độc hại tiêu chuẩn sau:

| Loại hồ sơ | Đường dẫn |
| :--- | :--- |
| **Hồ sơ người dùng** | `%APPDATA%\Gallery.exe` |
| **Hồ sơ hệ thống** | `C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe` |

---

## 🧱 Cách thức hoạt động: Phân tích kỹ thuật

Hiệu quả của tập lệnh đến từ một chiến lược bảo mật nhiều lớp:

1.  **🔍 Quét & Dọn dẹp:** Đầu tiên, nó kiểm tra và xóa mọi tệp `Gallery.exe` hiện có ở các vị trí đích, đảm bảo một khởi đầu sạch sẽ.
2.  **📝 Tạo mồi nhử:** Một tệp 0 byte trống có tên `Gallery.exe` được tạo. Nó vô hại và không chiếm dung lượng.
3.  **🛡️ Xây dựng Pháo đài (Tăng cường ACL):** Đây là bước quan trọng nhất. Tập lệnh sửa đổi Danh sách kiểm soát truy cập (ACL) của tệp:
    *   **Chặn kế thừa:** Nó ngăn tệp kế thừa các quyền từ thư mục mẹ của nó. Điều này cô lập nó khỏi bất kỳ thay đổi bảo mật nào trong tương lai.
    *   **Từ chối mọi người:** Nó thêm một quy tắc `Deny FullControl` rõ ràng cho nhóm `Everyone`. Trong Windows, một quy tắc `Deny` rõ ràng luôn ghi đè lên bất kỳ quy tắc `Allow` nào. Điều này có nghĩa là không có người dùng nào, **ngay cả Quản trị viên**, có thể ghi, sửa đổi hoặc xóa tệp.
    *   **Cấp quyền kiểm soát cho SYSTEM:** Nó đảm bảo rằng chỉ tài khoản `NT AUTHORITY\SYSTEM` hoặc `TrustedInstaller` mới có `FullControl`. Điều này là cần thiết cho tính toàn vẹn của hệ thống nhưng là một tài khoản mà phần mềm độc hại (và người dùng) không thể dễ dàng sử dụng.
4.  **👻 Trở nên vô hình:** Cuối cùng, nó đặt các thuộc tính của tệp thành `Ẩn` và `Hệ thống`, ẩn nó khỏi chế độ xem tiêu chuẩn trong File Explorer để ngăn chặn việc phát hiện hoặc giả mạo vô tình.

---

## ⚠️ Cảnh báo quan trọng & Cách hoàn tác

> [!WARNING]
> **Tập lệnh này tạo ra một tệp *cố ý* khó xóa, ngay cả đối với bạn.** Không chạy tập lệnh này trên bất kỳ tệp nào bạn có thể cần truy cập sau này. Nó được thiết kế đặc biệt để chặn các đường dẫn phần mềm độc hại đã biết.

### Cách xóa thủ công một tệp mồi nhử bị khóa

Nếu bạn cần xóa các mồi nhử, bạn phải đảo ngược việc bảo vệ theo cách thủ công với tư cách là **Quản trị viên**.

1.  **Mở một Terminal của Quản trị viên** (`Win + X` > Terminal (Admin)).
2.  **Chiếm quyền sở hữu** của tệp. Thay thế đường dẫn bằng đường dẫn chính xác.
    *Đối với tệp người dùng:*
    ```cmd
    takeown /f "%APPDATA%\Gallery.exe"
    ```
    *Đối với tệp hệ thống:*
    ```cmd
    takeown /f "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe"
    ```
3.  **Đặt lại quyền** để kế thừa từ thư mục mẹ.
    *Đối với tệp người dùng:*
    ```cmd
    icacls "%APPDATA%\Gallery.exe" /reset
    ```
    *Đối với tệp hệ thống:*
    ```cmd
    icacls "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe" /reset
    ```
4.  Bây giờ bạn có thể **xóa tệp** một cách bình thường.
    ```powershell
    Remove-Item -Path "$env:APPDATA\Gallery.exe" -Force
    ```

---

## 🔎 Khắc phục sự cố & Câu hỏi thường gặp

| Triệu chứng / Câu hỏi | Giải pháp / Giải thích |
| :--- | :--- |
| ❌ **Lỗi "Truy cập bị từ chối" trong khi thực thi tập lệnh.** | Điều này được mong đợi nếu bạn đang chạy với tư cách Quản trị viên thay vì SYSTEM. Tập lệnh không thể đặt `SYSTEM` làm chủ sở hữu. **Sử dụng phương pháp PsExec để được bảo vệ hoàn toàn.** |
| 📜 **Lỗi "Việc chạy tập lệnh bị vô hiệu hóa trên hệ thống này".** | Đây là lỗi Chính sách thực thi PowerShell. Bạn có thể bỏ qua nó cho quy trình hiện tại bằng cách chạy `Set-ExecutionPolicy Bypass -Scope Process -Force` trước khi chạy tập lệnh chính. |
| 🪟 **Tôi không thể thấy tệp `Gallery.exe` trong File Explorer.** | Điều này là có chủ ý. Tệp bị ẩn. Để xem nó, hãy vào File Explorer > `View` > `Options` > tab `View`, và chọn **"Hiển thị các tệp ẩn..."** và bỏ chọn **"Ẩn các tệp hệ điều hành được bảo vệ"**. |
| 🗑️ **Tôi không thể xóa tệp, ngay cả với tư cách là Quản trị viên!** | Điều này có nghĩa là tập lệnh đang hoạt động chính xác! Nó được thiết kế để chặn tất cả mọi người, kể cả bạn. Hãy làm theo các bước trong phần **[Cách hoàn tác](#️-cảnh-báo-quan-trọng--cách-hoàn-tác)** để xóa nó. |
| 🤔 **Tại sao việc chạy với tư cách `SYSTEM` lại quan trọng đến vậy?** | Tài khoản `SYSTEM` là cơ quan có thẩm quyền cao nhất trên Windows. Bằng cách đặt `SYSTEM` làm chủ sở hữu của mồi nhử, nó ngăn chặn ngay cả Quản trị viên dễ dàng sửa đổi nó mà không cần chiếm quyền sở hữu một cách rõ ràng trước. Phần mềm độc hại chạy với quyền quản trị sẽ bị chặn, đây là một chiến thắng lớn về bảo mật. |

---

## 📜 Giấy phép

Dự án này là mã nguồn mở và được phân phối theo [Giấy phép MIT](https://github.com/i-am-aka/readme-assets/blob/main/LICENSE). Bạn được tự do sử dụng, chia sẻ và sửa đổi nó.

---

## 📥 Tải xuống README gốc

```bash
curl -o README.md https://raw.githubusercontent.com/i-am-aka/Gallery-Lock/main/README.md
```
