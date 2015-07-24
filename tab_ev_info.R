tab_ev_info<-dbGetQuery(con, paste("
SELECT DISTINCT project_key,
                phase_base.phase_base_key,
                phase_base.phase_short_name,
                phase_type,
                wbs_element_key,
                task_actual_time_minutes,
                task_plan_time_minutes,
                task_actual_complete_date_key,
                task_date_key,
                measurement_type_key,
                defects_found
FROM            task_status_fact_hist
   LEFT JOIN    task_date_fact_hist
          ON        task_status_fact_hist.plan_item_key = task_date_fact_hist.plan_item_key
   LEFT JOIN    plan_item_hist
          ON        task_status_fact_hist.plan_item_key = plan_item_hist.plan_item_key
   LEFT JOIN    phase
          ON        plan_item_hist.phase_key = phase.phase_key
    LEFT JOIN   phase_mapping
          ON        phase.phase_key = phase_mapping.phase_key
   LEFT JOIN    phase_base
          ON        phase_mapping.phase_base_key = phase_base.phase_base_key
   LEFT JOIN
                (
                         SELECT   Sum(defect_fix_count) AS defects_found,
                                  plan_item_key
                         FROM     defect_log_fact_hist
                         GROUP BY plan_item_key) AS defect_table
           ON    defect_table.plan_item_key = task_status_fact_hist.plan_item_key
WHERE         task_status_fact_hist.row_current_flag = 1
  AND         plan_item_hist.row_current_flag       = 1
  AND         project_key IN (", str_unit, ")
                                             " , seq=""))
