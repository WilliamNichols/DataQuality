tab_time_def_info<-dbGetQuery(con, 
                              paste("
 SELECT time.plan_item_key,
        time.project_key,
        time.phase_short_name,
        ifnull(time.time_log_min,'0')  AS time_start_date,
        ifnull(time.time_log_max,'0')  AS time_end_date,
        ifnull(defect.def_log_min,'0') AS def_fix_start_date,
        ifnull(defect.def_log_max,'0') AS def_fix_end_date, 
        time_sum, 
        def_fix_time_sum 
 FROM   (
          (select time_log_fact_hist.plan_item_key,
                  plan_item.project_key,
                  phase_short_name,
                  min(time_log_start_date)    AS time_log_min,
                  max(time_log_end_date)      AS time_log_max,
                  sum(time_log_delta_minutes) AS time_sum 
           FROM      time_log_fact_hist 
           left join plan_item ON plan_item.plan_item_key = time_log_fact_hist.plan_item_key 
           left join phase     ON plan_item.phase_key     = phase.phase_key 
           left join project   ON plan_item.project_key   = project.project_key group BY time_log_fact_hist.plan_item_key) AS time 
           left join (select defect_log_fact_hist.plan_item_key,plan_item.project_key,
                             phase_short_name,min(defect_found_date) AS def_log_min,
                             max(defect_found_date)                  AS def_log_max, 
                             sum(defect_fix_time_minutes)            AS def_fix_time_sum from defect_log_fact_hist 
                      left join plan_item ON plan_item.plan_item_key = defect_log_fact_hist.plan_item_key 
                      left join phase     ON plan_item.phase_key     = phase.phase_key 
                      left join project   ON plan_item.project_key   = project.project_key 
                      GROUP BY defect_log_fact_hist.plan_item_key
                    )   AS defect on time.plan_item_key = defect.plan_item_key
        ) 
                    WHERE time.project_key in (", str_unit, ")
", seq=""))
