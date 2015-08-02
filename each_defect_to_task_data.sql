SELECT
    'project_key'
  , 'plan_item_key'
  , 'defect_fix_count'
  , 'defect_fix_time'
  , 'task_plan_item'
  , 'task_status_fact.task_actual_start_date'
  , 'task_status_fact.task_actual_complete_date'
  , 'task_actual_time_minutes'
UNION(
  SELECT
     defect_fact_table.project_key
  ,  defect_fact_table.plan_item_key as defect_plan_item_key
  ,  defect_fix_count
  ,  defect_fix_time_minutes
  ,  task_status_fact.plan_item_key  as task_plan_item_key
  ,  task_status_fact.task_actual_start_date
  ,  task_status_fact.task_actual_complete_date
  ,  task_actual_time_minutes
  FROM defect_fact_table
  LEFT JOIN task_status_fact 
         ON task_status_fact.plan_item_key=defect_fact_table.plan_item_key
  WHERE defect_fact_table.project_key = 279
  ORDER BY project_key, defect_log_fact_key
    INTO OUTFILE "c:/SEI/each_defect_task_check.csv"   Fields terminated by ',' 
    )