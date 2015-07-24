tab_defect_removed_info<-dbGetQuery(con, paste("
  SELECT project_key,
         Sum(defect_fix_count)       AS sum_defect_fix_count,
         Count(defect_log_fact_key)  AS sum_defect_records,
         phase_base.phase_short_name AS defect_removed_phase_name
  FROM   defect_log_fact_hist
     LEFT JOIN plan_item_hist
            ON   defect_log_fact_hist.plan_item_key =
                 plan_item_hist.plan_item_key
     LEFT JOIN phase
            ON   defect_log_fact_hist.defect_removed_phase_key = phase.phase_key
     LEFT JOIN phase_mapping
            ON   phase.phase_key = phase_mapping.phase_key
     LEFT JOIN phase_base
            ON   phase_mapping.phase_base_key = phase_base.phase_base_key
         WHERE  defect_log_fact_hist.row_current_flag = 1
           AND  plan_item_hist.row_current_flag       = 1
           AND  project_key IN ( ", str_unit," )
  GROUP  BY project_key,
          phase_base.phase_base_key
                                            ", seq=""))