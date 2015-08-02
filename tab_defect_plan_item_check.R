#  list defects-task plan items, missing task indicates data error
dbGetQuery( con,
            paste
            ("
SELECT
     'project_key'
   , 'defect_plan_item_key'
   , 'defects_found'
   , 'defect_effort_minutes'
   ,'task_plan_item'
UNION(
  SELECT
  defects_plan_item_table.project_key
  ,  defects_plan_item_table.plan_item_key as defect_plan_item_key
  ,  defects_found
  ,  defect_effort_minutes
  ,  task_status_fact_hist.plan_item_key  as task_plan_item_key
  FROM defects_plan_item_table
      LEFT JOIN task_status_fact_hist 
             ON task_status_fact_hist.plan_item_key=defects_plan_item_table.plan_item_key
  WHERE time.project_key in (", str_unit, ")
  INTO OUTFILE \"",   fnameDefectCheck, "\""   , "
          FIELDS TERMINATED by ','
     )# end union
          " , sep=""
            ) #end paste
) # end query