----------basic data cleaning and selecting for data (in corrected datatypes) that is needed.  ONly including reservations we have geometry info (both facility and zip) and the trip must be fully in the continental_us
--results in about 2.6 million reservations
create table  us_road_network.rec_gov_raw_2020 as
SELECT row_number() over(), parentlocation, park, sitetype, usetype, inventorytype, facilityid, facilityzip, facilitystate, 
customerzip, customerstate, customercountry, 
nullif(startdate, '')::date  as startdate, 
nullif(enddate, '')::date as enddate, 
nullif(orderdate, '')::timestamp as orderdate, 
nights, 
nullif(numberofpeople, '')::int as numberofpeople, 
st_transform(st_setsrid(st_makepoint(nullif(facilitylongitude, '')::numeric, nullif(facilitylatitude, '')::numeric), 4326), 2163) AS facil_geom,
st_setsrid(st_geomfromtext(b.geom), 2163) as zip_geom
	FROM public.fy20_historical_reservations_full a
	left join
	public.us_zip_code_points_2163 b
	on a.customerzip=zcta5ce10::numeric::int::character varying,
	continental_us c
	where b.geom is not null 
	and st_makepoint(nullif(facilitylongitude, '')::numeric, nullif(facilitylatitude, '')::numeric) is not null
	and st_intersects(st_transform(st_setsrid(st_makepoint(nullif(facilitylongitude, '')::numeric, nullif(facilitylatitude, '')::numeric), 4326), 2163), c.geom)
	and st_intersects(st_setsrid(st_geomfromtext(b.geom), 2163), c.geom)

	
--spatial indexes
CREATE INDEX rec_gov_raw_2020_geom_idx_zip_geom
  ON us_road_network.rec_gov_raw_2020
  USING GIST (zip_geom);

CREATE INDEX rec_gov_raw_2020_geom_idx_facil_geom
  ON us_road_network.rec_gov_raw_2020
  USING GIST (facil_geom);