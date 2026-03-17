# Code-Legende (Face Recognition Service)

Dieses Dokument erklärt die Funktionsweise der drei Haupt-Skripte des Projekts zeilen- bzw. abschnittsweise, nachdem die Kommentare im Code selbst für eine cleane Ansicht entfernt wurden.

## 1. `src/lambda_function.py`
Dieses Skript ist die AWS Lambda-Funktion, die in der Cloud ausgeführt wird, sobald ein neues Bild hochgeladen wird.

| Bereich / Befehl | Erklärung |
|---------|-----------|
| `import ...` | Lädt alle nötigen Python-Bibliotheken. `boto3` ist das AWS SDK für Python, `json` für Datenformate und `urllib` für URL-Dekodierung. |
| `s3 = boto3.client('s3')` | Initialisiert die Verbindung zum Datenspeicher (S3). |
| `rekognition = ...` | Initialisiert die Verbindung zur AWS Gesichtserkennungs-KI. |
| `def lambda_handler(...)` | Das ist die Hauptfunktion, die von AWS Lambda bei einem Event (z.B. Datei-Upload im Bucket) aufgerufen wird. |
| `out_bucket = ...` | Liest den Namen des Ziel-Buckets (wo die Resultate gespeichert werden sollen) aus den Umgebungsvariablen. |
| `bucket = event...` | Extrahiert den S3-Bucketnamen, in den das Bild gerade hochgeladen wurde, aus dem ausgelösten Event. |
| `key = urllib...` | Extrahiert den genauen Dateinamen des hochgeladenen Bildes. |
| `response = rekognition...`| Sendet das Bild an die AWS Rekognition KI, um bekannte Persönlichkeiten ("Celebrities") zu analysieren. |
| `file_name, _ = os.path...`| Tauscht die Datei-Endung (z.B. `.jpg`) gegen `.json` aus, um sie in diesem Format abzuspeichern. |
| `s3.put_object(...)` | Speichert das Ergebnis der KI (die `response`) als strukturierte Textdatei (JSON) im Output-Bucket ab. |

---

## 2. `scripts/Init.sh`
Dieses Skript automatisiert die komplette Bereitstellung (Deployment) der Cloud-Infrastruktur.

| Bereich / Befehl | Erklärung |
|------------------|-----------|
| `set -e` | Bricht das Skript sofort ab, falls irgendein Befehl einen Fehler wirft. |
| `ACCOUNT_ID=$(aws sts...)` | Fragt die eigene AWS Account-ID ab, um diese später für einzigartige Bucket-Namen zu verwenden. |
| `ROLE_ARN="arn:aws:..."` | Baut die Berechtigungs-Rolle (`LabRole`) zusammen, die im Learner Lab gebraucht wird. |
| `aws s3api create-bucket` | Erstellt die beiden benötigten Datenspeicher ("In-Bucket" für Bilder, "Out-Bucket" für Resultate). |
| `zip -rq lambda...` | Packt den Python-Code in ein `.zip`-Archiv, da AWS Lambda den Code in diesem Format verlangt. (Mit Fallback auf Python, falls `zip` fehlt). |
| `aws lambda create-function`| Erstellt die AWS Lambda Funktion in der Cloud, lädt den Code hoch und übergibt die Umgebungsvariablen (`OUT_BUCKET`). |
| `aws lambda wait ...` | Pausiert das Skript kurz, bis AWS die neue Lambda-Funktion vollständig aktiviert hat. |
| `aws lambda add-permission`| Erlaubt dem S3-Datenspeicher ausdrücklich, die Lambda-Funktion bei neuen Dateien aufzurufen. |
| `aws s3api put-bucket-notification...` | Verbindet den In-Bucket mit der Lambda-Funktion: Sobald eine Datei hochgeladen wird (`s3:ObjectCreated:*`), wird die Funktion getriggert. |

---

## 3. `scripts/Test.sh`
Dieses Skript dient als Test-Werkzeug, um einen Bild-Upload zu simulieren und das Resultat menschenleserlich in der Konsole auszugeben.

| Bereich / Befehl | Erklärung |
|------------------|-----------|
| `if [ "$#" -ne 1 ]; then` | Prüft, ob der Benutzer beim Skript-Aufruf genau einen lokalen Bildpfad mitgegeben hat. |
| `aws s3 cp "$IMAGE_PATH"...`| Lädt das lokale Bild in den AWS In-Bucket hoch. |
| `sleep 8` | Wartet 8 Sekunden. Das gibt der Cloud die Zeit, das Bild zu verarbeiten und das JSON-Ergebnis abzuspeichern. |
| `aws s3 cp s3:// ... /tmp/...`| Lädt die fertig analysierte `.json` Resultat-Datei aus dem Out-Bucket temporär herunter. |
| `$PYTHON_CMD -c ...` | Führt ein eingebautes Python-Skript im Terminal aus. Dieses öffnet die rohe JSON-Datei, sucht nach der gefundenen Person (`CelebrityFaces`) und gibt deren Namen und Wahrscheinlichkeit sauber formatiert auf der Konsole aus. |
