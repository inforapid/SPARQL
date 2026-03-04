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

---

## 12. Comprehensive Example

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

## 13. Tips
*   **Separation:** Use `#query` at the start of a line to separate different queries within the same `.sparql` file.
*   **Merging:** Because items are identified by URI (`i_`), you can define connections in one query and add categories or images in another; the tool will combine them.
