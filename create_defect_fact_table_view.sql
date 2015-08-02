create VIEW tsppacedb.defect_fact_table AS  (SELECT   
        defect_log_fact_key,         
		project_key,                        
		person_key,                  
		team_key,
		wbs_element_key,                
		defect_log_fact_hist.plan_item_key, 
		defect_found_date_key, 
		defect_fix_count,            
		defect_fix_time_minutes,
		defect_found_date,             
		defect_type_key,                   
		defect_removed_phase_key,  
		removed_phase.phase_short_name  as removed_phase_name,
        rem_po.phase_ordinal            as removed_phase_ordinal,
        rem_pb.phase_short_name         as removed_base_phase_name,
        rem_pb.phase_ordinal            as removed_base_phase_ordinal,
        removed_phase.phase_type        as removed_phase_type,
		defect_injected_phase_key,   
		injected_phase.phase_short_name as injected_phase_name,  
        inj_po.phase_ordinal            as injected_phase_ordinal,
		inj_pb.phase_short_name         as injected_base_phase_name,
        inj_po.phase_ordinal            as injected_base_phase_ordinal,
        injected_phase.phase_type       as injected_phase_type,
		removed_phase.process_key,
		process_name
FROM    defect_log_fact_hist
	LEFT JOIN data_block              ON defect_log_fact_hist.data_block_key            = data_block.data_block_key
	LEFT JOIN plan_item_hist          ON defect_log_fact_hist.plan_item_key             = plan_item_hist.plan_item_key
	LEFT JOIN phase AS injected_phase ON defect_log_fact_hist.defect_injected_phase_key = injected_phase.phase_key
	LEFT JOIN phase AS removed_phase  ON defect_log_fact_hist.defect_removed_phase_key  = removed_phase.phase_key
    left join phase_mapping as rem_pm on rem_pm.phase_key      = removed_phase.phase_key 
    left join phase_order   as rem_po on rem_po.phase_key      = removed_phase.phase_key 
    left join phase_base    as rem_pb on rem_pb.phase_base_key = rem_pm.phase_base_key
	left join phase_mapping as inj_pm on inj_pm.phase_key      = injected_phase.phase_key 
	left join phase_order   as inj_po on inj_po.phase_key      = removed_phase.phase_key 
    left join phase_base    as inj_pb on inj_pb.phase_base_key = inj_pm.phase_base_key
	LEFT JOIN process                 ON removed_phase.process_key   = process.process_key
	WHERE      defect_log_fact_hist.row_current_flag = 1
		AND    plan_item_hist.row_current_flag     = 1) 
        
