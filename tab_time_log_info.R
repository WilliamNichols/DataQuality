tab_time_log_info<-dbGetQuery(con, paste("
  SELECT time_log_fact_key,
         project_key,
         time_log_delta_minutes,
         time_log_start_date,
         time_log_end_date,
         Date_format(time_log_start_date, '%Y-%m-%d') AS start_day,
         Date_format(time_log_end_date, '%Y-%m-%d')   AS end_day,
         phase_base.phase_base_key,
         phase_base.phase_short_name
  FROM   time_log_fact_hist
         LEFT JOIN plan_item_hist
              ON time_log_fact_hist.plan_item_key = plan_item_hist.plan_item_key
         LEFT JOIN phase
              ON plan_item_hist.phase_key = phase.phase_key
         LEFT JOIN phase_mapping
              ON phase.phase_key = phase_mapping.phase_key
         LEFT JOIN phase_base
              ON phase_mapping.phase_base_key = phase_base.phase_base_key
  WHERE  plan_item_hist.row_current_flag     = 1
     AND time_log_fact_hist.row_current_flag = 1
     AND time_log_start_date > '1900-01-01 00:00:00'
     AND time_log_end_date > '1900-01-01 00:00:00'
     AND project_key IN ( ", str_unit," )
                                           " , seq=""))