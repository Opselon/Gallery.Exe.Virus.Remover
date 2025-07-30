# 🛡️ Gallery-Lock：坚不可摧的诱饵

<p align="center">
  <strong>一个“一劳永逸”的PowerShell脚本，可创建一个永久性的、坚不可摧的路障，以阻止<code>Gallery.exe</code>恶意软件并防止再次感染。</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-5.1+-blue.svg" alt="PowerShell版本">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="许可证">
  <img src="https://img.shields.io/badge/Platform-Windows-lightgrey.svg" alt="平台">
  <img src="https://img.shields.io/badge/Status-Active-brightgreen.svg" alt="状态">
</p>

---

## 问题：烦人的`Gallery.exe`病毒

您是否厌倦了删除`Gallery.exe`恶意软件，结果它在重启后又重新出现？这种常见的病毒通过将其可执行文件放置在特定的用户和系统文件夹中来工作。即使在清理系统后，它也常常会回来，因为原始感染源（如计划任务或其他隐藏进程）会尝试重新创建它。

## 解决方案：数字堡垒

**Gallery-Lock**不仅仅是删除病毒；它在其位置上建立了一个永久的堡垒。该脚本在恶意软件所针对的确切位置创建名为`Gallery.exe`的零字节（空）诱饵文件。然后，它应用极其严格的安全权限（ACL），使这些诱饵**无法被恶意软件覆盖或删除**。

结果呢？恶意软件重新感染您系统的企图在操作系统级别被阻止，每一次都是如此。

---

## 🚀 主要特点

| 特点 | 描述 |
| :--- | :--- |
| ✅ **根除现有感染** | 自动查找并删除已知恶意软件位置中的任何当前`Gallery.exe`文件。 |
| 🛡️ **创建不可变诱饵** | 生成空的占位符文件并将其锁定。 |
| 🔒 **高级ACL加固** | 使用访问控制列表（ACL）`拒绝`所有人的所有权限，包括管理员。只有核心`SYSTEM`帐户保留控制权。 |
| 🕵️ **隐秘无形** | 诱饵文件被设置为`隐藏`和`系统`文件，使其在正常使用中不可见。 |
| 📈 **清晰翔实的日志记录** | 为每个执行的操作在控制台中提供颜色编码的实时反馈。 |
| 📦 **零依赖** | 一个独立的PowerShell脚本，可在任何现代Windows系统上运行，无需额外安装。 |

---

## 🛠️ 如何使用：2分钟指南

为获得最大效果，该脚本必须以`SYSTEM`身份运行。这是Windows上的最高权限级别，甚至高于管理员。

### 推荐方法：使用PsExec以SYSTEM身份运行

这是**最安全的方法**，并保证脚本可以应用其最强的保护。

1.  **下载PsExec：**
    *   从Microsoft下载官方**Sysinternals Suite**：[**在此处下载**](https://learn.microsoft.com/en-us/sysinternals/downloads/psexec)。
    *   将ZIP文件解压缩到一个简单的位置，例如`C:\Sysinternals`。

2.  **打开管理员终端：**
    *   按`Win + X`并选择**终端（管理员）**或**Windows PowerShell（管理员）**。

3.  **导航到PsExec文件夹：**
    *   在终端中，转到您解压缩PsExec的目录。
      ```powershell
      cd C:\Sysinternals
      ```

4.  **启动SYSTEM级别的PowerShell：**
    *   运行以下命令。将打开一个具有`SYSTEM`权限的新PowerShell窗口。
      ```powershell
      .\PsExec64.exe -i -s powershell.exe
      ```

5.  **运行Gallery-Lock脚本：**
    *   在**新的SYSTEM窗口**中，导航到您保存`Gallery-Lock.ps1`的位置。
    *   首先，为此单个会话设置执行策略，然后运行脚本。
      ```powershell
      # 仅允许在此窗口中运行脚本
      Set-ExecutionPolicy Bypass -Scope Process -Force

      # 运行脚本（使用正确的路径）
      .\Gallery-Lock.ps1
      ```

**就这样！** 诱饵文件现在已经就位并已加固。您可以关闭所有窗口。

<details>
  <summary><strong>替代方法：以管理员身份运行（不太安全）</strong></summary>

  > [!NOTE]
  > 此方法有效，但文件保护不那么强大，因为管理员仍然可以更容易地取得所有权。仅当您无法使用PsExec时才建议使用。

  1. **右键单击**`Gallery-Lock.ps1`脚本文件。
  2. 选择**“使用PowerShell运行”**。
  3. 如果出现提示，批准UAC（用户帐户控制）提示以授予其管理员权限。

  脚本将通知您它正在以管理员身份而不是SYSTEM身份运行。
</details>

---

## 🗺️ 受保护的文件位置

该脚本在以下标准恶意软件路径中创建和保护诱饵：

| 配置文件类型 | 路径 |
| :--- | :--- |
| **用户配置文件** | `%APPDATA%\Gallery.exe` |
| **系统配置文件** | `C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe` |

---

## 🧱 工作原理：技术分解

该脚本的有效性来自多层安全策略：

1.  **🔍 扫描和清理：** 它首先检查并删除目标位置中任何现有的`Gallery.exe`文件，确保一个干净的开始。
2.  **📝 创建诱饵：** 创建一个名为`Gallery.exe`的空0字节文件。它是无害的，不占用任何空间。
3.  **🛡️ 构建堡垒（ACL加固）：** 这是最关键的步骤。该脚本修改文件的访问控制列表（ACL）：
    *   **阻止继承：** 它阻止文件从其父文件夹继承权限。这将其与任何未来的安全更改隔离开来。
    *   **拒绝所有人：** 它为`Everyone`组添加了一个明确的`Deny FullControl`规则。在Windows中，明确的`Deny`规则总是覆盖任何`Allow`规则。这意味着任何用户，**甚至管理员**，都不能写入、修改或删除该文件。
    *   **授予SYSTEM控制权：** 它确保只有`NT AUTHORITY\SYSTEM`或`TrustedInstaller`帐户具有`FullControl`。这对于系统完整性是必要的，但这是一个恶意软件（和用户）无法轻易使用的帐户。
4.  **👻 隐身：** 最后，它将文件属性设置为`隐藏`和`系统`，使其在文件资源管理器的标准视图中隐藏，以防止意外发现或篡改。

---

## ⚠️ 重要警告和如何撤消

> [!WARNING]
> **此脚本创建的文件*有意*难以删除，即使对您也是如此。** 不要在您以后可能需要访问的任何文件上运行此脚本。它专门设计用于阻止已知的恶意软件路径。

### 如何手动删除锁定的诱饵文件

如果您需要删除诱饵，则必须以**管理员**身份手动撤销保护。

1.  **打开管理员终端**（`Win + X` > 终端（管理员））。
2.  **取得所有权**文件。将路径替换为正确的路径。
    *对于用户文件：*
    ```cmd
    takeown /f "%APPDATA%\Gallery.exe"
    ```
    *对于系统文件：*
    ```cmd
    takeown /f "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe"
    ```
3.  **重置权限**以从父文件夹继承。
    *对于用户文件：*
    ```cmd
    icacls "%APPDATA%\Gallery.exe" /reset
    ```
    *对于系统文件：*
    ```cmd
    icacls "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe" /reset
    ```
4.  您现在可以正常**删除文件**了。
    ```powershell
    Remove-Item -Path "$env:APPDATA\Gallery.exe" -Force
    ```

---

## 🔎 故障排除和常见问题解答

| 症状/问题 | 解决方案/解释 |
| :--- | :--- |
| ❌ **脚本执行期间出现“访问被拒绝”错误。** | 如果您以管理员而不是SYSTEM身份运行，这是预期的。该脚本无法将`SYSTEM`设置为所有者。**使用PsExec方法获得全面保护。** |
| 📜 **“此系统上已禁用运行脚本。”错误。** | 这是PowerShell执行策略错误。您可以通过在运行主脚本之前运行`Set-ExecutionPolicy Bypass -Scope Process -Force`来为当前进程绕过它。 |
| 🪟 **我在文件资源管理器中看不到`Gallery.exe`文件。** | 这是故意的。该文件是隐藏的。要查看它，请转到文件资源管理器 > `查看` > `选项` > `查看`选项卡，然后选中**“显示隐藏的文件...”**并取消选中**“隐藏受保护的操作系统文件”**。 |
| 🗑️ **即使作为管理员，我也无法删除该文件！** | 这说明脚本工作正常！它旨在阻止所有人，包括您。请按照**[如何撤消](#️-重要警告和如何撤消)**部分中的步骤将其删除。 |
| 🤔 **为什么以`SYSTEM`身份运行如此重要？** | `SYSTEM`帐户是Windows上的最终权限。通过使`SYSTEM`成为诱饵的所有者，它可以防止即使是管理员在没有首先明确取得所有权的情况下轻易修改它。以管理员权限运行的恶意软件将被阻止，这是一个巨大的安全胜利。 |

---

## 📜 许可证

该项目是开源的，并根据[MIT许可证](https://github.com/i-am-aka/readme-assets/blob/main/LICENSE)分发。您可以自由使用、分享和修改它。

---

## 📥 下载原始README

```bash
curl -o README.md https://raw.githubusercontent.com/i-am-aka/Gallery-Lock/main/README.md
```
