# Kämpfe und Events hinzufügen

Die Inhalte sind getrennt:
- Battles.json: normale Duelle
- Events.json: Events
- Enemies.json: Gegner und Decks
- Characters.json: Charaktere

BattleCatalog.json enthält nur die vier Dateinamen und die Schema-Version. Es ist das kleine Ladeverzeichnis, keine zweite Kopie der Inhalte. Duelle und Events verwenden dasselbe Eintragsformat. Jede Inhaltsdatei ist ein JSON-Array.

1. Kopiere einen Eintrag in Battles.json oder Events.json und vergib eine neue, eindeutige id.
2. Setze enemyID auf eine ID aus Enemies.json. Gegner definieren LP, Schwierigkeit und deckCardIDs aus cards.json.
3. requiredAccountLevel legt die Freischaltung fest. Es muss auch die Levelanforderung des Gegners erfüllt sein.
4. rewards enthält coins, crystals und experience. Diese Werte werden bei einem Sieg pro Durchlauf einmal ausgezahlt. Wiederholte Siege sind erlaubt; Abbruch, Niederlage und Unentschieden geben nichts.
5. appearance steuert die Farben der Auswahlkarte und des Kampfes:
   - accentHex: Akzent als #RRGGBB
   - backgroundTopHex / backgroundBottomHex: Hintergrundfarben als #RRGGBB
   - shaderHue: Farbverschiebung des Metal-Hintergrunds in Grad (-360 bis 360)
   - shaderIntensity: Helligkeit (0 bis 2)
6. startsAt und endsAt sind null für dauerhafte Verfügbarkeit oder ISO-8601-Zeitpunkte wie 2026-12-01T00:00:00Z. Der Endzeitpunkt ist exklusiv.

Beispiel für Belohnungen:

```json
"rewards": { "coins": 250, "crystals": 5, "experience": 80 }
```

ResourceManager.swift verwaltet den einzigen Account-Ressourcenstand und speichert ihn lokal. Ein Level benötigt Level × 100 EXP; überschüssige EXP bleiben erhalten. Der Header wird automatisch aktualisiert.

MenuView besitzt genau einen CyberAccountHeader und einen CyberFooter für alle Menübereiche. Kämpfe öffnen sich bildschirmfüllend mit ihrem Kampf-HUD und kehren danach zur Auswahl zurück.

Die JSON-Dateien werden aus dem App-Bundle geladen. Änderungen wirken beim nächsten Laden der App. Es ist kein Server oder zusätzlicher Code pro Kampf notwendig.

## Energie

Jeder Eintrag in Battles.json und Events.json benötigt `"energyCost": 10` (1 bis 100). Energie wird beim Start und bei jeder Wiederholung abgezogen. Abbrüche erstatten keine Energie. Bei unzureichender Energie startet kein Kampf.

ResourceManager.swift definiert 100 maximale Energie und 300 Sekunden pro regeneriertem Punkt. Energie und Regenerationszeit werden lokal gespeichert; Offline-Zeit zählt mit. Alte Spielstände erhalten einmalig volle Energie, ohne andere Ressourcen zu verlieren. Der Account-Header zeigt den Stand in 20 schrägen Segmenten.
