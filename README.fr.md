# 🛡️ Gallery-Lock : Le Leurre Indestructible

<p align="center">
  <strong>Un script PowerShell "à configurer et à oublier" qui crée un obstacle permanent et indestructible pour bloquer le malware <code>Gallery.exe</code> et empêcher sa réinfection.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-5.1+-blue.svg" alt="Version de PowerShell">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="Licence">
  <img src="https://img.shields.io/badge/Platform-Windows-lightgrey.svg" alt="Plateforme">
  <img src="https://img.shields.io/badge/Status-Active-brightgreen.svg" alt="Statut">
</p>

---

## Le Problème : Le Virus Ennuyeux `Gallery.exe`

Êtes-vous fatigué de supprimer le malware `Gallery.exe`, pour qu'il réapparaisse après un redémarrage ? Ce virus courant fonctionne en plaçant son exécutable dans des dossiers spécifiques à l'utilisateur et au système. Même après avoir nettoyé votre système, il revient souvent car la source d'infection d'origine (comme une tâche planifiée ou un autre processus caché) tente de le recréer.

## La Solution : Une Forteresse Numérique

**Gallery-Lock** ne se contente pas de supprimer le virus ; il construit une forteresse permanente à sa place. Le script crée des fichiers leurres de zéro octet (vides) nommés `Gallery.exe` aux emplacements exacts ciblés par le malware. Il applique ensuite des autorisations de sécurité (ACL) extrêmement strictes qui rendent ces leurres **impossibles à écraser ou à supprimer par le malware**.

Le résultat ? La tentative du malware de réinfecter votre système est bloquée au niveau du système d'exploitation, à chaque fois.

---

## 🚀 Fonctionnalités Clés

| Fonctionnalité | Description |
| :--- | :--- |
| ✅ **Éradique les Infections Existantes** | Trouve et supprime automatiquement tous les fichiers `Gallery.exe` actuels des emplacements de logiciels malveillants connus. |
| 🛡️ **Crée des Leurres Immuables** | Génère des fichiers de remplacement vides et les verrouille. |
| 🔒 **Durcissement Avancé des ACL** | Utilise des listes de contrôle d'accès (ACL) pour `REFUSER` toutes les autorisations à tout le monde, y compris les administrateurs. Seul le compte `SYSTEM` principal conserve le contrôle. |
| 🕵️ **Furtif et Invisible** | Les fichiers leurres sont définis comme des fichiers `Cachés` et `Système`, ce qui les rend invisibles lors d'une utilisation normale. |
| 📈 **Journalisation Claire et Informative** | Fournit des commentaires en temps réel et codés par couleur dans la console pour chaque action effectuée. |
| 📦 **Zéro Dépendance** | Un script PowerShell autonome qui s'exécute sur n'importe quel système Windows moderne sans nécessiter d'installations supplémentaires. |

---

## 🛠️ Comment Utiliser : Le Guide de 2 Minutes

Pour une efficacité maximale, le script doit être exécuté en tant que `SYSTEM`. C'est le plus haut niveau d'autorité sur Windows, même au-dessus de l'administrateur.

### Méthode Recommandée : Exécuter en tant que SYSTEM avec PsExec

C'est la **méthode la plus sécurisée** et garantit que le script peut appliquer ses protections les plus fortes.

1.  **Télécharger PsExec :**
    *   Téléchargez la **suite Sysinternals** officielle de Microsoft : [**Télécharger Ici**](https://learn.microsoft.com/en-us/sysinternals/downloads/psexec).
    *   Extrayez le fichier ZIP dans un emplacement simple, comme `C:\Sysinternals`.

2.  **Ouvrir un Terminal Administrateur :**
    *   Appuyez sur `Win + X` et sélectionnez **Terminal (Admin)** ou **Windows PowerShell (Admin)**.

3.  **Accéder au Dossier PsExec :**
    *   Dans le terminal, accédez au répertoire où vous avez extrait PsExec.
      ```powershell
      cd C:\Sysinternals
      ```

4.  **Lancer un PowerShell au Niveau SYSTEM :**
    *   Exécutez la commande suivante. Une nouvelle fenêtre PowerShell s'ouvrira avec les privilèges `SYSTEM`.
      ```powershell
      .\PsExec64.exe -i -s powershell.exe
      ```

5.  **Exécuter le Script Gallery-Lock :**
    *   Dans la **nouvelle fenêtre SYSTEM**, accédez à l'endroit où vous avez enregistré `Gallery-Lock.ps1`.
    *   Tout d'abord, définissez la politique d'exécution pour cette seule session, puis exécutez le script.
      ```powershell
      # Autoriser l'exécution du script dans cette fenêtre uniquement
      Set-ExecutionPolicy Bypass -Scope Process -Force

      # Exécuter le script (utiliser le chemin correct)
      .\Gallery-Lock.ps1
      ```

**C'est tout !** Les fichiers leurres sont maintenant en place et durcis. Vous pouvez fermer toutes les fenêtres.

<details>
  <summary><strong>Méthode Alternative : Exécuter en tant qu'Administrateur (Moins Sécurisé)</strong></summary>

  > [!NOTE]
  > Cette méthode fonctionne, mais la protection des fichiers n'est pas aussi forte car un administrateur peut toujours en prendre possession plus facilement. Elle n'est recommandée que si vous ne pouvez pas utiliser PsExec.

  1. **Cliquez avec le bouton droit** sur le fichier de script `Gallery-Lock.ps1`.
  2. Sélectionnez **"Exécuter avec PowerShell"**.
  3. Si vous y êtes invité, approuvez l'invite UAC (Contrôle de compte d'utilisateur) pour lui accorder les droits d'administrateur.

  Le script vous informera qu'il s'exécute en tant qu'administrateur et non en tant que SYSTEM.
</details>

---

## 🗺️ Emplacements des Fichiers Protégés

Le script crée et protège des leurres dans les chemins de logiciels malveillants standard suivants :

| Type de Profil | Chemin |
| :--- | :--- |
| **Profil Utilisateur** | `%APPDATA%\Gallery.exe` |
| **Profil Système** | `C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe` |

---

## 🧱 Comment Ça Marche : Une Analyse Technique

L'efficacité du script repose sur une stratégie de sécurité à plusieurs niveaux :

1.  **🔍 Analyser et Nettoyer :** Il vérifie d'abord et supprime tous les fichiers `Gallery.exe` existants dans les emplacements cibles, garantissant une table rase.
2.  **📝 Créer le Leurre :** Un fichier vide de 0 octet nommé `Gallery.exe` est créé. Il est inoffensif et ne prend pas de place.
3.  **🛡️ Construire la Forteresse (Durcissement des ACL) :** C'est l'étape la plus critique. Le script modifie la liste de contrôle d'accès (ACL) du fichier :
    *   **Bloque l'Héritage :** Il empêche le fichier d'hériter des autorisations de son dossier parent. Cela l'isole de tout changement de sécurité futur.
    *   **Refuse Tout le Monde :** Il ajoute une règle explicite `Deny FullControl` pour le groupe `Tout le monde`. Sous Windows, une règle `Deny` explicite l'emporte toujours sur les règles `Allow`. Cela signifie qu'aucun utilisateur, **même un administrateur**, ne peut écrire, modifier ou supprimer le fichier.
    *   **Accorde le Contrôle à SYSTEM :** Il garantit que seul le compte `NT AUTHORITY\SYSTEM` ou `TrustedInstaller` dispose de `FullControl`. C'est nécessaire pour l'intégrité du système mais c'est un compte que les logiciels malveillants (et les utilisateurs) ne peuvent pas utiliser facilement.
4.  **👻 Devenir Invisible :** Enfin, il définit les attributs du fichier sur `Caché` et `Système`, le cachant de la vue standard dans l'Explorateur de fichiers pour éviter toute découverte ou falsification accidentelle.

---

## ⚠️ Avertissements Importants et Comment Annuler

> [!WARNING]
> **Ce script crée un fichier qui est *intentionnellement* difficile à supprimer, même pour vous.** N'exécutez pas cela sur un fichier auquel vous pourriez avoir besoin d'accéder plus tard. Il est conçu spécifiquement pour bloquer les chemins de logiciels malveillants connus.

### Comment Supprimer Manuellement un Fichier Leurre Verrouillé

Si vous avez besoin de supprimer les leurres, vous devez inverser manuellement la protection en tant qu'**administrateur**.

1.  **Ouvrir un Terminal Administrateur** (`Win + X` > Terminal (Admin)).
2.  **Prendre Possession** du fichier. Remplacez le chemin par le bon.
    *Pour le fichier utilisateur :*
    ```cmd
    takeown /f "%APPDATA%\Gallery.exe"
    ```
    *Pour le fichier système :*
    ```cmd
    takeown /f "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe"
    ```
3.  **Réinitialiser les Autorisations** pour hériter du dossier parent.
    *Pour le fichier utilisateur :*
    ```cmd
    icacls "%APPDATA%\Gallery.exe" /reset
    ```
    *Pour le fichier système :*
    ```cmd
    icacls "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe" /reset
    ```
4.  Vous pouvez maintenant **supprimer le fichier** normalement.
    ```powershell
    Remove-Item -Path "$env:APPDATA\Gallery.exe" -Force
    ```

---

## 🔎 Dépannage et FAQ

| Symptôme / Question | Solution / Explication |
| :--- | :--- |
| ❌ **Erreur "Accès refusé" lors de l'exécution du script.** | C'est normal si vous l'exécutez en tant qu'administrateur au lieu de SYSTEM. Le script ne peut pas définir `SYSTEM` comme propriétaire. **Utilisez la méthode PsExec pour une protection complète.** |
| 📜 **Erreur "L'exécution de scripts est désactivée sur ce système".** | C'est une erreur de politique d'exécution de PowerShell. Vous pouvez la contourner pour le processus en cours en exécutant `Set-ExecutionPolicy Bypass -Scope Process -Force` avant d'exécuter le script principal. |
| 🪟 **Je ne vois pas le fichier `Gallery.exe` dans l'Explorateur de fichiers.** | C'est intentionnel. Le fichier est caché. Pour le voir, allez dans l'Explorateur de fichiers > `Affichage` > `Options` > onglet `Affichage`, et cochez **"Afficher les fichiers cachés..."** et décochez **"Masquer les fichiers protégés du système d'exploitation"**. |
| 🗑️ **Je ne peux pas supprimer le fichier, même en tant qu'administrateur !** | C'est le script qui fonctionne correctement ! Il est conçu pour bloquer tout le monde, y compris vous. Suivez les étapes de la section **[Comment Annuler](#️-avertissements-importants-et-comment-annuler)** pour le supprimer. |
| 🤔 **Pourquoi est-il si important d'exécuter en tant que `SYSTEM` ?** | Le compte `SYSTEM` est l'autorité ultime sur Windows. En faisant de `SYSTEM` le propriétaire du leurre, cela empêche même un administrateur de le modifier facilement sans en prendre explicitement possession au préalable. Les logiciels malveillants s'exécutant avec des droits d'administrateur seront bloqués, ce qui est un énorme gain de sécurité. |

---

## 📜 Licence

Ce projet est open-source et distribué sous la [Licence MIT](https://github.com/i-am-aka/readme-assets/blob/main/LICENSE). Vous êtes libre de l'utiliser, de le partager et de le modifier.

---

## 📥 Télécharger le README Original

```bash
curl -o README.md https://raw.githubusercontent.com/i-am-aka/Gallery-Lock/main/README.md
```
