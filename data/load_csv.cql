CREATE INDEX on :Station(stationName);

LOAD CSV FROM "https://raw.githubusercontent.com/neo4j-meetups/graphconnect-2016/master/data/runtimes.csv" AS csvLine
WITH csvLine[0] AS lineName,
     csvLine[1] AS direction,
     csvLine[2] AS startStationName,
     csvLine[3] AS destinationStationName,
     toFloat(csvLine[4]) AS distance,
     toFloat(csvLine[5]) AS runningTime

MERGE (start:Station { stationName: startStationName})
MERGE (destination:Station { stationName: destinationStationName})
MERGE (line:Line { lineName: lineName})
MERGE (line) - [:DIRECTION] -> (dir:Direction { direction: direction})
CREATE (inPlatform:InPlatform {name: "In: " + destinationStationName + " " + lineName + " " + direction})
CREATE (outPlatform:OutPlatform {name: "Out: " + startStationName + " " + lineName + " " + direction})
CREATE (inPlatform) - [:AT] -> (destination)
CREATE (outPlatform) - [:AT] -> (start)
CREATE (inPlatform) - [:ON] -> (dir)
CREATE (outPlatform) - [:ON] -> (dir)
CREATE (outPlatform) - [r:TRAIN {distance: distance, runningTime: runningTime}] -> (inPlatform);

// post processing
MATCH (station:Station) <-[:AT]- (platformIn:InPlatform),
      (station:Station) <-[:AT]- (platformOut:OutPlatform),
      (direction:Direction) <-[:ON]- (platformIn:InPlatform),
      (direction:Direction) <-[:ON]- (platformOut:OutPlatform)
CREATE (platformIn) -[:WAIT {runningTime: 0.5}]-> (platformOut);

// link the Euston stations
MATCH (euston:Station {stationName: "EUSTON"})<-[:AT]-(eustonIn:InPlatform)
MATCH (eustonCx:Station {stationName: "EUSTON (CX)"})<-[:AT]-(eustonCxIn:InPlatform)
MATCH (eustonCity:Station {stationName: "EUSTON (CITY)"})<-[:AT]-(eustonCityIn:InPlatform)

CREATE UNIQUE (eustonIn)-[:WAIT {runningTime: 0.0}]->(eustonCxIn)
CREATE UNIQUE (eustonIn)-[:WAIT {runningTime: 0.0}]->(eustonCityIn)
CREATE UNIQUE (eustonCxIn)-[:WAIT {runningTime: 0.0}]->(eustonCityIn);

// link the Kennington stations
MATCH (kenningtonCx:Station {stationName: "KENNINGTON (CX)"})<-[:AT]-(kenningtonCxIn:InPlatform)
MATCH (kenningtonCity:Station {stationName: "KENNINGTON (CITY)"})<-[:AT]-(kenningtonCityIn:InPlatform)

CREATE UNIQUE (kenningtonCxIn)-[:WAIT {runningTime: 0.0}]->(kenningtonCityIn);

// query
MATCH (startStation:Station { stationName: 'KINGS CROSS'})
MATCH (destinationStation:Station { stationName: 'SOUTHWARK'})
MATCH path = shortestPath(startStation-[*]-destinationStation)
return path;
