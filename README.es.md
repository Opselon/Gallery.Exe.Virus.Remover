# 🛡️ Gallery-Lock: El Señuelo Indestructible

<p align="center">
  <strong>Un script de PowerShell "configurar y olvidar" que crea un obstáculo permanente e indestructible para bloquear el malware <code>Gallery.exe</code> y evitar la reinfección.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-5.1+-blue.svg" alt="Versión de PowerShell">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="Licencia">
  <img src="https://img.shields.io/badge/Platform-Windows-lightgrey.svg" alt="Plataforma">
  <img src="https://img.shields.io/badge/Status-Active-brightgreen.svg" alt="Estado">
</p>

---

## El Problema: El Molesto Virus `Gallery.exe`

¿Estás cansado de eliminar el malware `Gallery.exe`, solo para que reaparezca después de un reinicio? Este virus común funciona colocando su ejecutable en carpetas específicas del usuario y del sistema. Incluso después de limpiar tu sistema, a menudo regresa porque la fuente de infección original (como una tarea programada u otro proceso oculto) intenta recrearlo.

## La Solución: Una Fortaleza Digital

**Gallery-Lock** no solo elimina el virus; construye una fortaleza permanente en su lugar. El script crea archivos señuelo de cero bytes (vacíos) llamados `Gallery.exe` en las ubicaciones exactas a las que se dirige el malware. Luego, aplica permisos de seguridad (ACL) extremadamente estrictos que hacen que estos señuelos sean **imposibles de sobrescribir o eliminar para el malware**.

¿El resultado? El intento del malware de re-infectar tu sistema es bloqueado a nivel del sistema operativo, cada vez.

---

## 🚀 Características Clave

| Característica | Descripción |
| :--- | :--- |
| ✅ **Erradica Infecciones Existentes** | Encuentra y elimina automáticamente cualquier archivo `Gallery.exe` actual de las ubicaciones conocidas del malware. |
| 🛡️ **Crea Señuelos Inmutables** | Genera archivos de marcador de posición vacíos y los bloquea. |
| 🔒 **Refuerzo Avanzado de ACL** | Utiliza Listas de Control de Acceso (ACL) para `DENEGAR` todos los permisos a todos, incluidos los Administradores. Solo la cuenta central `SYSTEM` retiene el control. |
| 🕵️ **Sigiloso e Invisible** | Los archivos señuelo se establecen como archivos `Ocultos` y de `Sistema`, haciéndolos invisibles durante el uso normal. |
| 📈 **Registro Claro e Informativo** | Proporciona retroalimentación en tiempo real y codificada por colores en la consola para cada acción realizada. |
| 📦 **Cero Dependencias** | Un script de PowerShell independiente que se ejecuta en cualquier sistema Windows moderno sin necesidad de instalaciones adicionales. |

---

## 🛠️ Cómo Usar: La Guía de 2 Minutos

Para una máxima efectividad, el script debe ejecutarse como `SYSTEM`. Este es el nivel de autoridad más alto en Windows, incluso por encima del Administrador.

### Método Recomendado: Ejecutar como SYSTEM con PsExec

Este es el **método más seguro** y garantiza que el script pueda aplicar sus protecciones más fuertes.

1.  **Descargar PsExec:**
    *   Descarga la **Suite Sysinternals** oficial de Microsoft: [**Descargar Aquí**](https://learn.microsoft.com/en-us/sysinternals/downloads/psexec).
    *   Extrae el archivo ZIP en una ubicación simple, como `C:\Sysinternals`.

2.  **Abrir una Terminal de Administrador:**
    *   Presiona `Win + X` y selecciona **Terminal (Administrador)** o **Windows PowerShell (Administrador)**.

3.  **Navegar a la Carpeta de PsExec:**
    *   En la terminal, ve al directorio donde extrajiste PsExec.
      ```powershell
      cd C:\Sysinternals
      ```

4.  **Lanzar un PowerShell a Nivel de SYSTEM:**
    *   Ejecuta el siguiente comando. Se abrirá una nueva ventana de PowerShell con privilegios de `SYSTEM`.
      ```powershell
      .\PsExec64.exe -i -s powershell.exe
      ```

5.  **Ejecutar el Script Gallery-Lock:**
    *   En la **nueva ventana de SYSTEM**, navega a donde guardaste `Gallery-Lock.ps1`.
    *   Primero, establece la política de ejecución para esta única sesión, luego ejecuta el script.
      ```powershell
      # Permitir que el script se ejecute solo en esta ventana
      Set-ExecutionPolicy Bypass -Scope Process -Force

      # Ejecutar el script (usa la ruta correcta)
      .\Gallery-Lock.ps1
      ```

**¡Eso es todo!** Los archivos señuelo ahora están en su lugar y reforzados. Puedes cerrar todas las ventanas.

<details>
  <summary><strong>Método Alternativo: Ejecutar como Administrador (Menos Seguro)</strong></summary>

  > [!NOTE]
  > Este método funciona, pero la protección de archivos no es tan fuerte porque un Administrador aún puede tomar posesión más fácilmente. Solo se recomienda si no puedes usar PsExec.

  1. **Haz clic derecho** en el archivo del script `Gallery-Lock.ps1`.
  2. Selecciona **"Ejecutar con PowerShell"**.
  3. Si se te solicita, aprueba la solicitud de UAC (Control de Cuentas de Usuario) para otorgarle derechos de administrador.

  El script te notificará que se está ejecutando como Administrador y no como SYSTEM.
</details>

---

## 🗺️ Ubicaciones de Archivos Protegidos

El script crea y protege señuelos en las siguientes rutas de malware estándar:

| Tipo de Perfil | Ruta |
| :--- | :--- |
| **Perfil de Usuario** | `%APPDATA%\Gallery.exe` |
| **Perfil del Sistema** | `C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe` |

---

## 🧱 Cómo Funciona: Un Desglose Técnico

La efectividad del script proviene de una estrategia de seguridad de múltiples capas:

1.  **🔍 Escanear y Limpiar:** Primero, busca y elimina cualquier archivo `Gallery.exe` existente en las ubicaciones de destino, asegurando un borrón y cuenta nueva.
2.  **📝 Crear el Señuelo:** Se crea un archivo vacío de 0 bytes llamado `Gallery.exe`. Es inofensivo y no ocupa espacio.
3.  **🛡️ Construir la Fortaleza (Refuerzo de ACL):** Este es el paso más crítico. El script modifica la Lista de Control de Acceso (ACL) del archivo:
    *   **Bloquea la Herencia:** Evita que el archivo herede permisos de su carpeta principal. Esto lo aísla de cualquier cambio de seguridad futuro.
    *   **Deniega a Todos:** Agrega una regla explícita de `Denegar FullControl` para el grupo `Todos`. En Windows, una regla explícita de `Denegar` siempre anula cualquier regla de `Permitir`. Esto significa que ningún usuario, **ni siquiera un Administrador**, puede escribir, modificar o eliminar el archivo.
    *   **Otorga Control a SYSTEM:** Asegura que solo la cuenta `NT AUTHORITY\SYSTEM` o `TrustedInstaller` tenga `FullControl`. Esto es necesario para la integridad del sistema, pero es una cuenta que el malware (y los usuarios) no pueden usar fácilmente.
4.  **👻 Volverse Invisible:** Finalmente, establece los atributos del archivo en `Oculto` y `Sistema`, ocultándolo de la vista estándar en el Explorador de Archivos para evitar descubrimientos o manipulaciones accidentales.

---

## ⚠️ Advertencias Importantes y Cómo Deshacer

> [!WARNING]
> **Este script crea un archivo que es *intencionalmente* difícil de eliminar, incluso para ti.** No ejecutes esto en ningún archivo al que puedas necesitar acceder más tarde. Está diseñado específicamente para bloquear rutas de malware conocidas.

### Cómo Eliminar Manualmente un Archivo Señuelo Bloqueado

Si alguna vez necesitas eliminar los señuelos, debes revertir manualmente la protección como **Administrador**.

1.  **Abrir una Terminal de Administrador** (`Win + X` > Terminal (Administrador)).
2.  **Tomar Posesión** del archivo. Reemplaza la ruta con la correcta.
    *Para el archivo de usuario:*
    ```cmd
    takeown /f "%APPDATA%\Gallery.exe"
    ```
    *Para el archivo del sistema:*
    ```cmd
    takeown /f "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe"
    ```
3.  **Restablecer Permisos** para heredar de la carpeta principal.
    *Para el archivo de usuario:*
    ```cmd
    icacls "%APPDATA%\Gallery.exe" /reset
    ```
    *Para el archivo del sistema:*
    ```cmd
    icacls "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe" /reset
    ```
4.  Ahora puedes **eliminar el archivo** normalmente.
    ```powershell
    Remove-Item -Path "$env:APPDATA\Gallery.exe" -Force
    ```

---

## 🔎 Solución de Problemas y Preguntas Frecuentes

| Síntoma / Pregunta | Solución / Explicación |
| :--- | :--- |
| ❌ **Error "Acceso denegado" durante la ejecución del script.** | Esto es esperado si lo estás ejecutando como Administrador en lugar de SYSTEM. El script no puede establecer a `SYSTEM` como propietario. **Usa el método PsExec para una protección completa.** |
| 📜 **Error "La ejecución de scripts está deshabilitada en este sistema".** | Este es un error de la Política de Ejecución de PowerShell. Puedes omitirlo para el proceso actual ejecutando `Set-ExecutionPolicy Bypass -Scope Process -Force` antes de ejecutar el script principal. |
| 🪟 **No puedo ver el archivo `Gallery.exe` en el Explorador de Archivos.** | Esto es intencional. El archivo está oculto. Para verlo, ve al Explorador de Archivos > `Vista` > `Opciones` > pestaña `Ver`, y marca **"Mostrar archivos ocultos..."** y desmarca **"Ocultar archivos protegidos del sistema operativo"**. |
| 🗑️ **¡No puedo eliminar el archivo, incluso como Administrador!** | ¡Esto significa que el script funciona correctamente! Está diseñado para bloquear a todos, incluyéndote a ti. Sigue los pasos en la sección **[Cómo Deshacer](#️-advertencias-importantes--cómo-deshacer)** para eliminarlo. |
| 🤔 **¿Por qué es tan importante ejecutar como `SYSTEM`?** | La cuenta `SYSTEM` es la máxima autoridad en Windows. Al hacer que `SYSTEM` sea el propietario del señuelo, se evita que incluso un Administrador lo modifique fácilmente sin tomar posesión explícitamente primero. El malware que se ejecuta con derechos de administrador será bloqueado, lo cual es una gran victoria de seguridad. |

---

## 📜 Licencia

Este proyecto es de código abierto y se distribuye bajo la [Licencia MIT](https://github.com/i-am-aka/readme-assets/blob/main/LICENSE). Eres libre de usarlo, compartirlo y modificarlo.

---

## 📥 Descargar el README Original

```bash
curl -o README.md https://raw.githubusercontent.com/i-am-aka/Gallery-Lock/main/README.md
```
