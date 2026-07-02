### H Navigator

H Navigator is a highly-modified, privacy-hardened runtime and web browser for H-Linux, based on Brave Origin (nightly).

---

#### Structure

*   `INSTALL.sh`: The automated deployment and patching script.
*   `PKGBUILD`: The configuration for building the `h-navigator` package on H-Linux.
*   `patch/`: Contains a patched launcher for syntax correction and improved system-level integration.
*   `components/`: Contains the SEXTANT monitor tool.
*   `assets/`: Contains additional graphic components.

---

#### Prerequisites

Ensure the following are installed on H-Linux for intended functionality:

*   **Logic & UI:** `xdotool`, `zenity`, `openssl`, `coreutils`
*   **Branding:** `viu`, `figlet`
*   **Monitoring:** `procps-ng`
*   **Terminal consoles:** `cherry-terminal` and `xterm`

---

#### Build and Installation

To build and install H Navigator and its associated components on H-Linux:

1. Open a terminal console and navigate to the project directory.
2. Grant execution permissions to the installer:
   `chmod +x INSTALL.sh`
3. Execute the installer:
   `./INSTALL.sh`

---

#### Unique Features

*   **Singleton Jailbreak:** Automated stale-lock removal.
*   **Sextant Integration:** Live core monitoring via the `sextant.sh` script.
*   **Hardened Flags:** Pre-configured for H-Linux proxy server usage and user-data standards.
*   **Unique Identity:** Dynamic window enforcement.

---

#### License

H Navigator and its associated scripts are distributed under the **Mozilla Public License 2.0 (MPL 2.0)**. 

Copyright (c) 2026 Harmonious Platform Systems
