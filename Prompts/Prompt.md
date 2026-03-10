Verwende folgendes fiktives SPARQL Template als Basis und passe es so an, dass es statt Q1, P1, P2 folgende Daten abfragt:

Main Topic: wd:Q937 Albert Einstein
Relations to first level childs: P61
Relations to second level childs: P2579, P279, P1269

Die Namen und die Reihenfolge der Namen im SELECT-Statement dürfen nicht angepasst werden.

Die Triple-Struktur des Templates darf nicht verändert werden.
Insbesondere muss das Pattern `?childItem PROPERTY ?topic` unverändert bleiben.
Es dürfen nur die IDs von Topic und Properties ersetzt werden.

Diese Query soll mehrfach wiederholt werden, wobei ab der zweiten Ebene eine Zeile mit dem Kommentar #query jeder Query vorangestellt werden soll.
Die Query für die zweite Ebene soll mit
BIND(wd:Q1 AS ?topic)
# Get all child items connected to the topic
?childItem wdt:P1|wdt:P2 ?topic .
beginnen. Danach sollen die Grand Childs abgefragt werden mit
?grandChildItem wdt:P3|wdt:P4 ?childItem .
?i_start soll dann an das ?childItem, ?i_end an das ?grandChildItem gebunden werden.
Diese Logik soll auch bei tieferen Ebenen angewandt werden.

Die erstellten Queries werden zwar voneinander unabhängig ausgeführt, sie sollen aber in einer Textbox zusammen ausgegeben werden, nicht einzeln, damit sie auf einmal kopiert werden können.

"short name for relation to child item" soll durch einen maximal 3 Worte langen Text ersetzt werden, der die Beziehung zu dem Kindelement am besten und treffendsten beschreibt.

SELECT * WHERE {
  {
    SELECT
      ?i_start ?i_startLabel ?i_startDescription ?ic_Topic ?ii_startImage ?iu_startUrl
      ?rn_Name (?rn_Name AS ?rc_Category)
      ?i_end ?i_endLabel ?i_endDescription ?ic_War ?ii_endImage ?iu_endUrl
    WHERE {
      # Define the central node (Topic - Q1)
      BIND(wd:Q1 AS ?topic)
      
      # Get all child items connected to the topic
      ?childItem wdt:P1|wdt:P2 ?topic .
      
      # Optional images
      OPTIONAL { ?topic wdt:P18 ?topicImage . }
      OPTIONAL { ?childItem wdt:P18 ?childItemImage . }
      
      # Bind variables for start and end nodes and images
      BIND(?topic AS ?i_start)
      BIND(?childItem AS ?i_end)
      BIND(?topicImage AS ?ii_startImage)
      BIND(?childItemImage AS ?ii_endImage)
      
      # Relation name placeholder
      BIND("short name for relation to child item" AS ?rn_Name)
      
      # Standard Label Service for English labels and descriptions
      SERVICE wikibase:label { 
        bd:serviceParam wikibase:language "en". 
      }
    }
  }
  
  # Filters to remove empty labels or descriptions
  FILTER(STRLEN(?i_startLabel) > 0)
  FILTER(STRLEN(?i_startDescription) > 0)
  FILTER(STRLEN(?i_endLabel) > 0)
  FILTER(STRLEN(?i_endDescription) > 0)
}
