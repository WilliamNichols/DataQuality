select  process_name
      ,  plan_item.project_key
	  ,  plan_item.wbs_element_key
	  ,  plan_item.task_key
      ,  task_status_fact_key
      ,  plan_item.phase_key
      ,  phase_name
      ,  plan_item.plan_item_key
      ,  plan_item.phase_key
      ,  task_status_fact_hist.task_actual_complete_date
      ,  task_plan_time_minutes
      ,  task_status_fact_hist.task_actual_time_minutes
  from task_status_fact_hist
  left join plan_item    ON task_status_fact_hist.plan_item_key=plan_item.plan_item_key
        and                 plan_item_deleted_flag=0
  left join phase ON phase.phase_key=plan_item.phase_key
  left join process ON process.process_key = phase.process_key
	where task_status_fact_hist.row_current_flag=1
	AND project_key IS NOT NULL
  ORDER BY project_key, wbs_element_key, plan_item_key, phase_key