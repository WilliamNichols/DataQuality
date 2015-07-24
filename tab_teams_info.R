tab_teams_info<-dbGetQuery(con, paste("
SELECT DISTINCT project_key,
                data_block.team_key,
                Quote(team_name) AS team_name,
                person_key
FROM            task_status_fact_hist
  LEFT JOIN    plan_item_hist
         ON    task_status_fact_hist.plan_item_key = plan_item_hist.plan_item_key
  LEFT JOIN  data_block
         ON    task_status_fact_hist.data_block_key = data_block.data_block_key
  LEFT JOIN  team
         ON     data_block.team_key = team.team_key
      WHERE     project_key IN (", str_unit, ")
        AND     task_status_fact_hist.row_current_flag  = 1
        AND     plan_item_hist.row_current_flag         = 1
		                                             ", seq=""))