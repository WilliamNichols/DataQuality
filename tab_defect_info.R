tab_defect_info<-dbGetQuery(con, paste("
  SELECT distinct defect_log_fact_key, 
                  defect_fix_count, 
                  defect_fix_time_minutes, 
                  defect_fix_defect_identifier, 
                  defect_found_date, 
                  defect_type_key, 
                  defect_removed_phase_key, 
                  removed_phase.phase_short_name AS defect_removed_phase_short_name, 
                  defect_injected_phase_key, 
                  injected_phase.phase_short_name AS defect_injected_phase_short_name, 
                  team_key, 
                  person_key, 
                  wbs_element_key, 
                  project_key, 
                  defect_log_fact_hist.data_block_key, 
                  defect_log_fact_hist.plan_item_key 
 FROM       defect_log_fact_hist 
 LEFT JOIN  plan_item               ON defect_log_fact_hist.plan_item_key             = plan_item.plan_item_key 
 LEFT JOIN  data_block              ON defect_log_fact_hist.data_block_key            = data_block.data_block_key 
 LEFT JOIN  phase AS removed_phase  ON defect_log_fact_hist.defect_removed_phase_key  = removed_phase.phase_key 
 LEFT JOIN  phase AS injected_phase ON defect_log_fact_hist.defect_injected_phase_key = injected_phase.phase_key 
 WHERE      project_key in (", str_unit, ")
#  AND      defect_log_fact_hist.row_current_flag = 1
", seq=""))
#