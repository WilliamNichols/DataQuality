create VIEW tsppacedb.defects_plan_item_table AS (
SELECT     project_key
		,  wbs_element_key
        ,  defect_fact_table.plan_item_key
        ,  Sum(defect_fix_count)         AS defects_found
        ,  sum(defect_fix_time_minutes)  as defect_effort_minutes
        ,  defect_removed_phase_key      as removed_phase_key
        ,  removed_phase_name            as removed_phase_name
		,  removed_base_phase_name       as removed_phase_base_name
        ,  removed_phase_type            as phase_type
        ,  size_metric.size_metric_short_name
        ,  size_added_and_modified
FROM     defect_fact_table
   left join size_fact_hist 
          ON  size_fact_hist.plan_item_key   = defect_fact_table.plan_item_key
          AND size_fact_hist.measurement_type_key = 1
          AND size_fact_hist.row_current_flag = 1
   left join size_metric ON size_metric.size_metric_key = size_fact_hist.size_metric_key
GROUP BY plan_item_key
)