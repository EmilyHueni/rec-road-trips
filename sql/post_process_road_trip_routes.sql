--transform resulting multiline into a single line and simplify geometry

create table us_road_network.trip_routes_lines_merged as
SELECT trip_id, agg_cost, ST_LineMerge(geom) as geom, ST_Simplify(ST_LineMerge(geom), 100000) geom_simple
	FROM us_road_network.trip_routes;

	
-- break trip lines up by days (best estimate on how far people are willing to drive in a day)
--drop table us_road_network.trip_routes_lines_merged_travel_segments

create table us_road_network.trip_routes_lines_merged_travel_segments as 
SELECT trip_id, agg_cost, 
case when agg_cost<9 then 1
when agg_cost<18 then 2
when agg_cost<27 then 3
else 4
end as num_days_drivng,
case when agg_cost<9 then array[st_astext(geom_simple)]
when agg_cost<18 then array[st_astext(st_linesubstring(geom_simple, 0, .5)), st_astext(st_linesubstring(geom_simple, .5, 1))]
when agg_cost<27 then array[st_astext(st_linesubstring(geom_simple, 0, .33)), st_astext(st_linesubstring(geom_simple, .33, .66)), st_astext(st_linesubstring(geom_simple, .66, 1))]
else array[st_astext(st_linesubstring(geom_simple, 0, .25)), st_astext(st_linesubstring(geom_simple, .25, .5)), st_astext(st_linesubstring(geom_simple, .5, .75)), st_astext(st_linesubstring(geom_simple, .75, 1))]
end as travel_segments,
geom_simple
	FROM us_road_network.trip_routes_lines_merged;
	
	
----create a master trip table
create table us_road_network.rec_gov_raw_2020_master as
SELECT row_number, b.trip_id, agg_cost, num_days_drivng, parentlocation, park, sitetype, usetype, inventorytype, a.facilityid, facilitystate, 
a.customerzip, customerstate, startdate, case when enddate is null then startdate + INTERVAL '1 day'
else enddate
end as enddate, 
orderdate, 
case when numberofpeople is null then 1 else numberofpeople end as numberofpeople, facil_geom as facil_geom, zip_geom as zip_geom
FROM us_road_network.rec_gov_raw_2020 a
left join 
us_road_network.unique_trips_clusters_trip_id b
on 
a.customerzip=b.customerzip and a.facilityid=b.facilityid
left join
us_road_network.trip_routes_lines_merged_travel_segments c
on
b.trip_id = c.trip_id
where c.trip_id is not null;
	
	