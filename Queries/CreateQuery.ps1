# PowerShell Skript: Erzeugt queries.sparql (Level 1 bis Level 3) mit optionalen Filtern

$outputFile = "queries.sparql"
# STEUERUNG: $true = Bilder sind optional, $false = Bilder sind Pflicht
$imagesOptional = $true 
# STEUERUNG URLS: $true = Wikipedia Links werden geliefert
$includeUrls = $true
# GLOBALE SPRACHE: lang = Fallback-Kette für Labels; wikiLang = Wikipedia-Sprachversion
$lang = "de,en"
$wikiLang = "de"

if ($imagesOptional) {
    $optPrefix = "OPTIONAL {"
    $optSuffix = "}"
} else {
    $optPrefix = ""
    $optSuffix = ""
}

# Funktion für die URL-Statements (nutzt globale $wikiLang)
function Get-UrlStatements($sVar, $eVar) {
    if (-not $includeUrls) { return "" }
    return "OPTIONAL { ?iu_startUrl schema:about ?$sVar; schema:isPartOf <https://$wikiLang.wikipedia.org/>. } `n      OPTIONAL { ?iu_endUrl schema:about ?$eVar; schema:isPartOf <https://$wikiLang.wikipedia.org/>. }"
}

# Funktion für zusätzliche Properties
function Get-ExtraProps($itemVar, $extraProps, [ref]$counter) {
    $res = @{ select = ""; where = "" }
    if ($extraProps) {
        foreach ($ep in $extraProps) {
            $num = $counter.Value++
            $res.select += " ?rn_t_property${num}Label (?rn_t_property${num}Label as ?rc_property${num}Label) ?$($ep.icVar)"
            $res.where += "`n      OPTIONAL { ?$itemVar wdt:$($ep.prop) ?$($ep.icVar). ?rn_t_property$num wikibase:directClaim wdt:$($ep.prop). }"
        }
    }
    return $res
}

# Initialisierung
Set-Content -Path $outputFile -Value "" -Encoding UTF8

# --- Definitionen ---

$level0 = @{ 
    topic = "wd:Q937"; 
    icVar = "ic_Discoverer";
    extraProps = @(
        @{ prop = "P569"; icVar = "ic_DateOfBirth" },
        @{ prop = "P570"; icVar = "ic_DateOfDeath" }
    )
}

$level1Properties = @(
    @{ 
        prop = "P61"; 
        shortName = "discovery"; 
        icVar = "ic_Discovery";
        isReverse = $true; # Rückwärts: ?childItem wdt:P61 ?topic (Wer wurde von Einstein entdeckt?)
        # BEISPIEL ODER
        filterProp = "P31";
        filterVal  = @("Q3239681", "Q214070");
        extraProps = @(
            @{ prop = "P575"; icVar = "ic_DiscoveryDate" }
        )
    }
)

$level2Properties = @(
    @{ prop = "P2579"; shortName = "recognized in"; icVar = "ic_Source"; isReverse = $true; 
        extraProps = @(
            @{ prop = "P577"; icVar = "ic_PublicationDate" }
        )
    },
    @{ prop = "P279";  shortName = "superclass of"; icVar = "ic_Superclass"; isReverse = $true; filterProp = "P31"; filterVal = "Q2001676" },
    @{ 
        prop = "P2579"; 
        shortName = "recognized in"; 
        icVar = "ic_Source";
        isReverse = $true; # Rückwärts: ?childItem wdt:P61 ?topic (Wer wurde von Einstein entdeckt?)
        # BEISPIEL UND: P31=Q3239681 UND P1269=Q11452
        multiFilter = @(
            @{ p = "P31"; v = "Q3239681" },
            @{ p = "P1269"; v = "Q11452" }
        )
    }
)

$level3Properties = @(
    @{ prop = "P31";   shortName = "instance of"; icVar = "ic_Type"; isReverse = $false;
        extraProps = @(
            @{ prop = "P1889"; icVar = "ic_DifferentFrom" }
        )
    },
    @{ prop = "P361";  shortName = "part of";     icVar = "ic_Parent"; isReverse = $false }, # Kein Filter
    @{ prop = "P1343"; shortName = "described in"; icVar = "ic_Literature"; isReverse = $false } # Kein Filter
)

# --- Hilfsfunktionen ---

# Erzeugt den Triple-String basierend auf der Richtung
function Get-RelationString($propObj, $subjectVar, $objectVar) {
    if ($propObj.isReverse) {
        # B ist Property von A -> ?object wdt:prop ?subject
        return "?$objectVar wdt:$($propObj.prop) ?$subjectVar ."
    } else {
        # A ist Property von B -> ?subject wdt:prop ?object
        return "?$subjectVar wdt:$($propObj.prop) ?$objectVar ."
    }
}

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

# --- Templates (nutzen globale Variable $lang direkt) ---

$level1Template = @"
#query Level 1
SELECT * WHERE {{
  {{
    SELECT ?i_start ?i_startLabel ?i_startDescription ?{0} ?ii_startImage ?iu_startUrl
            ?rn_Name (?rn_Name AS ?rc_Category)
            ?i_end ?i_endLabel ?i_endDescription ?{1} ?ii_endImage ?iu_endUrl
    WHERE {{
      VALUES ?topic {{ {2} }}
      {3}
      {7}
      {5} ?topic wdt:P18 ?topicImage . {6}
      {5} ?childItem wdt:P18 ?childItemImage . {6}
      BIND(?topic AS ?i_start)
      BIND(?childItem AS ?i_end)
      {8}
      BIND(?topicImage AS ?ii_startImage)
      BIND(?childItemImage AS ?ii_endImage)
      BIND("{4}" AS ?rn_Name)
      SERVICE wikibase:label {{ bd:serviceParam wikibase:language "$lang". }}
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
      VALUES ?topic {{ {2} }}
      {3}
      {4}
      {8}
      {6} ?childItem wdt:P18 ?childItemImage . {7}
      {6} ?grandChildItem wdt:P18 ?grandChildItemImage . {7}
      BIND(?childItem AS ?i_start)
      BIND(?grandChildItem AS ?i_end)
      {9}
      BIND(?childItemImage AS ?ii_startImage)
      BIND(?grandChildItemImage AS ?ii_endImage)
      BIND("{5}" AS ?rn_Name)
      SERVICE wikibase:label {{ bd:serviceParam wikibase:language "$lang". }}
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
      VALUES ?topic {{ {2} }}
      {3}
      {4}
      {5}
      {9}
      {7} ?grandChildItem wdt:P18 ?gcImage . {8}
      {7} ?greatGrandChildItem wdt:P18 ?ggcImage . {8}
      BIND(?grandChildItem AS ?i_start)
      BIND(?greatGrandChildItem AS ?i_end)
      {10}
      BIND(?gcImage AS ?ii_startImage)
      BIND(?ggcImage AS ?ii_endImage)
      BIND("{6}" AS ?rn_Name)
      SERVICE wikibase:label {{ bd:serviceParam wikibase:language "$lang". }}
    }}
    ORDER BY ASC(xsd:integer(REPLACE(STR(?i_end), "^.*Q", "")))
  }}
  FILTER(STRLEN(?i_startLabel) > 0)
  FILTER(STRLEN(?i_startDescription) > 0)
  FILTER(STRLEN(?i_endLabel) > 0)
  FILTER(STRLEN(?i_endDescription) > 0)
}}
"@

$level1ExtraPropsTemplate = @"
#query Level 1 ExtraProps
SELECT * WHERE {{
  {{
    SELECT ?i_start ?i_startLabel ?i_startDescription ?{0} ?ii_startImage ?iu_startUrl{5}
    WHERE {{
      VALUES ?topic {{ {1} }}
      {2} ?topic wdt:P18 ?topicImage . {3}
      {6}
      BIND(?topic AS ?i_start)
      {4}
      BIND(?topicImage AS ?ii_startImage)
      SERVICE wikibase:label {{ bd:serviceParam wikibase:language "$lang". }}
    }}
  }}
  FILTER(STRLEN(?i_startLabel) > 0)
  FILTER(STRLEN(?i_startDescription) > 0)
}}
"@

$level2ExtraPropsTemplate = @"
#query Level 2 ExtraProps
SELECT * WHERE {{
  {{
    SELECT ?i_start ?i_startLabel ?i_startDescription ?{0} ?ii_startImage ?iu_startUrl{7}
    WHERE {{
      VALUES ?topic {{ {1} }}
      {2}
      {5}
      {3} ?childItem wdt:P18 ?childItemImage . {4}
      {8}
      BIND(?childItem AS ?i_start)
      {6}
      BIND(?childItemImage AS ?ii_startImage)
      SERVICE wikibase:label {{ bd:serviceParam wikibase:language "$lang". }}
    }}
  }}
  FILTER(STRLEN(?i_startLabel) > 0)
  FILTER(STRLEN(?i_startDescription) > 0)
}}
"@

$level3ExtraPropsTemplate = @"
#query Level 3 ExtraProps
SELECT * WHERE {{
  {{
    SELECT ?i_start ?i_startLabel ?i_startDescription ?{0} ?ii_startImage ?iu_startUrl{8}
    WHERE {{
      VALUES ?topic {{ {1} }}
      {2}
      {3}
      {6}
      {4} ?grandChildItem wdt:P18 ?grandChildItemImage . {5}
      {9}
      BIND(?grandChildItem AS ?i_start)
      {7}
      BIND(?grandChildItemImage AS ?ii_startImage)
      SERVICE wikibase:label {{ bd:serviceParam wikibase:language "$lang". }}
    }}
  }}
  FILTER(STRLEN(?i_startLabel) > 0)
  FILTER(STRLEN(?i_startDescription) > 0)
}}
"@

$level4ExtraPropsTemplate = @"
#query Level 4 ExtraProps
SELECT * WHERE {{
  {{
    SELECT ?i_start ?i_startLabel ?i_startDescription ?{0} ?ii_startImage ?iu_startUrl{9}
    WHERE {{
      VALUES ?topic {{ {1} }}
      {2}
      {3}
      {4}
      {7}
      {5} ?greatGrandChildItem wdt:P18 ?ggcImage . {6}
      {10}
      BIND(?greatGrandChildItem AS ?i_start)
      {8}
      BIND(?ggcImage AS ?ii_startImage)
      SERVICE wikibase:label {{ bd:serviceParam wikibase:language "$lang". }}
    }}
  }}
  FILTER(STRLEN(?i_startLabel) > 0)
  FILTER(STRLEN(?i_startDescription) > 0)
}}
"@

# --- Queries generieren ---

# Level 1
if ($level0.extraProps) {
    $cnt = [ref]1
    $exS = Get-ExtraProps "topic" $level0.extraProps $cnt
    $urls = Get-UrlStatements "topic" "topic"
    $query = $level1ExtraPropsTemplate -f $level0.icVar, $level0.topic, $optPrefix, $optSuffix, $urls, $exS.select, $exS.where
    Add-Content -Path $outputFile -Value $query -Encoding UTF8
}

foreach ($p1 in $level1Properties) {
    $rel1 = Get-RelationString $p1 "topic" "childItem"
    $fStr = Get-FilterString $p1 "childItem"
    $urls = Get-UrlStatements "topic" "childItem"
    $query = $level1Template -f $level0.icVar, $p1.icVar, $level0.topic, $rel1, $p1.shortName, $optPrefix, $optSuffix, $fStr, $urls
    Add-Content -Path $outputFile -Value $query -Encoding UTF8
}

# Level 2
foreach ($p1 in $level1Properties) {
    if ($p1.extraProps) {
        $rel1 = Get-RelationString $p1 "topic" "childItem"
        $f1 = Get-FilterString $p1 "childItem"
        $urls = Get-UrlStatements "childItem" "childItem"
        $cnt = [ref]1
        $exS = Get-ExtraProps "childItem" $p1.extraProps $cnt
        $query = $level2ExtraPropsTemplate -f $p1.icVar, $level0.topic, $rel1, $optPrefix, $optSuffix, $f1, $urls, $exS.select, $exS.where
        Add-Content -Path $outputFile -Value $query -Encoding UTF8
    }

    foreach ($p2 in $level2Properties) {
        if ($p1.icVar -ne $p2.icVar) {
            $rel1 = Get-RelationString $p1 "topic" "childItem"
            $rel2 = Get-RelationString $p2 "childItem" "grandChildItem"
            $f1 = Get-FilterString $p1 "childItem"         # Filter für die 1. Ebene
            $f2 = Get-FilterString $p2 "grandChildItem"    # Filter für die 2. Ebene
            $combinedFilters = "$f1 `n      $f2"
            $urls = Get-UrlStatements "childItem" "grandChildItem"
            $query = $level2Template -f $p1.icVar, $p2.icVar, $level0.topic, $rel1, $rel2, $p2.shortName, $optPrefix, $optSuffix, $combinedFilters, $urls
            Add-Content -Path $outputFile -Value $query -Encoding UTF8
        }
    }
}

# Level 3
foreach ($p1 in $level1Properties) {
    foreach ($p2 in $level2Properties) {
        if ($p1.icVar -ne $p2.icVar) {
            if ($p2.extraProps) {
                $rel1 = Get-RelationString $p1 "topic" "childItem"
                $rel2 = Get-RelationString $p2 "childItem" "grandChildItem"
                $f1 = Get-FilterString $p1 "childItem"
                $f2 = Get-FilterString $p2 "grandChildItem"
                $combinedFilters = "$f1 `n      $f2"
                $urls = Get-UrlStatements "grandChildItem" "grandChildItem"
                $cnt = [ref]1
                $exS = Get-ExtraProps "grandChildItem" $p2.extraProps $cnt
                $query = $level3ExtraPropsTemplate -f $p2.icVar, $level0.topic, $rel1, $rel2, $optPrefix, $optSuffix, $combinedFilters, $urls, $exS.select, $exS.where
                Add-Content -Path $outputFile -Value $query -Encoding UTF8
            }

            foreach ($p3 in $level3Properties) {
                if ($p2.icVar -ne $p3.icVar) {
                    $rel1 = Get-RelationString $p1 "topic" "childItem"
                    $rel2 = Get-RelationString $p2 "childItem" "grandChildItem"
                    $rel3 = Get-RelationString $p3 "grandChildItem" "greatGrandChildItem"
                    $f1 = Get-FilterString $p1 "childItem"
                    $f2 = Get-FilterString $p2 "grandChildItem"
                    $f3 = Get-FilterString $p3 "greatGrandChildItem"
                    $combinedFilters = "$f1 `n      $f2 `n      $f3"
                    $urls = Get-UrlStatements "grandChildItem" "greatGrandChildItem"
                    $query = $level3Template -f $p2.icVar, $p3.icVar, $level0.topic, $rel1, $rel2, $rel3, $p3.shortName, $optPrefix, $optSuffix, $combinedFilters, $urls
                    Add-Content -Path $outputFile -Value $query -Encoding UTF8
                }
            }
        }
    }
}

# Level 4
foreach ($p1 in $level1Properties) {
    foreach ($p2 in $level2Properties) {
        foreach ($p3 in $level3Properties) {
            if ($p2.icVar -ne $p3.icVar -and $p3.extraProps) {
                $rel1 = Get-RelationString $p1 "topic" "childItem"
                $rel2 = Get-RelationString $p2 "childItem" "grandChildItem"
                $rel3 = Get-RelationString $p3 "grandChildItem" "greatGrandChildItem"
                $f1 = Get-FilterString $p1 "childItem"
                $f2 = Get-FilterString $p2 "grandChildItem"
                $f3 = Get-FilterString $p3 "greatGrandChildItem"
                $combinedFilters = "$f1 `n      $f2 `n      $f3"
                $urls = Get-UrlStatements "greatGrandChildItem" "greatGrandChildItem"
                $cnt = [ref]1
                $exS = Get-ExtraProps "greatGrandChildItem" $p3.extraProps $cnt
                $query = $level4ExtraPropsTemplate -f $p3.icVar, $level0.topic, $rel1, $rel2, $rel3, $optPrefix, $optSuffix, $combinedFilters, $urls, $exS.select, $exS.where
                Add-Content -Path $outputFile -Value $query -Encoding UTF8
            }
        }
    }
}

Write-Host "Queries erfolgreich generiert." -ForegroundColor Green