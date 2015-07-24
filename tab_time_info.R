tab_time_info<-dbGetQuery(con, paste("
 SELECT distinct time_log_fact_key, 
                 time_log_delta_minutes, 
                 time_log_interrupt_minutes, 
                 time_log_start_date, 
                 time_log_start_date_key, 
                 time_log_end_date, 
                 team_key, 
                 person_key, 
                 wbs_element_key, 
                 project_key, 
                 time_log_fact_hist.data_block_key, 
                 time_log_fact_hist.plan_item_key 
  FROM           time_log_fact_hist 
  LEFT JOIN      plan_item  ON time_log_fact_hist.plan_item_key  = plan_item.plan_item_key 
  LEFT JOIN      data_block ON time_log_fact_hist.data_block_key = data_block.data_block_key 
  WHERE          project_key in (", str_unit, ")
    AND          time_log_fact_hist.row_current_flag = 1
", seq=""))
