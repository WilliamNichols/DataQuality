# 
# table
# defect_plan_item, defects_found, task_plan_item
# by counging the length nulls in task_plan_item, we can count defect phases without time allocated
tab_defect_task_plan_items<-dbGetQuery(con, 
                              paste("
select  distinct
   defects_plan_item_table.plan_item_key as defect_plan_item_key
  , defects_found
  , task_status_fact_hist.plan_item_key  as task_plan_item_key
   from defects_plan_item_table
   left join task_status_fact_hist 
          ON task_status_fact_hist.plan_item_key=defects_plan_item_table.plan_item_key
   where project_key = in (", str_unit, ")
   
" , sep=""
          ) #end paste
 )