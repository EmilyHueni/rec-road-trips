
--query unique trips from the rec.gov data and join to the corresponding clusters for their start and end locations

create table us_road_network.unique_trips_clusters_trip_id as
SELECT unique_trips.*, 
concat(zip_code_clusters_300.k_clusters::character varying, '_',  rec_park_clusters_110.k_clusters::character varying) as trip_id,
zip_code_clusters_300.k_clusters as zip_k_clusters, zip_code_clusters_300_centroids.geom as zip_k_clusters_cent_geom,
rec_park_clusters_110.k_clusters as facil_k_clusters, rec_park_clusters_110_centroids.geom as facil_k_clusters_cent_geom

FROM
(select distinct concat(customerzip, '_',  facilityid) as trip_id_detail, customerzip, facilityid from us_road_network.rec_gov_raw_2020) unique_trips
left join 
us_road_network.zip_code_clusters_300 
on unique_trips.customerzip = zip_code_clusters_300.customerzip
left join
us_road_network.zip_code_clusters_300_centroids
on zip_code_clusters_300.k_clusters = zip_code_clusters_300_centroids.zip_k_clusters
left join 
us_road_network.rec_park_clusters_110
on unique_trips.facilityid = rec_park_clusters_110.facilityid
left join
us_road_network.rec_park_clusters_110_centroids
on rec_park_clusters_110.k_clusters = rec_park_clusters_110_centroids.facil_k_clusters;


--spatial indexes
CREATE INDEX unique_trips_clusters_trip_id_facil_center_geom_idx
  ON us_road_network.unique_trips_clusters_trip_id
  USING GIST (facil_k_clusters_cent_geom);
  
  CREATE INDEX unique_trips_clusters_trip_id_zip_center_geom_idx
  ON us_road_network.unique_trips_clusters_trip_id
  USING GIST (zip_k_clusters_cent_geom);

--and a primary key
ALTER TABLE us_road_network.unique_trips_clusters_trip_id ADD PRIMARY KEY (trip_id_detail);


--create the start stop table
--the trip_id is from cluster to cluster (not zip to facil)
create table us_road_network.routes_start_stop_points as
  SELECT trip_id,
(pgis_fn_nn(a.zip_k_clusters_cent_geom, 100000, 1, 100, 'us_road_network.roads_us',  'true', 'source', 'geom')).nn_gid as origin,
(pgis_fn_nn(a.facil_k_clusters_cent_geom, 100000, 1, 100, 'us_road_network.roads_us',  'true', 'target', 'geom')).nn_gid as destination
  FROM (SELECT DISTINCT trip_id, zip_k_clusters_cent_geom, facil_k_clusters_cent_geom FROM us_road_network.unique_trips_clusters_trip_id) a;
  
  
  
  
  
--create table for the insert into resulting routes
--will be used for bulk processing route data in parallel
create table us_road_network.trip_routes as
SELECT  a.trip_id,
        SUM(a.cost) AS agg_cost,
        ST_Union(b.geom) AS geom       -- ST_Collect(b.geom)
FROM    (
    SELECT  trip_id, 
            (pgr_dijkstra(
                'SELECT id::int, source::bigint, target::bigint, travel_cost::float as cost FROM us_road_network.roads_us',
                origin,
                destination,
                false
            )).*
    FROM    (SELECT * FROM (SELECT row_number() over(), * FROM us_road_network.routes_start_stop_points order by trip_id) t_r where row_number<10) t
) AS a
JOIN    us_road_network.roads_us AS b
  ON    a.edge = b.id
GROUP BY
        a.trip_id
ORDER BY
        a.trip_id;