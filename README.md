### H Navigator

H Navigator is a highly-modified, privacy-hardened service runtime and web browser for H-Linux, built on Brave Origin (nightly).

---

#### Unique Features

*   **H-Profile Interpreter (w/ legacy-fallback):** A native interpreter for profile administration, backups and restoration.
*   **Blockchain Entropy (w/ fallback-mode):** Anonymous, local key generation maximizing runtime unpredictability and cryptographic security.
*   **Pulse:** A zero-CPU C-based heartbeat monitor with graceful termination features.
*   **Sextant Integration:** Live core monitoring via the `sextant.sh` script.
*   **Tamper-proof builds:** Air-gapped, dual-SHA-512 .dsigned caching mechanism guaranteeing integrity of packages before execution during build.
*   **Singleton Jailbreak:** Automated stale-lock removal.
*   **Hardened Flags:** Pre-configured for H-Linux proxy server usage and user-data standards.
*   **Unique Identity:** Dynamic window enforcement.

---

#### Structure

*   `INSTALL.hash`: The automated deployment and patching script.
*   `PKGBUILD`: The configuration for building the `h-navigator` package on H-Linux.
*   `patch/`: Contains a patched launcher for syntax correction and improved system-level integration.
*   `components/`: Contains the SEXTANT monitor tool.
*   `assets/`: Contains additional graphic components.

---

#### Dependencies

Ensure the following are installed and available on GNU Operating System / H-Linux for core functionality:

*   `GNU Operating System / H-Linux`
*   `Hash`
*   `Human command layer`
*   `H-Linux env library`
*   `nullfsvfs-dkms`
*   `GCC + Clang`
*   `ccache`

---

#### Prerequisites

Also, ensure the following are installed on GNU Operating System / H-Linux for intended functionality:

*   **Logic & UI:** `xdotool`, `zenity`, `openssl`, `coreutils` 
*   **Branding:** `viu`, `figlet`
*   **Monitoring:** `procps-ng`
*   **Terminal consoles:** `cherry-terminal` and `xterm`

---

#### Build and Installation

To build and install H Navigator and its associated components on H-Linux:

1. Open **Cherry Terminal+** and navigate to the project directory.

2. Grant execution permissions to the installer:
   `> chmod +x INSTALL.hash`

3. Execute the installer:
   `> ./INSTALL.hash`

---

#### License

H Navigator and its associated scripts are distributed under the **Mozilla Public License 2.0 (MPL 2.0)**. 

Copyright (c) 2026 Harmonious Platform Systems
