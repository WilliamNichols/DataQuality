tab_completed_task_time_info<-dbGetQuery(con, paste("
  SELECT project_key,
         phase_base.phase_short_name,
         phase_base.phase_base_key,
         phase_base.phase_ordinal,
         MIN(task_actual_start_date_key)    AS task_begin_date,
         MAX(task_actual_complete_date_key) AS task_end_date,
         SUM(task_actual_time_minutes)      AS sum_actual_time,
         SUM(task_plan_time_minutes)        AS sum_plan_time,phase_type
    FROM        task_status_fact_hist
      LEFT JOIN plan_item_hist
             ON   task_status_fact_hist.plan_item_key = plan_item_hist.plan_item_key
      LEFT JOIN phase
             ON   plan_item_hist.phase_key = phase.phase_key
      LEFT JOIN phase_mapping
             ON   phase.phase_key = phase_mapping.phase_key
      LEFT JOIN phase_base
             ON   phase_mapping.phase_base_key = phase_base.phase_base_key
          WHERE   phase_base.phase_base_key IS NOT NULL
            AND   plan_item_hist.row_current_flag        = 1
            AND   task_status_fact_hist.row_current_flag = 1
            AND   task_actual_complete_date_key > 20000101
            AND   task_actual_complete_date_key < 99990000
            AND   project_key in (", str_unit, ")
       GROUP BY project_key,phase_short_name
       ORDER BY project_key,
                phase_base.phase_ordinal,
                phase_base.phase_base_key
                                         ", seq=""))