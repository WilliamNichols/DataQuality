tab_time_overlap_info<-dbGetQuery(con, paste("
    SELECT time_log_fact_key,
           time_log_fact_hist.plan_item_key,
           wbs_element_key,
           person_key,project_key,
           ( SELECT     time_log_end_date 
             FROM       time_log_fact_hist AS t2 
             LEFT JOIN  data_block         AS d2 ON t2.data_block_key = d2.data_block_key 
             WHERE      d2.person_key        = d1.person_key 
               AND     t2.time_log_fact_key = time_log_fact_hist.time_log_fact_key-1
           )       AS pre_time_log_end_date,
           time_log_start_date,
           time_log_end_date,
           date_format(time_log_start_date, '%Y-%m-%d') AS start_day, 
           date_format(time_log_end_date, '%Y-%m-%d')   AS end_day,
           time_log_delta_minutes,
           time_log_interrupt_minutes 
 FROM time_log_fact_hist 
 LEFT JOIN data_block AS d1 ON time_log_fact_hist.data_block_key = d1.data_block_key 
 LEFT JOIN plan_item        ON time_log_fact_hist.plan_item_key  = plan_item.plan_item_key 
 WHERE     project_key in (", str_unit, ")
   AND    time_log_fact_hist.row_current_flag = 0
 ORDER BY project_key,person_key,
           time_log_start_date
", seq=""))
