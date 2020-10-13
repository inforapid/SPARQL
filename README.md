# SPARQL

SPARQL queries for the WikiData endpoint for use with the InfoRapid KnowledgeBase Builder

## SPARQL and the InfoRapid KnowledgeBase Builder

### The following prefixes must be used for SPARQL variables in the SELECT statement:
```
i_ : item
ic_ : item category, the column values are ignored, only the column header is relevant
in_ or i_XXXLabel or ic_XXXLabel: item name
id_ or i_XXXDescription or ic_XXXDescription: item description
iu_ : item url
ii_ : item image
rn_ : relation name
rn_t_ : relation name for a table relation
rc_ : relation category

The columns in the SELECT statement must have the following order (the values in round brackets are optional)

?i_item1 (?ic_item1) (?in_item1) (?id_item1) (?iu_item1) (?ii_item1) (?rn_relation1) (?rc_relation1) ?i_item2 (?ic_item2) ... (?rn_relation2) (?i_item3) ...

This SELECT statement connects item1 through relation1 with item2 and through relation 2 with item3

One result row can connect item1 with any number of other items

A line starting with the comment #query can be used to separte many queries
```
