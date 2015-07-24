tab_person_info<-dbGetQuery(con, paste("
 SELECT distinct project_key, 
                 person_key 
 FROM            time_log_fact_hist 
 JOIN            data_block ON time_log_fact_hist.data_block_key = data_block.data_block_key 
 JOIN            plan_item  ON time_log_fact_hist.plan_item_key  = plan_item.plan_item_key 
 WHERE           project_key IN (", str_unit, ")
                                       ", seq=""))
