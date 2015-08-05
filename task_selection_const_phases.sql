select  process_name
      ,  plan_item.project_key
	  ,  plan_item.wbs_element_key
      ,  plan_item.plan_item_key
	  ,  plan_item.task_key
      ,  task_status_fact_key
      ,  plan_item.phase_key
      ,  phase_name
      ,  phase_order.phase_ordinal
      ,  plan_item.phase_key
      ,  size_metric.size_metric_name
      ,  size_fact_hist.size_added_and_modified
      ,  task_status_fact_hist.task_actual_complete_date
      ,  task_plan_time_minutes
      ,  task_status_fact_hist.task_actual_time_minutes
  from task_status_fact_hist
  left join plan_item    ON task_status_fact_hist.plan_item_key=plan_item.plan_item_key
        and                 plan_item_deleted_flag=0
  left join phase ON phase.phase_key=plan_item.phase_key
  left join process ON process.process_key = phase.process_key
  left join phase_order ON phase_order.phase_key = phase.phase_key
  left join size_fact_hist ON  size_fact_hist.plan_item_key=plan_item.plan_item_key
        AND size_fact_hist.row_current_flag=1
        AND size_fact_hist.measurement_type_key=1
  left join size_metric ON size_metric.size_metric_key=size_fact_hist.size_metric_key
	where task_status_fact_hist.row_current_flag=1
	AND project_key IS NOT NULL
    AND plan_item.phase_key > 11
    AND plan_item.phase_key < 21
  ORDER BY project_key, wbs_element_key, plan_item_key, phase_key