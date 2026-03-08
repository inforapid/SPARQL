# Guide: Writing SPARQL Queries for InfoRapid KnowledgeBase Builder

This manual explains how to construct SPARQL queries that the **InfoRapid KnowledgeBase Builder (IKBB)** can use to generate MindMaps and Knowledge Graphs from WikiData.

The tool identifies different types of data (items, names, images, relations) based on **variable prefixes** and the **order of columns** in the `SELECT` statement.

---

## 1. Variable Name Prefixes

The prefix of a variable tells the KnowledgeBase Builder how to process that specific data point.

| Prefix | Type | Description |
| :--- | :--- | :--- |
| `i_` | **Item** | Unique identifier (URI) for a node. |
| `ic_` | **Item Category** | Similar to `i_`, but the **column header** name (e.g., "DateOfBirth") is automatically assigned as the **Category** for the node. |
| `in_` or `i_...Label` | **Item Name** | The primary text displayed on the node. |
| `ic_...Label` | **Item Name (Cat)** | The label for a node identified by an `ic_` variable. Also used as the value in the second column of a table relation. |
| `id_` or `i_...Description` | **Item Description** | Description text for an `i_` item. |
| `ic_...Description` | **Item Description (Cat)**| Description text for an `ic_` item. |
| `iu_` | **Item URL** | A clickable hyperlink for the item. |
| `ii_` | **Item Image** | A URL to an image displayed on the node. |
| `idi_` | **Description Image**| An image specifically for the description area. |
| `rn_` | **Relation Name** | The label shown on the connection line. |
| `rc_` | **Relation Category** | The category assigned to the connection line. |
| `rn_t_` | **Table Relation** | A special relation displayed as a **table entry** inside the item. These relations are internally prefixed with `T:`. |

---

## 2. SELECT Statement Structure and Order

The order of variables in the `SELECT` statement is crucial. It defines the topology of the map. One result row can connect an item to any number of other items in a chain or branch.

### The Connection Pattern
The standard structure follows this sequence (items in brackets are optional):

`?i_item1 (?ic_item1) (?in_item1) (?id_item1) (?iu_item1) (?ii_item1) (?rn_relation1) (?rc_relation1) ?i_item2 ...`

*   **Relationship:** This connects `item1` to `item2` via `relation1`.
*   **Branching:** A single row can link `item1` to `item2`, AND `item1` to `item3` by repeating the relation/target variables later in the `SELECT`.
*   **Metadata for Categories:** If you use an `ic_` variable, you can still provide a label and description using `ic_...Label` and `ic_...Description`.

---

## 3. Advanced Variable Construction

You can use SPARQL's `BIND` and `CONCAT` functions to create custom labels or modify URLs specifically for the KnowledgeBase Builder.

### 3.1. Static Relation Names
If you want every row to have the same connection label (e.g., "influences"), you can hardcode it:
```sparql
BIND("influences" AS ?rn_influences).
```

### 3.2. Root Node Binding (Global Anchors)
You can anchor every result row to a single "Center" node by binding a URI to a variable at the start of your query. This is useful for maps centered on a city or a specific event.
```sparql
# This makes every person in the result connect to "Aberdeen"
BIND(wd:Q62274582 as ?i_place).
```

### 3.3. Custom Item URLs and Suffixes
The KnowledgeBase Builder often uses special suffixes in URLs to trigger specific behaviors. For example, adding `§if` to a WikiData URI:
```sparql
BIND (CONCAT (STR (?i_influencer), "§if") AS ?iu_influencer).
```

---

## 4. Automatic Branching

The KnowledgeBase Builder supports **implicit branching**. If you place multiple `i_` (Item) variables after a source node in your `SELECT` statement, the tool interprets them as separate branches coming from the **first** item in that row.

**SELECT Order:**
`?i_subject ... ?i_place ... ?i_plaque`

**The Resulting Graph:**
*   `subject` -> `place`
*   `subject` -> `plaque` (not `place` -> `plaque`)

This allows you to quickly build "Star" topologies where one central subject is connected to many different types of data (locations, objects, organizations) simultaneously.

---

## 5. Radial Network Exploration

While hierarchies build "top-down" trees, you can also build **radial maps** that explore all relationships surrounding a central item (the "Root").

### Exploring Both Directions
To see everything that connects *to* an item and everything the item connects *to*, use a `UNION` pattern:
```sparql
{
  # Items pointing to the root
  BIND(?root AS ?i_to)
  ?i_from ?property1 ?root.
}
UNION
{
  # Items the root points to
  BIND(?root AS ?i_from)
  ?root ?property1 ?i_to.
}
```

### Neighbors of Neighbors
You can expand the map by fetching second-degree connections (e.g., "Show me the neighbors of the Great Pyramid, and then show me how those neighbors connect to each other"):
```sparql
?i_to ?property2 ?root.      # Neighbor of root
?i_from ?property1 ?i_to.    # Neighbor of neighbor
```

---

## 6. Dynamic Relation Categorization (`rc_`)

You can use the `rc_` (Relation Category) prefix to color-code your connection lines based on the type of relationship.

If you fetch the label of the WikiData property (e.g., "subclass of", "location", "part of"), you can assign it to an `rc_` variable:
```sparql
# This makes all "subclass of" lines one color and all "location" lines another
OPTIONAL { ?rc_propertyLabel wikibase:directClaim ?property1. }
```
The KnowledgeBase Builder will group all relations with the same label into the same category, allowing you to filter or style them globally in the UI.

---

## 7. Data Merging and Multi-Row Results

One of the most powerful features of the tool is its ability to merge data from multiple rows.

*   **The Unique Key:** The `i_` (Item) variable acts as the unique identifier.
*   **Merging Logic:** If a person has five different "notable works", your SPARQL query will return five rows for that same person. The KnowledgeBase Builder will:
    1.  Create only **one node** for that person.
    2.  Attach all five works as separate outgoing connections.
    3.  Consolidate all `rn_t_` table entries into a single property table for that node.

---

## 8. Hierarchical Structures with UNION

While `#query` separates independent requests, you can use the `UNION` operator within a single SPARQL statement to build **multi-level hierarchies** (e.g., Millennium -> Century -> Decade -> Item).

### The "Stitch" Strategy
To create a chain, you provide rows that connect different levels:
1.  **Level 1 to 2:** Connect Millennium to Century.
2.  **Level 2 to 3:** Connect Century to Decade.
3.  **Level 3 to 4:** Connect Decade to the actual Item.

The KnowledgeBase Builder automatically "stitches" these together into a branch because they share the same variable names and values across the `UNION` blocks.

---

## 9. Calculated and Numeric Categories

You don't have to rely on existing WikiData items for grouping. You can create **virtual nodes** (like decades or price ranges) using SPARQL math.

### Creating Time Groups
If you have a date, you can calculate its decade or century and use it as a category node:
```sparql
# Calculate the decade (e.g., 1920)
BIND (xsd:integer(FLOOR(YEAR(?birthDate) / 10) * 10) AS ?ic_decyear).

# Calculate the century (e.g., 1900)
BIND (xsd:integer(FLOOR(YEAR(?birthDate) / 100) * 100) AS ?ic_centyear).
```
When these are placed in `ic_` variables, the tool creates a node labeled with the number and uses the column header as its category.

---

## 10. Multi-Query Architecture (`#query`)

You can combine multiple `SELECT` statements in a single `.sparql` file by separating them with the keyword `#query` at the beginning of a line.

### How Merging Works
The KnowledgeBase Builder processes every query in the file and merges the results into a single MindMap based on the unique URIs provided in the `i_` variables.

**Example Use Case: Multi-Level Hierarchies**
1.  **Query 1:** Define the relationship between specific occupations and general fields (e.g., *Astrophysicist* is a sub-type of *Physicist*).
2.  **Query 2:** Find Nobel Prize winners and their specific occupations (e.g., *Albert Einstein* is an *Astrophysicist*).

**The Result:** Because both queries use the same URI for "Astrophysicist", the tool automatically builds a chain:
`Einstein` -> `Astrophysicist` -> `Physicist`.

### Benefits
*   **Logical Separation:** Keep your "Category Tree" logic separate from your "Data Instance" logic.
*   **Metadata Enrichment:** Use one query to build connections and another query to specifically fetch images or descriptions for those items.
*   **Performance:** Wikibase services sometimes handle several smaller queries better than one massive, deeply nested query.

---

## 11. Table Relations (`rn_t_`)

Table relations allow you to store attributes (like "Date of Birth") as structured data within a node rather than just drawing lines in the MindMap.

*   **UI Representation:** In the generated diagram, these connections are labeled with `T:` (e.g., `T:date of birth`).
*   **Column 1:** The label of the `rn_t_` variable (the property name).
*   **Column 2:** The value of the following `ic_` or `i_` variable.
*   **Mapping:** The KnowledgeBase Builder groups these into the "Properties" table of the source node.
*   **Source Node Logic:** By default, if a SELECT statement looks like `?i_item1 ... ?rn_t_prop ?ic_value`, the property is attached to `item1`. If multiple items are in the row, the tool uses **Implicit Branching** (see Section 4), meaning properties placed after several `i_` items are typically attached to the **first** item of that segment.

---

## 12. Handling Values with Units

When dealing with physical quantities (mass, temperature, distance), WikiData provides both a number and a unit. To display these correctly in the KnowledgeBase Builder (e.g., "5772 Kelvin"), you must manually combine them using SPARQL's string functions.

### The "Amount + Unit" Pattern
To fetch a value with its unit, you cannot use the simple `wdt:` prefix. You must navigate through the statement and the value node:

```sparql
OPTIONAL { 
  # 1. Navigate to the statement (p:) and then to the specific value node (psv:)
  ?i_item p:P2076/psv:P2076 [
    wikibase:quantityAmount ?amount; 
    wikibase:quantityUnit [rdfs:label ?unitLabel]
  ]. 
  
  # 2. Filter the unit name to your preferred language
  FILTER(LANG(?unitLabel)="en") 
  
  # 3. Merge amount and unit into a single string for the KnowledgeBase Builder
  BIND(CONCAT(STR(?amount), " ", ?unitLabel) AS ?ic_ValueWithUnit) 
  
  # 4. Get the property name for the table header
  ?rn_t_property wikibase:directClaim wdt:P2076. 
}
```

### Why use `ic_` for values?
Using the `ic_` (Item Category) prefix for these combined strings is recommended. It ensures that the value is treated as a property entry within the item's table, and the column header in your `SELECT` statement (e.g., `?ic_Temperature`) will be used as the category/label for that value.

---

## 13. Using `VALUES` for Input Data

If you want to create a map for a specific set of items or compare specific pairs (like Sun/Earth, Jupiter/Io), you can define them at the start of your query using the `VALUES` block.

```sparql
WHERE {
  VALUES (?i_item1 ?i_item2) {
    (wd:Q525 wd:Q2)    # Sun and Earth
    (wd:Q319 wd:Q3123) # Jupiter and Io
  }
  # ... rest of the query
}
```
This is much more efficient than fetching all items of a class if you already know which specific entities you are interested in.

---

## 14. Comprehensive Example

This query extracts descendants of Elizabeth II, mapping family connections as lines and biographical data as table entries.

```sparql
SELECT 
  ?i_item ?i_itemLabel ?i_itemDescription ?ii_pic ?iu_enwiki 
  # Standard Relation (Line)
  ?rn_property1Label (?rn_property1Label as ?rc_property1Label) ?i_link1 
  # Table Relation (Inner Table)
  ?rn_t_property3Label (?rn_t_property3Label as ?rc_property3Label) 
  ?ic_DateOfBirth # This column header "DateOfBirth" becomes the Category
WHERE {
  wd:Q9682 wdt:P40* ?i_item. 
  
  OPTIONAL { ?i_item wdt:P18 ?ii_pic. }
  OPTIONAL { ?iu_enwiki schema:about ?i_item; schema:isPartOf <https://en.wikipedia.org/> }
  
  # Connection to Father (Line)
  OPTIONAL { ?i_item wdt:P22 ?i_link1. ?rn_property1 wikibase:directClaim wdt:P22. }
  
  # Connection to Birth Date (Table)
  OPTIONAL { ?i_item wdt:P569 ?ic_DateOfBirth. ?rn_t_property3 wikibase:directClaim wdt:P569. }

  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }
}
```

---

## 15. Useful SPARQL Code Snippets

The following snippets are commonly used with the KnowledgeBase Builder to enrich your diagrams.

### 15.1. Google Maps Links
Create a clickable URL that opens the location of an item in Google Maps.
```sparql
OPTIONAL { 
  ?i_place p:P625 ?statement.
  ?statement psv:P625 ?coordinate_node.
  ?coordinate_node wikibase:geoLatitude ?lat.
  ?coordinate_node wikibase:geoLongitude ?long.
  BIND (CONCAT ("http://www.google.com/maps/place/", STR(?lat), ",", STR(?long), "§if") AS ?iu_url).
}
```

### 15.2. Wikipedia Links
Fetch the English Wikipedia URL for an item.
```sparql
OPTIONAL { 
  ?iu_wikipedia_url schema:about ?i_item; 
  schema:isPartOf <https://en.wikipedia.org/> 
}
```

### 15.3. Geospatial Queries (Radius Search)
Find all places within a 10km radius of a central location.
```sparql
?centerPlace wdt:P625 ?centerLoc.
SERVICE wikibase:around {
  ?i_place wdt:P625 ?location. # the first statement must include the place and the location
  bd:serviceParam wikibase:center ?centerLoc.
  bd:serviceParam wikibase:radius "10". # maximum distance in kilometers
  bd:serviceParam wikibase:distance ?dist. # current distance in kilometers
}
```

### 15.4. Calculating and Formatting Distance
Calculate the distance between two locations and format it for display.
```sparql
# Calculate distance
BIND (geof:distance (?location1, ?location2) AS ?dist).

# Round to 10m precision and add unit
BIND (CONCAT (xsd:string (xsd:integer (CEIL (100 * ?dist) * 10)), " m") AS ?rounded_dist_in_m).
```

### 15.5. Dynamic Property Labels
If item1 is connected to item2 through a property, use this to get the property name label.
```sparql
?item1 ?property ?item2.
OPTIONAL { ?propertyName wikibase:directClaim ?property. }
```

### 15.6. Defining Constants
Use `VALUES` to define a fixed item as a starting point.
```sparql
VALUES (?item) {(wd:Q138809)}
```

### 15.7. Identifying Backward Relationships
Use this snippet to find out which properties connect other items to a specific central item (e.g., Albert Einstein). This is useful for identifying "incoming" connections that you might want to include in your map.

```sparql
SELECT ?itemLabel ?propertyLabel ?item ?property
WHERE {
  # Connects the item (?item) to Albert Einstein (wd:Q937) via any direct predicate (?directProp)
  ?item ?directProp wd:Q937.
  
  # Maps the technical URI (prop/direct/P...) to the actual Property entity (entity/P...)
  # This step is crucial for the Label Service to find the human-readable name.
  ?property wikibase:directClaim ?directProp .

  # Ensures that only standard Wikidata items (starting with Q) are returned, 
  # filtering out internal statement nodes or references.
  FILTER(STRSTARTS(STR(?item), "http://www.wikidata.org/entity/Q"))

  # Label Service for fetching names in German, falling back to English
  SERVICE wikibase:label { 
    bd:serviceParam wikibase:language "de,en". 
  }
}
ORDER BY ?propertyLabel
```

### 15.8. Identifying Important Backward Relationships
This advanced version of the backward relationship query filters results to show only "important" items (those with at least 5 referrers on WikiData) and sorts them by importance. This helps in filtering out noise when exploring connections.

```sparql
SELECT ?itemLabel ?propertyLabel ?item ?property (COUNT(?referrer) AS ?importance)
WHERE {
  # 1. Connect item to Einstein (wd:Q937)
  ?item ?directProp wd:Q937.
  
  # 2. Map to the actual Property entity for the label
  ?property wikibase:directClaim ?directProp .

  # 3. Count referrers: Only allow direct properties (wdt:) 
  # and ensure the referrer is a standard Item (Q)
  ?referrer ?anyDirectProp ?item .
  FILTER(STRSTARTS(STR(?anyDirectProp), "http://www.wikidata.org/prop/direct/"))
  FILTER(STRSTARTS(STR(?referrer), "http://www.wikidata.org/entity/Q"))

  # 4. Filter the target item to be a standard Q-item
  FILTER(STRSTARTS(STR(?item), "http://www.wikidata.org/entity/Q"))

  SERVICE wikibase:label { 
    bd:serviceParam wikibase:language "de,en". 
  }
}
GROUP BY ?item ?itemLabel ?property ?propertyLabel
# Filter out items with less than 5 referrers
HAVING (COUNT(?referrer) >= 5)
# Sort by property name, then by importance
ORDER BY ?propertyLabel DESC(?importance)
```

---

## 16. Tips
*   **Performance:** Use `OPTIONAL` to prevent timeouts wherever possible.
*   **Separation:** Use `#query` at the start of a line to separate different queries within the same `.sparql` file.
*   **Merging:** Because items are identified by URI (`i_`), you can define connections in one query and add categories or images in another; the tool will combine them.

---

## 17. Handling Multi-Value Properties and Row Explosion

When a WikiData item has multiple values for the same property (e.g., Venus has several values for temperature: mean, maximum, etc.), using multiple `OPTIONAL` blocks in a single `SELECT` statement leads to a **Cartesian product**. 

If an item has 3 temperature values and 3 radius values, the query will return **9 rows** (3x3). This causes the KnowledgeBase Builder to duplicate data or misalign table entries.

### 17.1. The UNION Strategy
To prevent this "row explosion," fetch each property in a separate `UNION` block. This produces a "long" result set (rows are added instead of columns multiplied). The KnowledgeBase Builder then merges these rows based on the unique `i_` ID.

### 17.2. Dynamic Labels using Qualifiers
To distinguish between multiple values (e.g., "Radius (equator)" vs "Radius (mean)"), you should fetch the **Qualifiers** from WikiData and use them to build a dynamic Table Relation label (`rn_t_`).

**Implementation Example:**
```sparql
SELECT ?i_item ?rn_t_Label (?rn_t_Label as ?rc_Label) ?ic_Value
WHERE {
  {
    # Block 1: Temperature
    ?i_item p:P2076 ?stat. 
    ?stat psv:P2076 [wikibase:quantityAmount ?amt; wikibase:quantityUnit [rdfs:label ?unit]].
    # Optional: Get qualifier (e.g. "mean" or "surface")
    OPTIONAL { ?stat (pq:P518|pq:P1480) [rdfs:label ?qual]. FILTER(LANG(?qual)="en") }
    
    # Get the property name dynamically
    ?prop wikibase:directClaim wdt:P2076. ?prop rdfs:label ?pLabel. FILTER(LANG(?pLabel)="en")
    
    # Build a specific label: "Temperature (surface)"
    BIND(IF(BOUND(?qual), CONCAT(?pLabel, " (", ?qual, ")"), ?pLabel) AS ?rn_t_Label)
  }
  UNION
  {
    # Block 2: Radius (analogous to above)
    ?i_item p:P2120 ?stat. 
    ...
  }
  
  # Format the value with unit
  FILTER(LANG(?unit)="en")
  BIND(CONCAT(STR(?amt), " ", ?unit) AS ?ic_Value)
}
```

### Benefits of this approach:
1.  **Correctness:** No row explosion, ensuring the tool assigns values correctly.
2.  **Precision:** The table in the MindMap will show specific rows like "Radius (equator)" and "Radius (polar)" instead of just multiple entries named "Radius".
3.  **Flexibility:** You can add as many `UNION` blocks as needed without affecting the performance of other property fetches.

