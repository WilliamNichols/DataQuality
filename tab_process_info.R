tab_process_info<-dbGetQuery(con, paste("
SELECT DISTINCT project_key,
                phase.process_key,
                Quote(process_name) AS process_name
  FROM   plan_item_hist
      LEFT JOIN  phase
              ON plan_item_hist.phase_key = phase.phase_key
      LEFT JOIN  process
              ON phase.process_key = process.process_key
           WHERE phase.process_key IS NOT NULL
             AND project_key IN ( ", str_unit," )