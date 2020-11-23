# SPARQL

In this project I want to collect useful SPARQL queries for the WikiData endpoint for use with the InfoRapid KnowledgeBase Builder. Please participate and publish your own favorite SPARQL queries.

## SPARQL and the InfoRapid KnowledgeBase Builder

![3D rotating MindMap of SPARQL query result](images/Example.gif?raw=true "Example")

### The following prefixes must be used for SPARQL variables in the KnowledgeBase Builder SELECT statement:
```
i_ : item
ic_ : item category, the column values are ignored, only the column header is relevant
in_ or i_XXXLabel or ic_XXXLabel: item name
id_ or i_XXXDescription or ic_XXXDescription: item description
iu_ : item url
ii_ : item image
idi_ : item description image
rn_ : relation name
rn_t_ : relation name for a table relation
rc_ : relation category

The columns in the SELECT statement must have the following order (the values in round brackets are optional)

?i_item1 (?ic_item1) (?in_item1) (?id_item1) (?iu_item1) (?ii_item1) (?rn_relation1) (?rc_relation1) ?i_item2 (?ic_item2) ... (?rn_relation2) (?i_item3) ...

This SELECT statement connects item1 through relation1 with item2 and through relation 2 with item3

One result row can connect item1 with any number of other items

A line starting with the comment #query can be used to separte many queries
```

## Tips for SPARQL queries
* Use OPTIONAL to prevent timeouts wherever it's possible

## SPARQL code snippets for use with the InfoRapid KnowledgeBase Builder

#### Convert an url so that it opens inplace in the KnowledgeBase Builder:
```
BIND (CONCAT (STR (?url), "§if") AS ?iu_url).
```

#### Create an url which links ?i_place to its position in Google Maps
```
OPTIONAL { ?i_place p:P625 ?statement.
  ?statement psv:P625 ?coordinate_node.
  ?coordinate_node wikibase:geoLatitude ?lat.
  ?coordinate_node wikibase:geoLongitude ?long.
  BIND (CONCAT ("http://www.google.com/maps/place/", STR(?lat), ",", STR(?long), "§if") AS ?iu_url).
}
```

#### Query the Wikipedia url for i_item
```
OPTIONAL { ?iu_wikipedia_url schema:about ?i_item; schema:isPartOf <https://en.wikipedia.org/> }
```

#### Find all places within a given radius around a central location
```
?centerPlace wdt:P625 ?centerLoc.
SERVICE wikibase:around {
  ?i_place wdt:P625 ?location. # the first statement must include the place and the location
  bd:serviceParam wikibase:center ?centerLoc.
  bd:serviceParam wikibase:radius "10". # maximum distance in kilometers
  bd:serviceParam wikibase:distance ?dist. # current distance in kilometers
}
```

#### Calculate the distance between two locations
```
BIND (geof:distance (?location1, ?location2) AS ?dist).
```

#### Round the distance with a precision of 10 meters and add the unit m
```
BIND (CONCAT (xsd:string (xsd:integer (CEIL (100 * ?dist) * 10)), " m") AS ?rounded_dist_in_m).
```

#### item1 is connected to item2 through property, get the propertyName (SELECT propertyNameLabel)
```
?item1 ?property ?item2.
OPTIONAL { ?propertyName wikibase:directClaim ?property. }
```

#### Get the image to an item
```
OPTIONAL { ?i_item wdt:P18 ?ii_itemImage. }
```

#### Get Date of Birth / Date of Death / Place of Birth / Place of Death for a person
```
OPTIONAL { ?i_person wdt:P569 ?ic_DateOfBirth. }
OPTIONAL { ?rn_t_DateOfBirth wikibase:directClaim wdt:P569. }
OPTIONAL { ?i_person wdt:P570 ?ic_DateOfDeath. }
OPTIONAL { ?rn_t_DateOfDeath wikibase:directClaim wdt:P570. }
OPTIONAL { ?i_person wdt:P19 ?ic_PlaceOfBirth. }
OPTIONAL { ?rn_t_PlaceOfBirth wikibase:directClaim wdt:P19. }
OPTIONAL { ?i_person wdt:P20 ?ic_PlaceOfDeath. }
OPTIONAL { ?rn_t_PlaceOfDeath wikibase:directClaim wdt:P20. }
```

#### Define a constant
```
VALUES (?item) {(wd:Q138809)}
```
