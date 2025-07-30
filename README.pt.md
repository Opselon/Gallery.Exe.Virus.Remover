# 🛡️ Gallery-Lock: A Isca Indestrutível

<p align="center">
  <strong>Um script PowerShell "configure e esqueça" que cria um bloqueio permanente e indestrutível para barrar o malware <code>Gallery.exe</code> e prevenir a reinfecção.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-5.1+-blue.svg" alt="Versão do PowerShell">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="Licença">
  <img src="https://img.shields.io/badge/Platform-Windows-lightgrey.svg" alt="Plataforma">
  <img src="https://img.shields.io/badge/Status-Active-brightgreen.svg" alt="Status">
</p>

---

## O Problema: O Vírus Chato `Gallery.exe`

Você está cansado de remover o malware `Gallery.exe`, apenas para ele reaparecer após uma reinicialização? Este vírus comum funciona colocando seu executável em pastas específicas do usuário e do sistema. Mesmo após limpar seu sistema, ele frequentemente retorna porque a fonte original da infecção (como uma tarefa agendada ou outro processo oculto) tenta recriá-lo.

## A Solução: Uma Fortaleza Digital

**Gallery-Lock** não apenas exclui o vírus; ele constrói uma fortaleza permanente em seu lugar. O script cria arquivos de isca de zero byte (vazios) chamados `Gallery.exe` nos locais exatos que o malware visa. Em seguida, ele aplica permissões de segurança (ACLs) extremamente rígidas que tornam essas iscas **impossíveis de serem sobrescritas ou excluídas pelo malware**.

O resultado? A tentativa do malware de reinfectar seu sistema é bloqueada no nível do sistema operacional, todas as vezes.

---

## 🚀 Principais Características

| Característica | Descrição |
| :--- | :--- |
| ✅ **Erradica Infecções Existentes** | Encontra e exclui automaticamente quaisquer arquivos `Gallery.exe` atuais de locais conhecidos de malware. |
| 🛡️ **Cria Iscas Imutáveis** | Gera arquivos de placeholder vazios e os bloqueia. |
| 🔒 **Endurecimento Avançado de ACL** | Usa Listas de Controle de Acesso (ACLs) para `NEGAR` todas as permissões a todos, incluindo Administradores. Apenas a conta principal `SYSTEM` retém o controle. |
| 🕵️ **Furtivo e Invisível** | Os arquivos de isca são definidos como arquivos `Ocultos` e do `Sistema`, tornando-os invisíveis durante o uso normal. |
| 📈 **Registro Claro e Informativo** | Fornece feedback em tempo real com código de cores no console para cada ação realizada. |
| 📦 **Zero Dependências** | Um script PowerShell autônomo que roda em qualquer sistema Windows moderno sem a necessidade de instalações extras. |

---

## 🛠️ Como Usar: O Guia de 2 Minutos

Para máxima eficácia, o script deve ser executado como `SYSTEM`. Este é o nível de autoridade mais alto no Windows, até mesmo acima do Administrador.

### Método Recomendado: Executar como SYSTEM com PsExec

Este é o **método mais seguro** e garante que o script possa aplicar suas proteções mais fortes.

1.  **Baixe o PsExec:**
    *   Baixe a **Sysinternals Suite** oficial da Microsoft: [**Baixe Aqui**](https://learn.microsoft.com/en-us/sysinternals/downloads/psexec).
    *   Extraia o arquivo ZIP para um local simples, como `C:\Sysinternals`.

2.  **Abra um Terminal de Administrador:**
    *   Pressione `Win + X` e selecione **Terminal (Admin)** ou **Windows PowerShell (Admin)**.

3.  **Navegue até a Pasta do PsExec:**
    *   No terminal, vá para o diretório onde você extraiu o PsExec.
      ```powershell
      cd C:\Sysinternals
      ```

4.  **Inicie um PowerShell no Nível do SYSTEM:**
    *   Execute o seguinte comando. Uma nova janela do PowerShell será aberta com privilégios de `SYSTEM`.
      ```powershell
      .\PsExec64.exe -i -s powershell.exe
      ```

5.  **Execute o Script Gallery-Lock:**
    *   Na **nova janela do SYSTEM**, navegue até onde você salvou o `Gallery-Lock.ps1`.
    *   Primeiro, defina a política de execução para esta única sessão e, em seguida, execute o script.
      ```powershell
      # Permitir que o script seja executado apenas nesta janela
      Set-ExecutionPolicy Bypass -Scope Process -Force

      # Execute o script (use o caminho correto)
      .\Gallery-Lock.ps1
      ```

**É isso!** Os arquivos de isca estão agora no lugar e endurecidos. Você pode fechar todas as janelas.

<details>
  <summary><strong>Método Alternativo: Executar como Administrador (Menos Seguro)</strong></summary>

  > [!NOTE]
  > Este método funciona, mas a proteção do arquivo não é tão forte porque um Administrador ainda pode tomar posse mais facilmente. É recomendado apenas se você não puder usar o PsExec.

  1. **Clique com o botão direito** no arquivo de script `Gallery-Lock.ps1`.
  2. Selecione **"Executar com PowerShell"**.
  3. Se solicitado, aprove o prompt do UAC (Controle de Conta de Usuário) para conceder direitos de administrador.

  O script irá notificá-lo de que está sendo executado como Administrador e não como SYSTEM.
</details>

---

## 🗺️ Locais de Arquivos Protegidos

O script cria e protege iscas nos seguintes caminhos de malware padrão:

| Tipo de Perfil | Caminho |
| :--- | :--- |
| **Perfil do Usuário** | `%APPDATA%\Gallery.exe` |
| **Perfil do Sistema** | `C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe` |

---

## 🧱 Como Funciona: Uma Análise Técnica

A eficácia do script vem de uma estratégia de segurança em várias camadas:

1.  **🔍 Verificar e Limpar:** Ele primeiro verifica e exclui quaisquer arquivos `Gallery.exe` existentes nos locais de destino, garantindo um começo limpo.
2.  **📝 Criar a Isca:** Um arquivo vazio de 0 bytes chamado `Gallery.exe` é criado. É inofensivo e não ocupa espaço.
3.  **🛡️ Construir a Fortaleza (Endurecimento de ACL):** Este é o passo mais crítico. O script modifica a Lista de Controle de Acesso (ACL) do arquivo:
    *   **Bloqueia a Herança:** Impede que o arquivo herde permissões de sua pasta pai. Isso o isola de quaisquer futuras alterações de segurança.
    *   **Nega a Todos:** Adiciona uma regra explícita `Deny FullControl` para o grupo `Todos`. No Windows, uma regra `Deny` explícita sempre se sobrepõe a quaisquer regras `Allow`. Isso significa que nenhum usuário, **nem mesmo um Administrador**, pode escrever, modificar ou excluir o arquivo.
    *   **Concede Controle ao SYSTEM:** Garante que apenas a conta `NT AUTHORITY\SYSTEM` ou `TrustedInstaller` tenha `FullControl`. Isso é necessário para a integridade do sistema, mas é uma conta que malwares (e usuários) não podem usar facilmente.
4.  **👻 Ficar Invisível:** Finalmente, ele define os atributos do arquivo para `Oculto` e `Sistema`, escondendo-o da visualização padrão no Explorador de Arquivos para evitar descoberta ou adulteração acidental.

---

## ⚠️ Avisos Importantes e Como Desfazer

> [!WARNING]
> **Este script cria um arquivo que é *intencionalmente* difícil de remover, mesmo para você.** Não execute isso em nenhum arquivo que você possa precisar acessar mais tarde. Ele é projetado especificamente para bloquear caminhos de malware conhecidos.

### Como Remover Manualmente um Arquivo de Isca Bloqueado

Se você precisar remover as iscas, deverá reverter manualmente a proteção como um **Administrador**.

1.  **Abra um Terminal de Administrador** (`Win + X` > Terminal (Admin)).
2.  **Tome Posse** do arquivo. Substitua o caminho pelo correto.
    *Para o arquivo do usuário:*
    ```cmd
    takeown /f "%APPDATA%\Gallery.exe"
    ```
    *Para o arquivo do sistema:*
    ```cmd
    takeown /f "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe"
    ```
3.  **Redefina as Permissões** para herdar da pasta pai.
    *Para o arquivo do usuário:*
    ```cmd
    icacls "%APPDATA%\Gallery.exe" /reset
    ```
    *Para o arquivo do sistema:*
    ```cmd
    icacls "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe" /reset
    ```
4.  Agora você pode **excluir o arquivo** normalmente.
    ```powershell
    Remove-Item -Path "$env:APPDATA\Gallery.exe" -Force
    ```

---

## 🔎 Solução de Problemas e Perguntas Frequentes

| Sintoma / Pergunta | Solução / Explicação |
| :--- | :--- |
| ❌ **Erro de "Acesso negado" durante a execução do script.** | Isso é esperado se você estiver executando como Administrador em vez de SYSTEM. O script não pode definir `SYSTEM` como o proprietário. **Use o método PsExec para proteção total.** |
| 📜 **Erro "A execução de scripts está desabilitada neste sistema".** | Este é um erro de Política de Execução do PowerShell. Você pode contorná-lo para o processo atual executando `Set-ExecutionPolicy Bypass -Scope Process -Force` antes de executar o script principal. |
| 🪟 **Não consigo ver o arquivo `Gallery.exe` no Explorador de Arquivos.** | Isso é intencional. O arquivo está oculto. Para visualizá-lo, vá para o Explorador de Arquivos > `Exibir` > `Opções` > guia `Modo de Exibição`, e marque **"Mostrar arquivos ocultos..."** e desmarque **"Ocultar arquivos protegidos do sistema operacional"**. |
| 🗑️ **Não consigo excluir o arquivo, mesmo como Administrador!** | Isso significa que o script está funcionando corretamente! Ele foi projetado para bloquear a todos, incluindo você. Siga as etapas na seção **[Como Desfazer](#️-avisos-importantes-e-como-desfazer)** para removê-lo. |
| 🤔 **Por que é tão importante executar como `SYSTEM`?** | A conta `SYSTEM` é a autoridade máxima no Windows. Ao tornar o `SYSTEM` o proprietário da isca, impede que até mesmo um Administrador a modifique facilmente sem primeiro tomar posse explicitamente. Malwares executados com direitos de administrador serão bloqueados, o que é uma grande vitória de segurança. |

---

## 📜 Licença

Este projeto é de código aberto e distribuído sob a [Licença MIT](https://github.com/i-am-aka/readme-assets/blob/main/LICENSE). Você é livre para usá-lo, compartilhá-lo e modificá-lo.

---

## 📥 Baixar o README Original

```bash
curl -o README.md https://raw.githubusercontent.com/i-am-aka/Gallery-Lock/main/README.md
```
