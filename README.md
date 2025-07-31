## Installer

Die aktuelle Setup-Version findest du unter [Releases](https://github.com/Blondie-61/HiddenScheduler/releases).

Mit dem Setup werden alle benötigten Dateien installiert und die Kontextmenü-Einträge registriert. Optional kann Autostart aktiviert werden.

## 🛠 Selbst kompilieren

Das Projekt wurde erstellt mit **Delphi 11.3 Alexandria**.

### Voraussetzungen

- **Delphi 11.3** oder kompatible Version
- **Virtual TreeView** (benötigt zur Anzeige der Dateiliste)

  → [Download: Virtual TreeView Releases](https://github.com/JAM-Software/Virtual-TreeView/releases/latest)

### Kompilierung

1. Virtual TreeView laden und entpacken
2. Die Datei `VirtualTrees.pas` ins Projekt einbinden oder Bibliothekspfad setzen
3. `Sleep_con.dproj` und `WakeHidden.dproj` mit Delphi öffnen und kompilieren
4. Optionale Ressourcen: Icons, WAV-Datei (`icq-uh-oh.wav`) im gleichen Verzeichnis
