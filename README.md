# Face Recognition Service (AWS Learner Lab)

Dieses Projekt stellt einen Cloud-Service bereit, der auf Basis von AWS S3 und AWS Lambda automatisch bekannte Persönlichkeiten (Celebrities) auf hochgeladenen Fotos erkennt und die detaillierten JSON-Resultate speichert. 

## Inhaltsverzeichnis
- [Voraussetzungen](#voraussetzungen)
- [Inbetriebnahme / Deployment](#inbetriebnahme--deployment)
- [Nutzung und manueller Test](#nutzung-und-manueller-test)
- [Code-Erklärung](#code-erklärung)

---

## Voraussetzungen
Damit die Skripte einwandfrei funktionieren, müssen folgende Bedingungen erfüllt sein:
1. **AWS Umgebung**: Du befindest dich im _AWS Learner Lab_ (verwendet die Rolle `LabRole`).
2. **AWS CLI**: Auf deinem Rechner (oder in der AWS CloudShell) ist die AWS Command Line Interface (CLI) installiert und mit deinen Credentials (aus den Learner Lab Details) konfiguriert.
3. **Betriebssystem**: Du benötigst eine Bash-Umgebung (z.B. Git Bash für Windows, Linux, Mac oder AWS CloudShell).

---

## Inbetriebnahme / Deployment

Die komplette Einrichtung der Cloud-Infrastruktur (S3 Buckets inkl. Trigger, Permissions und Lambda-Code) erfolgt vollautomatisch über das `Init.sh` Skript.

1. Öffne dein Bash-Terminal und navigiere in den Ordner `scripts/`:
   ```bash
   cd scripts
   ```
2. Mache das Skript (falls nötig) ausführbar und starte es:
   ```bash
   bash Init.sh
   ```
3. Das Skript zeigt in der Konsole an, welche Komponenten erstellt werden (S3 Buckets, Zip-File, IAM Permissions, etc.). Am Ende meldet es `Setup Complete!`.

> **Hinweis:** Das Skript ist "idempotent". Das heisst, man kann es so oft ausführen, wie man möchte, ohne dass es duplizierte Ressourcen oder Fehler generiert. Das ist besonders praktisch, wenn man nach einer Anpassung am Python-Code (`src/lambda_function.py`) den Service kurzerhand updaten will.

---

## Nutzung und manueller Test

Wenn die Cloud-Umgebung einmal steht, funktioniert der Service vollautomatisch, sobald ein neues Bild in den Input-Bucket geladen wird. 

Wir haben dafür ein Test-Skript (`Test.sh`) geschrieben, mit dem dieser Prozess via Terminal ganz einfach simuliert werden kann:

1. Suche ein Foto einer bekannten Persönlichkeit aus (z.B. `merkel.jpg`) und speichere es idealerweise direkt neben den Skripten.
2. Führe im `scripts/` Ordner das Test-Skript mit dem Namen deines Bildes aus:
   ```bash
   bash Test.sh /pfad/zu/dem/bild/merkel.jpg
   ```

**Was macht das Skript?**
1. Lädt dein Bild in den (mit deiner Account-ID benannten) In-Bucket auf S3 hoch.
2. Wartet wenige Sekunden (die Lambda Funktion in der Cloud wird im Hintergrund automatisch getriggert, analysiert das Bild mit **AWS Rekognition** und speichert das Ergebnis im Out-Bucket).
3. Das Test-Skript lädt anschliessend die fertige `.json` Datei aus dem Out-Bucket wieder herunter.
4. Es analysiert die Datei und gibt dir die Ergebnisse (Gefundene Personen inkl. Wahrscheinlichkeit in %) gut lesbar im Terminal aus.

---

## Code-Erklärung
Die exakte Erklärung der Zeilen in den Files (`lambda_function.py`, `Init.sh`, `Test.sh`) findet man in der separaten Datei **[CodeLegende.md](CodeLegende.md)**.
