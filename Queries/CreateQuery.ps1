# PowerShell Skript: Erzeugt queries.sparql (Level 1 bis Level 3)

$outputFile = "queries.sparql"
# STEUERUNG: $true = Bilder sind optional, $false = Bilder sind Pflicht (Query liefert nur Ergebnisse mit Bildern)
$imagesOptional = $true 

if ($imagesOptional) {
    $optPrefix = "OPTIONAL { "
    $optSuffix = " }"
} else {
    $optPrefix = ""
    $optSuffix = ""
}

Set-Content -Path $outputFile -Value "" -Encoding UTF8

# Definitionen
$level0 = @{ topic = "wd:Q937"; icVar = "ic_Discoverer" }

$level1Properties = @(
    @{ prop = "P61"; shortName = "discovery"; icVar = "ic_Discovery" }
)

$level2Properties = @(
    @{ prop = "P2579"; shortName = "recognized in"; icVar = "ic_Source" },
    @{ prop = "P279";  shortName = "superclass of"; icVar = "ic_Superclass" },
    @{ prop = "P1269"; shortName = "influences"; icVar = "ic_Influencer" }
)

$level3Properties = @(
    @{ prop = "P31";   shortName = "instance of"; icVar = "ic_Type" },
    @{ prop = "P361";  shortName = "part of";      icVar = "ic_Parent" },
    @{ prop = "P1343"; shortName = "described in"; icVar = "ic_Literature" }
)

# --- Templates ---

$level1Template = @"
#query Level 1
SELECT * WHERE {{
  {{
    SELECT ?i_start ?i_startLabel ?i_startDescription ?{0} ?ii_startImage ?iu_startUrl
            ?rn_Name (?rn_Name AS ?rc_Category)
            ?i_end ?i_endLabel ?i_endDescription ?{1} ?ii_endImage ?iu_endUrl
    WHERE {{
      BIND({2} AS ?topic)
      ?childItem wdt:{3} ?topic .
      {5} ?topic wdt:P18 ?topicImage . {6}
      {5} ?childItem wdt:P18 ?childItemImage . {6}
      BIND(?topic AS ?i_start)
      BIND(?childItem AS ?i_end)
      BIND(?topicImage AS ?ii_startImage)
      BIND(?childItemImage AS ?ii_endImage)
      BIND("{4}" AS ?rn_Name)
      SERVICE wikibase:label {{ bd:serviceParam wikibase:language "en". }}
    }}
  }}
  FILTER(STRLEN(?i_startLabel) > 0)
  FILTER(STRLEN(?i_startDescription) > 0)
  FILTER(STRLEN(?i_endLabel) > 0)
  FILTER(STRLEN(?i_endDescription) > 0)
}}
"@

$level2Template = @"
#query
SELECT * WHERE {{
  {{
    SELECT ?i_start ?i_startLabel ?i_startDescription ?{0} ?ii_startImage ?iu_startUrl
            ?rn_Name (?rn_Name AS ?rc_Category)
            ?i_end ?i_endLabel ?i_endDescription ?{1} ?ii_endImage ?iu_endUrl
    WHERE {{
      BIND({2} AS ?topic)
      ?childItem wdt:{3} ?topic .
      ?grandChildItem wdt:{4} ?childItem .
      {6} ?childItem wdt:P18 ?childItemImage . {7}
      {6} ?grandChildItem wdt:P18 ?grandChildItemImage . {7}
      BIND(?childItem AS ?i_start)
      BIND(?grandChildItem AS ?i_end)
      BIND(?childItemImage AS ?ii_startImage)
      BIND(?grandChildItemImage AS ?ii_endImage)
      BIND("{5}" AS ?rn_Name)
      SERVICE wikibase:label {{ bd:serviceParam wikibase:language "en". }}
    }}
  }}
  FILTER(STRLEN(?i_startLabel) > 0)
  FILTER(STRLEN(?i_startDescription) > 0)
  FILTER(STRLEN(?i_endLabel) > 0)
  FILTER(STRLEN(?i_endDescription) > 0)
}}
"@

$level3Template = @"
#query Level 3
SELECT * WHERE {{
  {{
    SELECT ?i_start ?i_startLabel ?i_startDescription ?{0} ?ii_startImage ?iu_startUrl
            ?rn_Name (?rn_Name AS ?rc_Category)
            ?i_end ?i_endLabel ?i_endDescription ?{1} ?ii_endImage ?iu_endUrl
    WHERE {{
      BIND({2} AS ?topic)
      ?childItem wdt:{3} ?topic .
      ?grandChildItem wdt:{4} ?childItem .
      ?greatGrandChildItem wdt:{5} ?grandChildItem .
      
      {7} ?grandChildItem wdt:P18 ?gcImage . {8}
      {7} ?greatGrandChildItem wdt:P18 ?ggcImage . {8}
      
      BIND(?grandChildItem AS ?i_start)
      BIND(?greatGrandChildItem AS ?i_end)
      BIND(?gcImage AS ?ii_startImage)
      BIND(?ggcImage AS ?ii_endImage)
      BIND("{6}" AS ?rn_Name)
      SERVICE wikibase:label {{ bd:serviceParam wikibase:language "en". }}
    }}
  }}
  FILTER(STRLEN(?i_startLabel) > 0)
  FILTER(STRLEN(?i_startDescription) > 0)
  FILTER(STRLEN(?i_endLabel) > 0)
  FILTER(STRLEN(?i_endDescription) > 0)
}}
"@

# --- Queries generieren ---

# Level 1
foreach ($p1 in $level1Properties) {
    if ($level0.icVar -ne $p1.icVar) {
        $query = $level1Template -f $level0.icVar, $p1.icVar, $level0.topic, $p1.prop, $p1.shortName, $optPrefix, $optSuffix
        Add-Content -Path $outputFile -Value $query -Encoding UTF8
    }
}

# Level 2
foreach ($p1 in $level1Properties) {
    foreach ($p2 in $level2Properties) {
        if ($p1.icVar -ne $p2.icVar) {
            $query = $level2Template -f $p1.icVar, $p2.icVar, $level0.topic, $p1.prop, $p2.prop, $p2.shortName, $optPrefix, $optSuffix
            Add-Content -Path $outputFile -Value $query -Encoding UTF8
        }
        else {
            Write-Host "Überspringe Level 2 Query: $($p1.icVar) ist identisch mit $($p2.icVar)" -ForegroundColor Yellow
        }
    }
}

# Level 3
foreach ($p1 in $level1Properties) {
    foreach ($p2 in $level2Properties) {
        foreach ($p3 in $level3Properties) {
            if ($p2.icVar -ne $p3.icVar) {
                $query = $level3Template -f $p2.icVar, $p3.icVar, $level0.topic, $p1.prop, $p2.prop, $p3.prop, $p3.shortName, $optPrefix, $optSuffix
                Add-Content -Path $outputFile -Value $query -Encoding UTF8
            }
            else {
                Write-Host "Überspringe Level 3 Query: $($p2.icVar) ist identisch mit $($p3.icVar)" -ForegroundColor Yellow
            }
        }
    }
}

Write-Host "Erfolgreich Queries (Bilder optional: $imagesOptional) generiert."