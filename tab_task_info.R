tab_task_info<-dbGetQuery(con, paste("
SELECT distinct task_status_fact_key, 
                task_actual_start_date, 
				task_actual_complete_date, 
				task_actual_time_minutes, 
				task_plan_time_minutes, 
				task_actual_start_date_key, 
				task_actual_complete_date_key, 
				team_key, 
				person_key, 
				wbs_element_key, 
				project_key, 
				task_status_fact_hist.data_block_key, 
				task_status_fact_hist.plan_item_key 
	   FROM 	task_status_fact_hist 
	      LEFT JOIN plan_item  ON task_status_fact_hist.plan_item_key  = plan_item.plan_item_key 
		  LEFT JOIN data_block ON task_status_fact_hist.data_block_key = data_block.data_block_key 
	   WHERE   project_key IN (", str_unit, ")
	     AND   plan_item.plan_item_deleted_flag = 0
		                                            " , seq=""))
