// defects_per_task_check.sql 
// append task start, end, and total time to the defect fix totals
SELECT
    'project_key'
  , 'defect_plan_item_key'
  , 'removed_phase_name'
  , 'removed_phase_base_name'
  , 'defects_found'
  , 'defect_effort_minutes'
  , 'task_plan_item'
  , 'task_status_fact.task_actual_start_date'
  , 'task_status_fact.task_actual_complete_date'
  , 'task_actual_time_minutes'
UNION(
  SELECT
     defects_plan_item_table.project_key
  ,  defects_plan_item_table.plan_item_key as defect_plan_item_key
  ,  removed_phase_name
  ,  removed_phase_base_name
  ,  defects_found
  ,  defect_effort_minutes
  ,  task_status_fact.plan_item_key  as task_plan_item_key
  ,  task_status_fact.task_actual_start_date
  ,  task_status_fact.task_actual_complete_date
  ,  task_actual_time_minutes
  FROM defects_plan_item_table
  LEFT JOIN task_status_fact 
         ON task_status_fact.plan_item_key=defects_plan_item_table.plan_item_key
  WHERE time.project_key in (", str_unit, ")
  ORDER BY project_key, defect_plan_item_key
    INTO OUTFILE "c:/SEI/defects_per_task_check.csv"   Fields terminated by ',' 
    )
