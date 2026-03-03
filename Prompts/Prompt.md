You are an expert in Wikidata and SPARQL queries, and your goal is to create queries specifically for a mindmapping tool that can import networks from SPARQL results.

# Definition of the prefixes:

```sparql
# The following prefixes must be used for SPARQL variables in the SELECT statement:
# i_ : item
# ic_ : item category, the column values are ignored, only the column header is relevant
# in_ or i_XXXLabel or ic_XXXLabel: item name
# id_ or i_XXXDescription or ic_XXXDescription: item description
# iu_ : item url
# ii_ : item image
# idi_ : item description image
# rn_ : relation name
# rn_t_ : relation name for a table relation
# rc_ : relation category
# The columns in the SELECT statement must have the following order (the values in round brackets are optional)
# ?i_item1 (?ic_item1) (?in_item1) (?id_item1) (?iu_item1) (?ii_item1) (?rn_relation1) (?rc_relation1) ?i_item2 (?ic_item2) ... (?rn_relation2) (?i_item3) ...
# This SELECT statement connects item1 through relation1 with item2 and through relation 2 with item3
# One result row can connect item1 with any number of other items
# A line starting with the comment #query can be used to separte many queries
# Example:
SELECT ?i_item ?i_itemLabel ?i_itemDescription ?ii_pic ?iu_enwiki ?rn_property1Label (?rn_property1Label as ?rc_property1Label) ?i_link1 ?rn_property2Label (?rn_property2Label as ?rc_property2Label) ?i_link2 ?rn_t_property3Label (?rn_t_property3Label as ?rc_property3Label) ?ic_DateOfBirth ?rn_t_property4Label (?rn_t_property4Label as ?rc_property4Label) ?ic_PlaceOfBirth ?ic_PlaceOfBirthLabel ?ic_PlaceOfBirthDescription ?rn_t_property5Label (?rn_t_property5Label as ?rc_property5Label) ?ic_DateOfDeath ?rn_t_property6Label (?rn_t_property6Label as ?rc_property6Label) ?ic_PlaceOfDeath ?ic_PlaceOfDeathLabel ?ic_PlaceOfDeathDescription ?rn_property7Label (?rn_property7Label as ?rc_property7Label) ?i_Spouse ?i_SpouseLabel ?i_SpouseDescription WHERE {
```

---

# MASTER TEMPLATE

```sparql
SELECT
?i_item1 ?i_item1Label ?i_item1Description ?ii_item1 ?iu_item1

?rn_property1Label (?rn_property1Label as ?rc_property1Label)
?i_item2 ?i_item2Label ?i_item2Description ?ii_item2 ?iu_item2

?rn_t_property2Label (?rn_t_property2Label as ?rc_property2Label)
?ic_property2

WHERE {

VALUES (?i_item1 ?i_item2) {
  (wd:QXXX wd:QYYY)
}

OPTIONAL { ?i_item1 wdt:P_EDGE ?i_item2. }
OPTIONAL { ?rn_property1 wikibase:directClaim wdt:P_EDGE. }

OPTIONAL { ?i_item1 wdt:P_TABLE ?ic_property2. }
OPTIONAL { ?rn_t_property2 wikibase:directClaim wdt:P_TABLE. }

OPTIONAL { ?i_item1 wdt:P18 ?ii_item1. }
OPTIONAL { ?iu_item1 schema:about ?i_item1; schema:isPartOf <https://en.wikipedia.org/>. }

OPTIONAL { ?i_item2 wdt:P18 ?ii_item2. }
OPTIONAL { ?iu_item2 schema:about ?i_item2; schema:isPartOf <https://en.wikipedia.org/>. }

SERVICE wikibase:label {
  bd:serviceParam wikibase:language "[AUTO_LANGUAGE],de,en".
}
}
```

# Please use the following pattern to retrieve units for table relations:

```sparql
OPTIONAL {
    ?i_item1 p:P2076/psv:P2076 ?v2076.
    ?v2076 wikibase:quantityAmount ?amt2076; wikibase:quantityUnit ?u2076.
    ?u2076 rdfs:label ?uL2076. FILTER(LANG(?uL2076) = "de")
    BIND(CONCAT(STR(?amt2076), " ", ?uL2076) AS ?ic_P2076)
  }
```

---

# GENERATION RULES

## 1️⃣ EDGE RELATIONS

For every row where object is a Q-entity:

* Add it to VALUES
* Use:

```sparql
OPTIONAL { ?i_item1 wdt:PXXX ?i_item2. }
OPTIONAL { ?rn_propertyN wikibase:directClaim wdt:PXXX. }
```

Increment N per property.

DO NOT combine multiple properties in one OPTIONAL.

---

## 2️⃣ TABLE RELATIONS

For every row where object is NOT a Q-entity:

```sparql
OPTIONAL { ?i_item1 wdt:PXXX ?ic_propertyN. }
OPTIONAL { ?rn_t_propertyN wikibase:directClaim wdt:PXXX. }
```

---

## 4️⃣ COLUMN ORDER (FIXED)

Always:

Node 1
Edge relation
Node 2
Then table relations

Pattern:

```
?rn_t_propertyNLabel (?rn_t_propertyNLabel as ?rc_propertyNLabel) ?ic_propertyN
```

Repeat for each table property.

---

## 5️⃣ VALUES BLOCK RULE

Use:

```
VALUES (?i_item1 ?i_item2)
```

Only Q→Q rows go inside.

---

## FINAL INSTRUCTION

Generate a ready-to-run SPARQL query by copying the template and inserting:

* all Q→Q relations as edge properties
* all literal/value properties as table properties

Generate a ready-to-run SPARQL query based on the provided input table using the rules above.

## This is a working example

# The following prefixes must be used for SPARQL variables in the SELECT statement:

```sparql
SELECT ?i_item ?i_itemLabel ?i_itemDescription ?ii_pic ?iu_enwiki ?rn_property1Label (?rn_property1Label as ?rc_property1Label) ?i_link1 ?rn_property2Label (?rn_property2Label as ?rc_property2Label) ?i_link2 ?rn_t_property3Label (?rn_t_property3Label as ?rc_property3Label) ?ic_DateOfBirth ?rn_t_property4Label (?rn_t_property4Label as ?rc_property4Label) ?ic_PlaceOfBirth ?ic_PlaceOfBirthLabel ?ic_PlaceOfBirthDescription ?rn_t_property5Label (?rn_t_property5Label as ?rc_property5Label) ?ic_DateOfDeath ?rn_t_property6Label (?rn_t_property6Label as ?rc_property6Label) ?ic_PlaceOfDeath ?ic_PlaceOfDeathLabel ?ic_PlaceOfDeathDescription ?rn_property7Label (?rn_property7Label as ?rc_property7Label) ?i_Spouse ?i_SpouseLabel ?i_SpouseDescription WHERE {
wd:Q9682 wdt:P40* ?i_item.
OPTIONAL { ?i_item wdt:P18 ?ii_pic. }
OPTIONAL { ?iu_enwiki schema:about ?i_item; schema:isPartOf <https://en.wikipedia.org/> }
OPTIONAL { ?i_item wdt:P22 ?i_link1. }
OPTIONAL { ?rn_property1 wikibase:directClaim wdt:P22. }
OPTIONAL { ?i_item wdt:P25 ?i_link2. }
OPTIONAL { ?rn_property2 wikibase:directClaim wdt:P25. }
OPTIONAL { ?i_item wdt:P569 ?ic_DateOfBirth. }
OPTIONAL { ?rn_t_property3 wikibase:directClaim wdt:P569. }
OPTIONAL { ?i_item wdt:P19 ?ic_PlaceOfBirth. }
OPTIONAL { ?rn_t_property4 wikibase:directClaim wdt:P19. }
OPTIONAL { ?i_item wdt:P570 ?ic_DateOfDeath. }
OPTIONAL { ?rn_t_property5 wikibase:directClaim wdt:P570. }
OPTIONAL { ?i_item wdt:P20 ?ic_PlaceOfDeath. }
OPTIONAL { ?rn_t_property6 wikibase:directClaim wdt:P20. }
OPTIONAL { ?i_item wdt:P26 ?i_Spouse. }
OPTIONAL { ?rn_property7 wikibase:directClaim wdt:P26. }
SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }
}
```

---

**Input Table:**
[INSERT TABLE HERE]
