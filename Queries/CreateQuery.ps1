# PowerShell Skript: Erzeugt queries.sparql (Level 1 bis Level 3) mit optionalen Filtern

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

# --- Definitionen mit optionalen Filtern ---
# Beispiel: Nur Instanzen von Mensch (Q5) oder chemischen Elementen (Q11344)
$level0 = @{ topic = "wd:Q937"; icVar = "ic_Discoverer" }

$level1Properties = @(
    @{ 
        prop = "P61"; 
        shortName = "discovery"; 
        icVar = "ic_Discovery";
        # BEISPIEL ODER: Instanz von Q3239681 ODER Q214070
        filterProp = "P31";
        filterVal  = @("Q3239681", "Q214070") 
    }
)

$level2Properties = @(
    @{ prop = "P2579"; shortName = "recognized in"; icVar = "ic_Source" },
    @{ prop = "P279";  shortName = "superclass of"; icVar = "ic_Superclass"; filterProp = "P31"; filterVal = "Q2001676" },
    @{ 
        prop = "P2579"; 
        shortName = "recognized in"; 
        icVar = "ic_Source";
        # BEISPIEL UND: P31=Q3239681 UND P1269=Q11452
        multiFilter = @(
            @{ p = "P31"; v = "Q3239681" },
            @{ p = "P1269"; v = "Q11452" }
        )
    }    
)

$level3Properties = @(
    @{ prop = "P31";   shortName = "instance of"; icVar = "ic_Type" }, # Kein Filter
    @{ prop = "P361";  shortName = "part of";      icVar = "ic_Parent" }, # Kein Filter
    @{ prop = "P1343"; shortName = "described in"; icVar = "ic_Literature" } # Kein Filter
)

# Hilfsfunktion zur Erzeugung des Filter-Strings in SPARQL
function Get-FilterString($propObj, $targetVar) {
    $sparql = ""
    
    # 1. Check auf Multi-Filter (UND)
    if ($propObj.multiFilter) {
        foreach ($f in $propObj.multiFilter) {
            $sparql += "?$targetVar wdt:$($f.p) wd:$($f.v) . `n      "
        }
    }
    # 2. Check auf einfachen Filter oder ODER-Liste
    elseif ($propObj.filterProp -and $propObj.filterVal) {
        if ($propObj.filterVal -is [array]) {
            # ODER-Verknüpfung via VALUES
            $values = ($propObj.filterVal | ForEach-Object { "wd:$_" }) -join " "
            # HIER DIE KORREKTUR: ${targetVar} statt $targetVar_filter
            $sparql = "VALUES ?${targetVar}Filter { $values } . `n      ?$targetVar wdt:$($propObj.filterProp) ?${targetVar}Filter ."
        } else {
            # Einfacher Filter
            $sparql = "?$targetVar wdt:$($propObj.filterProp) wd:$($propObj.filterVal) ."
        }
    }
    return $sparql
}

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
      {7}
      {5} ?topic wdt:P18 ?topicImage . {6}
      {5} ?childItem wdt:P18 ?childItemImage . {6}
      BIND(?topic AS ?i_start)
      BIND(?childItem AS ?i_end)
      BIND(?topicImage AS ?ii_startImage)
      BIND(?childItemImage AS ?ii_endImage)
      BIND("{4}" AS ?rn_Name)
      SERVICE wikibase:label {{ bd:serviceParam wikibase:language "en". }}
    }}
    ORDER BY ASC(xsd:integer(REPLACE(STR(?i_end), "^.*Q", "")))
  }}
  FILTER(STRLEN(?i_startLabel) > 0)
  FILTER(STRLEN(?i_startDescription) > 0)
  FILTER(STRLEN(?i_endLabel) > 0)
  FILTER(STRLEN(?i_endDescription) > 0)
}}
"@

$level2Template = @"
#query Level 2
SELECT * WHERE {{
  {{
    SELECT ?i_start ?i_startLabel ?i_startDescription ?{0} ?ii_startImage ?iu_startUrl
            ?rn_Name (?rn_Name AS ?rc_Category)
            ?i_end ?i_endLabel ?i_endDescription ?{1} ?ii_endImage ?iu_endUrl
    WHERE {{
      BIND({2} AS ?topic)
      ?childItem wdt:{3} ?topic .
      ?grandChildItem wdt:{4} ?childItem .
      {8}
      {6} ?childItem wdt:P18 ?childItemImage . {7}
      {6} ?grandChildItem wdt:P18 ?grandChildItemImage . {7}
      BIND(?childItem AS ?i_start)
      BIND(?grandChildItem AS ?i_end)
      BIND(?childItemImage AS ?ii_startImage)
      BIND(?grandChildItemImage AS ?ii_endImage)
      BIND("{5}" AS ?rn_Name)
      SERVICE wikibase:label {{ bd:serviceParam wikibase:language "en". }}
    }}
    ORDER BY ASC(xsd:integer(REPLACE(STR(?i_end), "^.*Q", "")))
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
      {9}
      {7} ?grandChildItem wdt:P18 ?gcImage . {8}
      {7} ?greatGrandChildItem wdt:P18 ?ggcImage . {8}
      BIND(?grandChildItem AS ?i_start)
      BIND(?greatGrandChildItem AS ?i_end)
      BIND(?gcImage AS ?ii_startImage)
      BIND(?ggcImage AS ?ii_endImage)
      BIND("{6}" AS ?rn_Name)
      SERVICE wikibase:label {{ bd:serviceParam wikibase:language "en". }}
    }}
    ORDER BY ASC(xsd:integer(REPLACE(STR(?i_end), "^.*Q", "")))
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
    $fStr = Get-FilterString $p1 "childItem"
    $query = $level1Template -f $level0.icVar, $p1.icVar, $level0.topic, $p1.prop, $p1.shortName, $optPrefix, $optSuffix, $fStr
    Add-Content -Path $outputFile -Value $query -Encoding UTF8
}

# Level 2
foreach ($p1 in $level1Properties) {
    foreach ($p2 in $level2Properties) {
        if ($p1.icVar -ne $p2.icVar) {
            $f1 = Get-FilterString $p1 "childItem"         # Filter für die 1. Ebene
            $f2 = Get-FilterString $p2 "grandChildItem"    # Filter für die 2. Ebene
            $combinedFilters = "$f1 `n      $f2"
            $query = $level2Template -f $p1.icVar, $p2.icVar, $level0.topic, $p1.prop, $p2.prop, $p2.shortName, $optPrefix, $optSuffix, $combinedFilters
            Add-Content -Path $outputFile -Value $query -Encoding UTF8
        }
    }
}

# Level 3
foreach ($p1 in $level1Properties) {
    foreach ($p2 in $level2Properties) {
        foreach ($p3 in $level3Properties) {
            if ($p2.icVar -ne $p3.icVar) {
                $f1 = Get-FilterString $p1 "childItem"
                $f2 = Get-FilterString $p2 "grandChildItem"
                $f3 = Get-FilterString $p3 "greatGrandChildItem"
                $combinedFilters = "$f1 `n      $f2 `n      $f3"
                $query = $level3Template -f $p2.icVar, $p3.icVar, $level0.topic, $p1.prop, $p2.prop, $p3.prop, $p3.shortName, $optPrefix, $optSuffix, $combinedFilters
                Add-Content -Path $outputFile -Value $query -Encoding UTF8
            }
        }
    }
}

Write-Host "Queries mit optionalen Filtern generiert." -ForegroundColor Green