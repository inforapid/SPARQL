# PowerShell Skript: Erzeugt queries.sparql mit SPARQL-Queries für Albert Einstein

# Datei neu erstellen
$outputFile = "queries.sparql"
Set-Content -Path $outputFile -Value "" -Encoding UTF8

# Hauptthema (Level 0)
$level0 = @{ topic = "wd:Q937"; icVar = "ic_Discoverer" }

# Properties 1. Ebene
$level1Properties = @(
    @{ prop = "P61"; shortName = "discovery"; icVar = "ic_Discovery" }
)

# Properties 2. Ebene
$level2Properties = @(
    @{ prop = "P2579"; shortName = "recognized in"; icVar = "ic_Source" },
    @{ prop = "P279";  shortName = "superclass of"; icVar = "ic_Superclass" },
    @{ prop = "P1269"; shortName = "influences"; icVar = "ic_Influencer" }
)

# Template für die 1. Ebene (beachte das ? vor den Platzhaltern)
$level1Template = @"
SELECT * WHERE {{
  {{
    SELECT
      ?i_start ?i_startLabel ?i_startDescription ?{0} ?ii_startImage ?iu_startUrl
      ?rn_Name (?rn_Name AS ?rc_Category)
      ?i_end ?i_endLabel ?i_endDescription ?{1} ?ii_endImage ?iu_endUrl
    WHERE {{
      # Define the central node (Topic - Level 0)
      BIND({2} AS ?topic)
      
      # Get all child items connected to the topic
      ?childItem wdt:{3} ?topic .
      
      # Optional images
      OPTIONAL {{ ?topic wdt:P18 ?topicImage . }}
      OPTIONAL {{ ?childItem wdt:P18 ?childItemImage . }}
      
      # Bind variables for start and end nodes and images
      BIND(?topic AS ?i_start)
      BIND(?childItem AS ?i_end)
      BIND(?topicImage AS ?ii_startImage)
      BIND(?childItemImage AS ?ii_endImage)
      
      # Relation name placeholder
      BIND("{4}" AS ?rn_Name)
      
      # Standard Label Service for English labels and descriptions
      SERVICE wikibase:label {{ 
        bd:serviceParam wikibase:language "en". 
      }}
    }}
  }}
  
  # Filters to remove empty labels or descriptions
  FILTER(STRLEN(?i_startLabel) > 0)
  FILTER(STRLEN(?i_startDescription) > 0)
  FILTER(STRLEN(?i_endLabel) > 0)
  FILTER(STRLEN(?i_endDescription) > 0)
}}
"@

# Template für die 2. Ebene (beachte das ? vor den Platzhaltern)
$level2Template = @"
#query
SELECT * WHERE {{
  {{
    SELECT
      ?i_start ?i_startLabel ?i_startDescription ?{0} ?ii_startImage ?iu_startUrl
      ?rn_Name (?rn_Name AS ?rc_Category)
      ?i_end ?i_endLabel ?i_endDescription ?{1} ?ii_endImage ?iu_endUrl
    WHERE {{
      BIND({2} AS ?topic)
      
      # Get all child items connected to the topic
      ?childItem wdt:{3} ?topic .
      
      # Get grandchild items
      ?grandChildItem wdt:{4} ?childItem .
      
      # Optional images
      OPTIONAL {{ ?topic wdt:P18 ?topicImage . }}
      OPTIONAL {{ ?childItem wdt:P18 ?childItemImage . }}
      OPTIONAL {{ ?grandChildItem wdt:P18 ?grandChildItemImage . }}
      
      # Bind variables for start and end nodes and images
      BIND(?childItem AS ?i_start)
      BIND(?grandChildItem AS ?i_end)
      BIND(?childItemImage AS ?ii_startImage)
      BIND(?grandChildItemImage AS ?ii_endImage)
      
      # Relation name placeholder
      BIND("{5}" AS ?rn_Name)
      
      # Standard Label Service for English labels and descriptions
      SERVICE wikibase:label {{ 
        bd:serviceParam wikibase:language "en". 
      }}
    }}
  }}
  
  # Filters to remove empty labels or descriptions
  FILTER(STRLEN(?i_startLabel) > 0)
  FILTER(STRLEN(?i_startDescription) > 0)
  FILTER(STRLEN(?i_endLabel) > 0)
  FILTER(STRLEN(?i_endDescription) > 0)
}}
"@

# 1. Ebene Queries schreiben
foreach ($p1 in $level1Properties) {
    # Wir übergeben icVar von Level 0 und Level 1
    $query = $level1Template -f $level0.icVar, $p1.icVar, $level0.topic, $p1.prop, $p1.shortName
    Add-Content -Path $outputFile -Value $query -Encoding UTF8
}

# 2. Ebene Queries schreiben
foreach ($p1 in $level1Properties) {
    foreach ($p2 in $level2Properties) {
        $query = $level2Template -f $p1.icVar, $p2.icVar, $level0.topic, $p1.prop, $p2.prop, $p2.shortName
        Add-Content -Path $outputFile -Value $query -Encoding UTF8
    }
}

Write-Host "SPARQL-Queries mit korrekten Variablen (?ic_...) erfolgreich in $outputFile erstellt."