tab_defect_fix_time_info<-dbGetQuery(con, paste("
  SELECT project_key,
         phase_base.phase_base_key,
         phase_base.phase_short_name,
         Sum(defect_fix_time_minutes) AS sum_defect_fix_time
  FROM   defect_log_fact_hist
      LEFT JOIN plan_item
             ON   defect_log_fact_hist.plan_item_key = plan_item.plan_item_key
      LEFT JOIN phase
             ON   plan_item.phase_key = phase.phase_key
      LEFT JOIN phase_mapping
             ON   phase.phase_key = phase_mapping.phase_key
      LEFT JOIN phase_base
             ON   phase_mapping.phase_base_key = phase_base.phase_base_key
          WHERE   defect_log_fact_hist.row_current_flag = 1
            AND   plan_item.plan_item_deleted_flag      = 0
            AND   project_key IN ( ", str_unit," )
  GROUP  BY project_key,
          phase_base.phase_base_key
                                      "  , seq=""))