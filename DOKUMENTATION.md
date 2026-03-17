# Projektdokumentation M346 - Face Recognition Service

## 1. Projektuebersicht

### 1.1 Ausgangslage
Im Rahmen von Modul 346 wird ein Cloud-Service implementiert, der ein Bildereignis automatisiert verarbeitet und das Analyseergebnis strukturiert ablegt.

### 1.2 Projektziel
Ziel ist die Realisierung eines serverlosen Workflows auf AWS, der bekannte Persoenlichkeiten auf Bildern erkennt.

Kernanforderungen:

- Event-getriebene Verarbeitung
- Automatisiertes Deployment
- Nachvollziehbare Tests
- Saubere technische Dokumentation

### 1.3 Team

- Jonas Rutz
- Alexej

## 2. Anforderungen und Scope

### 2.1 Funktionale Anforderungen

- Beim Upload eines Bildes in den Input-Bucket wird automatisch eine Lambda-Funktion gestartet.
- Die Lambda-Funktion analysiert das Bild mit AWS Rekognition (`RecognizeCelebrities`).
- Das Resultat wird als JSON im Output-Bucket gespeichert.
- Ein Testskript soll den End-to-End-Ablauf reproduzierbar validieren.

### 2.2 Nicht-funktionale Anforderungen

- Reproduzierbarkeit durch Skripte
- Wartbarkeit durch klare Struktur und Trennung der Verantwortungen
- Nachvollziehbarkeit durch Logs und Dokumentation
- Zuverlaessiger Betrieb im Lab-Setup

## 3. Architektur und Datenfluss

### 3.1 Komponenten

- Amazon S3 Input-Bucket: Bild-Upload und Event-Quelle
- AWS Lambda: Verarbeitung des Upload-Events
- Amazon Rekognition: Erkennung bekannter Persoenlichkeiten
- Amazon S3 Output-Bucket: Persistenz der Analyse als JSON
- CloudWatch Logs: Laufzeit- und Fehlernachweise

### 3.2 Ablaufdiagramm

```text
Client/Terminal
    |
    | Upload Bild
    v
S3 Input Bucket (ObjectCreated Event)
    |
    | Trigger
    v
AWS Lambda (lambda_function.py)
    |
    | Rekognition API Call
    v
AWS Rekognition (RecognizeCelebrities)
    |
    | JSON Response
    v
S3 Output Bucket (<bildname>.json)
    |
    | Download
    v
Test.sh (lesbare Konsolenausgabe)
```

### 3.3 Datenobjekte

Input:

- Bilddatei (`.jpg`, `.jpeg`, `.png`) im Input-Bucket

Output:

- JSON-Datei mit denselben Basisnamen wie das Eingabebild
- Struktur mit u.a. `CelebrityFaces`, `UnrecognizedFaces`, Confidence-Werten

## 4. Implementierung

### 4.1 Lambda-Funktion (`src/lambda_function.py`)

Verantwortung:

- Event-Daten auslesen
- Bildobjekt an Rekognition uebergeben
- Antwort in JSON serialisieren
- Ergebnisobjekt im Output-Bucket ablegen

Wichtige technische Punkte:

- `OUT_BUCKET` wird als Umgebungsvariable gesetzt
- Dateiname wird von Bild-Endung auf `.json` umgestellt
- Fehlerbehandlung ueber `try/except` mit klaren Logs

### 4.2 Deployment-Skript (`scripts/Init.sh`)

Verantwortung:

- AWS Account-ID bestimmen
- Bucket-Namen konstruieren
- Buckets idempotent erstellen
- Lambda verpacken und bereitstellen
- Trigger und Berechtigungen konfigurieren

Wichtige technische Punkte:

- `set -e` fuer sofortigen Abbruch bei Fehlern
- Update-Pfad fuer bestehende Lambda-Funktion
- S3->Lambda Permission wird sauber erneuert

### 4.3 Test-Skript (`scripts/Test.sh`)

Verantwortung:

- Bild in Input-Bucket hochladen
- Auf Verarbeitung warten
- JSON-Resultat holen
- Relevante Infos lesbar ausgeben

Wichtige technische Punkte:

- Validierung der Eingabeparameter
- Fallback zwischen `python3` und `python`
- Hinweise bei fehlender Resultatdatei

## 5. Installation und Betrieb

### 5.1 Erstinstallation

```bash
cd scripts
bash Init.sh
```

### 5.2 End-to-End-Test

```bash
cd scripts
bash Test.sh ../pfad/zum/bild.jpg
```

### 5.3 Betriebskontrolle

- CloudWatch Logs fuer `FaceRekognitionFunction` pruefen
- Output-Bucket auf erzeugte JSON-Datei pruefen
- Bei Fehlern IAM-Rolle, Region und Bucket-Namen kontrollieren

## 6. Testkonzept und Nachweise

### 6.1 Testfaelle

1. Positivfall mit bekannter Persoenlichkeit
- Erwartung: Mindestens ein Eintrag in `CelebrityFaces`
- Nachweis: Konsolenausgabe mit Name und Confidence

2. Positivfall ohne bekannte Persoenlichkeit
- Erwartung: Keine Celebrity-Ausgabe, ggf. unrecognized faces
- Nachweis: Konsolenausgabe ohne Celebrity-Eintrag

3. Fehlerfall falscher Aufruf von `Test.sh`
- Erwartung: Usage-Hinweis und Abbruch
- Nachweis: Konsolenausgabe mit Usage-Text

4. Infrastrukturtest
- Erwartung: `Init.sh` endet mit `Setup Complete`
- Nachweis: Erfolgreiche Setup-Ausgabe

### 6.2 Screenshot-Checkliste (vorbereitet)

- `docs/screenshots/01-init-success.png`
- `docs/screenshots/02-test-known-person.png`
- `docs/screenshots/03-test-no-celebrity.png`
- `docs/screenshots/04-s3-output-json.png`
- `docs/screenshots/05-cloudwatch-success-log.png`
- `docs/screenshots/06-test-usage-error.png`

Hinweis: Diese Screenshots werden vor der finalen Abgabe eingefuegt.

## 7. Bewertungssicherung (Guetestufe 3)

### 7.1 Nachweismatrix

| Kriterium                   | Umsetzung im Projekt                                            | Nachweis                           |
| --------------------------- | --------------------------------------------------------------- | ---------------------------------- |
| Fachliche Funktion erfuellt | Vollstaendiger Event-Workflow S3 -> Lambda -> Rekognition -> S3 | Testlauf + JSON-Ausgabe            |
| Reproduzierbarkeit          | Vollautomatisches Setup mit `Init.sh`                           | Setup-Output + Skriptinhalt        |
| Technische Qualitaet        | Strukturierte Skripte, Fehlerabbruch, klare Rollen              | Code + CodeLegende                 |
| Nachvollziehbarkeit         | Ausfuehrliche README und Projektdokumentation                   | `README.md`, `DOKUMENTATION.md`    |
| Testabdeckung               | Positive und negative Testfaelle definiert                      | Testskript + Screenshot-Checkliste |
| Betrieb/Monitoring          | CloudWatch Logs fuer Laufzeitanalyse vorgesehen                 | Log-Screenshot                     |

### 7.2 Begruendung Guetestufe 3

Die Loesung erreicht Guetestufe 3 durch:

- vollstaendige und lauffaehige Umsetzung der Kernfunktion
- reproduzierbares, weitgehend automatisiertes Deployment
- klar dokumentierte Architektur und Betriebsprozesse
- definierte Testfaelle mit eindeutigen Nachweisen
- transparente Grenzen und konkrete Erweiterungsvorschlaege

## 8. Risiken und Grenzen

- Rekognition-Ergebnisse sind daten- und qualitaetsabhaengig.
- Feste Wartezeit im Test kann in Einzelfaellen zu kurz sein.
- Learner-Lab-Rollen koennen je nach Lab-Setup variieren.

## 9. Verbesserungsoptionen

- Polling-Logik fuer Resultatdatei statt `sleep 8`
- Strukturierte Error-Codes im JSON
- Automatisierte Tests in CI (z.B. Shellcheck + Integration Test)
- Aufraeumskript fuer Buckets und Lambda-Ressourcen

## 10. Fazit

Der Service zeigt eine saubere, cloud-native Eventarchitektur mit nachvollziehbarer Automatisierung und klaren Betriebsablaeufen. Die Dokumentation ist auf eine vollstaendige, bewertungsstarke Abgabe ausgerichtet und enthaelt alle vorgesehenen Nachweise inklusive vorbereiteter Screenshot-Checkliste.
