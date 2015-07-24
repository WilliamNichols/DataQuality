(tab_task_completion_info<-dbGetQuery(con, paste("
SELECT    task_date_fact_key,
          project_key,
          task_date_key,
          Date_format(task_date_key, '%Y-%m-%d') AS task_completion_date,
          measurement_type_key,
          phase_base.phase_short_name,
          wbs_element_key
FROM       task_date_fact_hist
  LEFT JOIN  plan_item_hist
         ON     task_date_fact_hist.plan_item_key = plan_item_hist.plan_item_key
  LEFT JOIN phase
         ON     plan_item_hist.phase_key = phase.phase_key
  LEFT JOIN phase_mapping
         ON     phase.phase_key = phase_mapping.phase_key
  LEFT JOIN phase_base
         ON     phase_mapping.phase_base_key = phase_base.phase_base_key
WHERE       task_date_fact_hist.row_current_flag = 1
  AND       plan_item_hist.row_current_flag      = 1
  AND       project_key IN (", str_unit, ")"
                                              , seq=""))