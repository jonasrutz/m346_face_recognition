# M346 Face Recognition Service

Cloud-basierter Face-Recognition-Service mit AWS S3, AWS Lambda und AWS Rekognition.
Beim Upload eines Bildes in den Input-Bucket wird automatisch eine Lambda-Funktion ausgeloest. Die Funktion analysiert das Bild mit Rekognition und speichert das Ergebnis als JSON im Output-Bucket.

## Team und Autorenschaft

- Jonas Rutz
- Alexej

## Ziel des Projekts

Dieses Projekt implementiert einen ereignisgesteuerten Cloud-Service, der bekannte Persoenlichkeiten in Bildern erkennt und die Resultate maschinenlesbar bereitstellt.

Fachliche Ziele:

- Event-Driven Processing mit AWS Services umsetzen
- Cloud-Ressourcen automatisiert bereitstellen
- Nachvollziehbare, reproduzierbare Tests dokumentieren
- Wartbare und erweiterbare Loesung liefern

## Architekturueberblick

1. Bild wird in `face-rekog-in-<ACCOUNT_ID>` hochgeladen.
2. S3 Event `ObjectCreated` triggert `FaceRekognitionFunction`.
3. Lambda liest das Bild und ruft `rekognition.recognize_celebrities` auf.
4. JSON-Resultat wird in `face-rekog-out-<ACCOUNT_ID>` gespeichert.
5. `scripts/Test.sh` laedt das Resultat und zeigt die wichtigsten Werte lesbar an.

## Repository-Struktur

```text
.
|- README.md
|- DOKUMENTATION.md
|- CodeLegende.md
|- scripts/
|  |- Init.sh
|  |- Test.sh
|- src/
	|- lambda_function.py
```

## Voraussetzungen

- AWS Learner Lab / AWS Account mit aktiver CLI-Anmeldung
- AWS CLI v2
- Bash-Umgebung (Git Bash, WSL oder Linux/macOS)
- Python 3.x (fuer lokalen JSON-Output in `Test.sh`)
- Region: `us-east-1`

## Setup und Deployment

Aus dem Ordner `scripts/` ausfuehren:

```bash
bash Init.sh
```

Was das Skript erledigt:

- Ermittelt `ACCOUNT_ID`
- Erstellt Input- und Output-Bucket (idempotent)
- Packt die Lambda-Funktion
- Erstellt oder aktualisiert Lambda
- Setzt Umgebungsvariable `OUT_BUCKET`
- Konfiguriert Invoke-Berechtigung S3 -> Lambda
- Konfiguriert S3 Event Notification

## Funktionstest durchfuehren

```bash
bash Test.sh <pfad-zum-bild.jpg>
```

Erwartetes Verhalten:

- Bild wird in den Input-Bucket hochgeladen
- Lambda wird automatisch ausgefuehrt
- JSON-Datei `<bildname>.json` entsteht im Output-Bucket
- Terminal zeigt erkannte Celebrities mit `MatchConfidence`

## Testnachweise (mit Platzhaltern fuer Screenshots)

Hinweis: Die finalen Screenshots werden vor der Abgabe eingefuegt.

1. Infrastruktur erfolgreich erstellt
- Platzhalter: `docs/screenshots/01-init-success.png`
- Inhalt: Ausgabe von `Init.sh` mit `Setup Complete`

2. Testlauf erfolgreich
- Platzhalter: `docs/screenshots/02-test-success.png`
- Inhalt: Ausgabe von `Test.sh` mit erkannter Person und Confidence

3. Resultatdatei im S3 Output-Bucket
- Platzhalter: `docs/screenshots/03-s3-output-json.png`
- Inhalt: S3 Console mit erzeugter `<bildname>.json`

4. CloudWatch Logs der Lambda-Funktion
- Platzhalter: `docs/screenshots/04-cloudwatch-log.png`
- Inhalt: Logzeilen mit verarbeitetem Dateinamen und Erfolgsmeldung

## Qualitaetsmerkmale

- Reproduzierbarkeit: Deployment via `Init.sh` ohne manuelle Klickpfade
- Robustheit: `set -e`, idempotente Bucket-/Lambda-Logik, Fehlerabbruch
- Nachvollziehbarkeit: saubere Struktur, `CodeLegende.md`, ausfuehrliche Doku
- Wartbarkeit: klare Trennung zwischen Deployment, Laufzeitcode und Testskript
- Erweiterbarkeit: JSON-Output eignet sich fuer API/Frontend/Analytics

## Sicherheit und Betrieb

- Berechtigungen laufen ueber LabRole (Least Privilege im Lab-Rahmen)
- S3 darf Lambda gezielt ueber `add-permission` aufrufen
- Keine Secrets im Quellcode
- Fehler und Laufzeitverhalten sind in CloudWatch nachvollziehbar

## Bekannte Grenzen

- Erkennung basiert auf `RecognizeCelebrities`, nicht auf generischer Gesichtserkennung
- Konfidenzwerte koennen je nach Bildqualitaet stark variieren
- Der Test nutzt feste Wartezeit (`sleep 8`), bei Last kann mehr Zeit noetig sein

## Weiterfuehrung

- Asynchrone Statuspruefung statt fixer Wartezeit
- Speicherung zusaetzlicher Metadaten (Zeitstempel, Bildgroesse)
- Optionale API (API Gateway + Lambda) fuer direkte Abfrage

## Verweise

- Technische Detaildokumentation: `DOKUMENTATION.md`
- Code-Erklaerung auf Skript-Ebene: `CodeLegende.md`
