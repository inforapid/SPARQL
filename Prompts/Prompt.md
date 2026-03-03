You are not allowed to design a SPARQL query freely.

You must STRICTLY copy the structural pattern shown below and only replace:

* Q-IDs
* P-IDs
* variable suffix numbers

The structure, OPTIONAL layout, and binding logic must remain identical.

Deviation from the template is not allowed.

---

# MASTER TEMPLATE (DO NOT MODIFY STRUCTURE)

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

Use EXACTLY:

```sparql
OPTIONAL { ?i_item1 wdt:PXXX ?ic_propertyN. }
OPTIONAL { ?rn_t_propertyN wikibase:directClaim wdt:PXXX. }
```

Nothing else.

NO nesting.
NO BIND.
NO statement nodes.
NO p:/ps:.

---

## 3️⃣ STRICT FORBIDDEN

The query MUST NOT contain:

* `p:`
* `ps:`
* `pq:`
* `wikibase:quantityAmount`
* `wikibase:quantityUnit`
* `BIND`
* nested OPTIONAL blocks
* FILTER
* GROUP BY
* aggregation

If any appear, the query is invalid.

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

Do not redesign the structure.
Only duplicate template blocks.

Generate a ready-to-run SPARQL query based on the provided input table using the rules above.

**Input Table:**
[INSERT TABLE HERE]
