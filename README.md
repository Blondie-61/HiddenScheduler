## Installer

Die aktuelle Setup-Version findest du unter [Releases](https://github.com/Blondie-61/HiddenScheduler/releases).

Mit dem Setup werden alle benötigten Dateien installiert und die Kontextmenü-Einträge registriert. Optional kann Autostart im Setup aktiviert werden.

# HiddenScheduler

Ein kleines Windows-Tool zum temporären Verstecken von Dateien über das Explorer-Kontextmenü.  
Dateien werden für eine bestimmte Zeit unsichtbar gemacht und automatisch wieder eingeblendet – z. B. nach 1h, morgen früh oder am Wochenende. Ideal für Desktop-Aufräumer, Datenverstecker oder Aufschieber. 😎

---

## 🔧 Funktionen

- Versteckt Dateien mit einem Rechtsklick („Schlafen …“) für:
  - 1h, 2h, 4h
  - Bis morgen früh
  - Am Wochenende
  - Oder benutzerdefiniert
- Automatisches Wiederherstellen durch das Tray-Tool `WakeHidden.exe`
- Setup inklusive:
  - Uninstaller
  - Optionalem Autostart des Tray-Tools (`WakeHidden.exe`)

---

## 📦 Installer

Die aktuelle Setup-Version findest du unter [Releases](https://github.com/Blondie-61/HiddenScheduler/releases).

Nach der Installation ist das Kontextmenü sofort verfügbar.

---

## 🛠 Selbst kompilieren

Das Projekt wurde erstellt mit **Delphi 11.3 Alexandria**.

### Voraussetzungen

- **Delphi 11.3** oder kompatible Version
- **Virtual TreeView**  
  → [Download: Virtual TreeView Releases](https://github.com/JAM-Software/Virtual-TreeView/releases/latest)

### Kompilierung

1. Virtual TreeView herunterladen und entpacken
2. Datei `VirtualTrees.pas` ins Projekt einbinden oder Pfad konfigurieren
3. `Sleep_con.dproj` und `WakeHidden.dproj` mit Delphi öffnen und kompilieren
4. Icons und WAV-Datei (`icq-uh-oh.wav`) müssen im EXE-Verzeichnis liegen

---

## 🚧 Roadmap

### ✅ Version 1.0.0 (veröffentlicht)
- Kontextmenü „Schlafen …“ mit festen Zeitoptionen
- Tray-Programm zur automatischen Reaktivierung
- Setup mit Uninstaller
- Optionaler Autostart des Tray-Tools (über Setup-Task)
- Silent-Installer (Setup selbst, **nicht** Programmfunktionen)

### 🛠 Geplant für Version 1.1.0
- Autostart-Option im Programm (konfigurierbar)
- Integrierte Update-Funktion im Tray-Tool
- Erweiterte Tray-Optionen (z. B. „Jetzt alles aufwecken“)
  - Unterstützung für Silent-Installation (`/silent`, `/verysilent`)
    
### 🧪 Ideen für spätere Versionen
- Option: Verstecken nur, wenn Datei älter als X Minuten
- Unterstützung für Ordner
- Dark Mode für GUI
- Lokalisierung (Deutsch/Englisch)
- Zeitregelung mit Kalender-Auswahl

---

## 📝 Lizenz

MIT License – siehe [LICENSE](LICENSE).
