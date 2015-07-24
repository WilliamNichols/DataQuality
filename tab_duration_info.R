tab_duration_info<-dbGetQuery(con, paste("
  SELECT project_key,
         Min(time_log_start_date)                          AS start_date,
         Date_format(Min(time_log_start_date), '%Y%u')     AS start_week,
         Max(time_log_end_date)                            AS end_date,
         Date_format(Max(time_log_start_date), '%Y%u')     AS end_week,
         ( Date_format(Max(time_log_start_date), '%Y%u') -
         Date_format(Min(time_log_start_date), '%Y%u') ) AS actual_weeks
  FROM   time_log_fact_hist
     JOIN  plan_item_hist
       ON   time_log_fact_hist.plan_item_key = plan_item_hist.plan_item_key
    WHERE   time_log_fact_key != 23000
      AND   time_log_fact_hist.row_current_flag = 1
      AND   plan_item_hist.row_current_flag     = 1
      AND   project_key IN ( ", str_unit," )
    GROUP  BY project_key"
                                       , seq=""))