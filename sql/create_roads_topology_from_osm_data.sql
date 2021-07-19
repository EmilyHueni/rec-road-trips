--simplify columns need in road network and reproject to meters and equal area projection.
-- also changed unique identifier to be more compatible with pgrouting columns needed
--only include roads in the continental us.

CREATE table us_road_network.roads_us AS 
 SELECT lines.ogc_fid as id,
    st_transform(st_setsrid(ST_GeomFromEWKB(lines._ogr_geometry_), 4326), 2163) AS geom,
    lines.osm_id,
    lines.name,
    lines.highway,
    lines.other_tags
   FROM lines,
   continental_us
   where st_intersects(st_transform(st_setsrid(ST_GeomFromEWKB(lines._ogr_geometry_), 4326), 2163), geom)
WITH DATA;


--dont forget your spatial indexes!!!
CREATE INDEX roads_us_geom_idx
  ON us_road_network.roads_us
  USING GIST (geom);

--and a primary key
ALTER TABLE us_road_network.roads_us ADD PRIMARY KEY (id);



--add cost column on estimated speeds 
--Remeber it is in meters and not miles so speed is adjusted accordingly!
 alter table us_road_network.roads_us add column estimated_speed integer;

UPDATE us_road_network.roads_us
   SET estimated_speed=case 
   when highway IN ('motorway', 'motorway_link') then 120701 --75mph
   when highway IN ('primary', 'primary_link', 'trunk') then 96560 --60mph
        when highway IN ('secondary_link', 'secondary') then 72420 --45mph
       else 64373 --40mph
       end;
	   
------add column for cost using speed and geom length
alter table us_road_network.roads_us add column travel_cost float;

UPDATE us_road_network.roads_us
   SET travel_cost=st_length(geom)/estimated_speed;
   
   
   
-- making the road routing capable
-- once again making it compatible with the pgrouting terminology
ALTER TABLE us_road_network.roads_us ADD COLUMN "source" bigint;
ALTER TABLE us_road_network.roads_us ADD COLUMN "target" bigint;


--create topology for all of the lines
select pgr_createTopology('us_road_network.roads_us', 150, 'geom', 'id');