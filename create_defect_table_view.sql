create VIEW tsppacedb.defect_table AS  
(SELECT   
        defect_log_fact_key,         
		project_key,  
        team_key,
		person_key,                  
		wbs_element_key,               
		defect_log_fact_hist.plan_item_key, 
		defect_fix_count,            
		defect_fix_time_minutes,
		defect_found_date,             
		defect_type_key,                   
		defect_removed_phase_key,    
		removed_phase.phase_short_name as removed_phase,
        removed_phase.phase_type as     removed_phase_type,
		defect_injected_phase_key,   
		injected_phase.phase_short_name as injected_phase,   
        injected_phase.phase_type  as injected_phase_type,
		defect_found_date_key,       
		removed_phase.process_key,
		process_name
FROM    defect_log_fact_hist
	LEFT JOIN data_block              ON defect_log_fact_hist.data_block_key            = data_block.data_block_key
	LEFT JOIN plan_item_hist          ON defect_log_fact_hist.plan_item_key             = plan_item_hist.plan_item_key
	LEFT JOIN phase AS injected_phase ON defect_log_fact_hist.defect_injected_phase_key = injected_phase.phase_key
	LEFT JOIN phase AS removed_phase  ON defect_log_fact_hist.defect_removed_phase_key  = removed_phase.phase_key
	LEFT JOIN process                 ON removed_phase.process_key                      = process.process_key
    WHERE      defect_log_fact_hist.row_current_flag = 1
		AND    plan_item_hist.row_current_flag     = 1)
        
               
