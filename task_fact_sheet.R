# Extract task fact sheet
 dbGetQuery(con,
            paste
             ("
              SELECT  
			          'project_key',                   
					  'person_key',
                      'team_key',                      
					  'wbs_element_key',               
					  'plan_item_key',
                      'task_actual_start_date',        
					  'task_actual_complete_date',     
					  'task_actual_time_minutes',
                      'task_plan_time_minutes',            
					  'phase_key',                     
					  'phase_short_name',
                      'process_key',                   
					  'process_name'
               UNION
               (
                SELECT              
				       project_key,                     
					   person_key,
                       team_key,                         
					   wbs_element_key,                 
					   task_status_fact_hist.plan_item_key AS plan_item_key,
                       task_actual_start_date,           
					   task_actual_complete_date,       
					   task_actual_time_minutes,
                       task_plan_time_minutes,            
					   plan_item.phase_key,             
					   phase_short_name,
                       phase.process_key AS process_key, 
					   process_name
                FROM        
				            task_status_fact_hist
                  LEFT JOIN plan_item  ON task_status_fact_hist.plan_item_key     = plan_item.plan_item_key
                  LEFT JOIN data_block ON task_status_fact_hist.data_block_key    = data_block.data_block_key
                  LEFT JOIN phase      ON plan_item.phase_key                     = phase.phase_key
                  LEFT JOIN process    ON  phase.process_key                      = process.process_key
                  WHERE   
                        task_status_fact_hist.row_current_flag = 1
                    AND plan_item.plan_item_deleted_flag       = 0
                    AND project_key IN (", str_unit, ")
                ORDER BY task_status_fact_key
                INTO OUTFILE \"",   fnameTask, "\""  , "
                FIELDS TERMINATED by ','
               )   # end union
               " , sep=""
             ) # end paste
            )  #end query
