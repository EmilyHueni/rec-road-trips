CREATE OR REPLACE VIEW us_road_network.rec_park_clusters_110_centroids
 AS
 SELECT rec_park_clusters_110.k_clusters AS facil_k_clusters,
    st_centroid(st_union(st_setsrid(st_makepoint(rec_park_clusters_110.facil_x, rec_park_clusters_110.facil_y), 2163))) AS geom
   FROM us_road_network.rec_park_clusters_110
  GROUP BY rec_park_clusters_110.k_clusters
  ORDER BY rec_park_clusters_110.k_clusters;
  
  

CREATE OR REPLACE VIEW us_road_network.zip_code_clusters_300_centroids
 AS
 SELECT zip_code_clusters_300.k_clusters AS zip_k_clusters,
    st_centroid(st_union(st_setsrid(st_makepoint(zip_code_clusters_300.zip_x, zip_code_clusters_300.zip_y), 2163))) AS geom
   FROM us_road_network.zip_code_clusters_300
  GROUP BY zip_code_clusters_300.k_clusters
  ORDER BY zip_code_clusters_300.k_clusters;