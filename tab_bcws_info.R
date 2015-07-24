tab_bcws_info<-dbGetQuery(con, paste("
  SELECT project_key,
         Sum(s.task_plan_time_minutes) AS sum_plan_minutes
  FROM   task_status_fact s,
         task_date_fact   d,
         measurement_type t,
         plan_item_hist   h
  WHERE  s.plan_item_key             = d.plan_item_key

    AND  s.data_block_key        = d.data_block_key
    AND  d.measurement_type_key  = t.measurement_type_key
    AND  t.measurement_type_name = 'Plan'
    AND  d.task_date_key        <= 29991231
    AND  s.plan_item_key         = h.plan_item_key
    AND  s.row_current_flag      = 1
    AND  h.row_current_flag      = 1
    AND  d.row_current_flag      = 1
    AND  project_key IN ( ", str_unit," )
  GROUP  BY project_key
                                             ", seq=""))