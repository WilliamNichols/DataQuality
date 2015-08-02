/* for completed tasks 
//project, 
 //       wbs_element, 
 //                    task_key,
 //                             phase, 
 //                                   phase_type,  
 //                                   plan/actual time, 
//									actual-date, 
//									defects_found  
*/

SELECT DISTINCT project_key,                              
                phase_base.phase_base_key,                
                phase_base.phase_short_name,
                phase_type,
                wbs_element_key,
                task_status_fact_hist.task_status_fact_key as task_key,
                task_status_fact_hist.task_actual_time_minutes,
                task_status_fact_hist.task_plan_time_minutes,
                task_status_fact_hist.task_actual_complete_date_key,
                defects_found                             
FROM     task_status_fact_hist
    LEFT JOIN    plan_item_hist
          ON        task_status_fact_hist.plan_item_key = plan_item_hist.plan_item_key 
          and       plan_item_hist.row_current_flag = 1
   LEFT JOIN    phase
          ON        plan_item_hist.phase_key = phase.phase_key
   LEFT JOIN   phase_mapping
          ON        phase.phase_key = phase_mapping.phase_key
   LEFT JOIN   phase_base                                                         
          ON        phase_mapping.phase_base_key = phase_base.phase_base_key
   LEFT JOIN
                ( SELECT   Sum(defect_fix_count) AS defects_found,
                           plan_item_key
                  FROM     defect_log_fact_hist
                  GROUP BY plan_item_key ) 
                  AS defect_table
           ON    defect_table.plan_item_key = task_status_fact_hist.plan_item_key
WHERE         task_status_fact_hist.row_current_flag = 1  
  AND         plan_item_hist.row_current_flag        = 1  
  AND         project_key = 279                          
  AND         task_status_fact_hist.row_current_flag = 1