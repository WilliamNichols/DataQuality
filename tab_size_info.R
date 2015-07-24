tab_size_info<-dbGetQuery(con, paste("
  SELECT distinct size_fact_key, 
                  size_added_and_modified, 
                  size_added, 
                  size_base, 
                  size_deleted, 
                  size_modified, 
                  size_reused, 
                  size_total, 
                  measurement_type_key, 
                  size_fact_hist.size_metric_key, 
                  size_metric_name, 
                  team_key, 
                  person_key, 
                  wbs_element_key, 
                  project_key, 
                  size_fact_hist.data_block_key, 
                  size_fact_hist.plan_item_key 
  FROM       size_fact_hist 
  left join  plan_item   ON size_fact_hist.plan_item_key   = plan_item.plan_item_key 
  left join  data_block  ON size_fact_hist.data_block_key  = data_block.data_block_key 
  left join  size_metric ON size_fact_hist.size_metric_key = size_metric.size_metric_key 
  WHERE      project_key IN (", str_unit, ")
", seq=""))
