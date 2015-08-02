tab_each_defect_per_task_check_info<-dbGetQuery(con, 
                              paste("
  SELECT
     defect_fact_table.project_key
  ,  defect_fact_table.plan_item_key as defect_plan_item_key
  ,  defect_fix_count
  ,  defect_fix_time_minutes
  ,  task_status_fact.plan_item_key  as task_plan_item_key
  ,  task_status_fact.task_actual_start_date
  ,  task_status_fact.task_actual_complete_date
  ,  task_actual_time_minutes
  ,  IF( ( task_status_fact.plan_item_key IS NULL), 'fail', 'pass') AS defect_in_null_task_check
  FROM defect_fact_table
  LEFT JOIN task_status_fact 
         ON task_status_fact.plan_item_key=defect_fact_table.plan_item_key
  WHERE defect_fact_table.project_key IN (", str_unit ,")
  ORDER BY defect_in_null_task_check, project_key, defect_log_fact_key
", seq="")
)
#


dbGetQuery(con, 
           paste("
 SELECT
    'project_key'
  , 'plan_item_key'
  , 'defect_fix_count'
  , 'defect_fix_time'
  , 'task_plan_item'
  , 'task_status_fact.task_actual_start_date'
  , 'task_status_fact.task_actual_complete_date'
  , 'task_actual_time_minutes'
  , 'defect_in_null_task_check'
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
  ,  IF( ( task_status_fact.plan_item_key IS NULL), 'fail', 'pass') AS defect_in_null_task_check
  FROM defect_fact_table
  LEFT JOIN task_status_fact 
         ON task_status_fact.plan_item_key=defect_fact_table.plan_item_key
  WHERE defect_fact_table.project_key IN (", str_unit, ")
  ORDER BY defect_in_null_task_check, project_key, defect_log_fact_key
    INTO OUTFILE 'c:/SEI/defect_to_task_check.csv'   Fields terminated by ',' 
    )
", seq="")
)
#