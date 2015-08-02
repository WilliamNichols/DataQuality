# 
tab_defects_per_task_check_info<-dbGetQuery(con, 
                              paste("
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
 ,  IF( (task_status_fact.task_actual_time_minutes IS NULL)  ,      
         (0-defect_effort_minutes) , 
         IF( (task_status_fact.task_actual_time_minutes > defect_effort_minutes),   
              0,
              (defect_effort_minutes - task_status_fact.task_actual_time_minutes)
       )   ) AS missing_test_time
 , IF( task_status_fact.task_actual_time_minutes IS  NULL, 'fail' , 
       IF( (defect_effort_minutes-task_status_fact.task_actual_time_minutes) >0 , 'fail', 'pass')
     ) AS fix_exceeds_task_check
 , IF( (task_status_fact.task_actual_time_minutes IS NOT NULL), 
       'pass', 'fail' ) AS null_task_check
  FROM defects_plan_item_table
  LEFT JOIN task_status_fact 
         ON task_status_fact.plan_item_key=defects_plan_item_table.plan_item_key
  WHERE defects_plan_item_table.project_key in (", str_unit, ")
", seq="")
                              )
# output to a file for later  examination
dbGetQuery(con, 
           paste("
SELECT
    'project_key'
  , 'defect_plan_item_key'
                 , 'removed_phase_name'
                 , 'removed_phase_base_name'
                 , 'defects_found'
                 , 'defect_effort_minutes'
                 , 'task_plan_item'
                 , 'task_actual_start_date'
                 , 'task_actual_complete_date'
                 , 'task_actual_time_minutes'
                 , 'missing_time'
                 , 'fix_effort_check'
                 , 'null_task_check'
 UNION(
 SELECT
 defects_plan_item_table.project_key   as project_key
 ,  defects_plan_item_table.plan_item_key as defect_plan_item_key
 ,  removed_phase_name
 ,  removed_phase_base_name
 ,  defects_found
 ,  defect_effort_minutes
 ,  task_status_fact.plan_item_key  as task_plan_item_key
 ,  task_status_fact.task_actual_start_date
 ,  task_status_fact.task_actual_complete_date
 ,  task_status_fact.task_actual_time_minutes
 ,  IF( (task_status_fact.task_actual_time_minutes IS NULL)  ,      
         (0-defect_effort_minutes) , 
         IF( (task_status_fact.task_actual_time_minutes > defect_effort_minutes),   
              0,
              (defect_effort_minutes - task_status_fact.task_actual_time_minutes)
       )   ) AS missing_test_time
 , IF( task_status_fact.task_actual_time_minutes IS  NULL, 'fail' , 
       IF( (defect_effort_minutes-task_status_fact.task_actual_time_minutes) >0 , 'fail', 'pass')
     ) AS fix_exceeds_task_check
 , IF( (task_status_fact.task_actual_time_minutes IS NOT NULL), 
       'pass', 'fail' ) AS null_task_check
 FROM defects_plan_item_table
 LEFT JOIN task_status_fact 
 ON task_status_fact.plan_item_key=defects_plan_item_table.plan_item_key
 WHERE defects_plan_item_table.project_key IN (", str_unit, ") 
 ORDER BY  null_task_check, fix_exceeds_task_check, project_key, defect_plan_item_key, missing_test_time
 INTO OUTFILE 'c:/SEI/defects_per_task_check.csv'   Fields terminated by ','
                 ) ", seq="") 
) # end query
# 
# 
