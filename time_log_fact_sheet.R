# Extract Time fact sheet
dbGetQuery(con, paste("
   SELECT 'time_log_fact_key',       'project_key',                    'person_key',                       'team_key',
           'wbs_element_key',        'plan_item_key',                  'time_log_start_date',              'time_log_end_date',
           'time_log_delta_minutes', 'time_log_interrupt_minutes',      'phase_key',                       'phase_short_name',
           'phase.process_key',      'process_name',                    'row_current_flag'
   UNION (
   SELECT time_log_fact_key,         project_key,                       person_key,                         team_key,
           wbs_element_key,          time_log_fact_hist.plan_item_key,  time_log_start_date,                time_log_end_date,
           time_log_delta_minutes,   time_log_interrupt_minutes,        plan_item_hist.phase_key,           phase_short_name,
           phase.process_key,         process_name,                     time_log_fact_hist.row_current_flag
    FROM         time_log_fact_hist
      LEFT JOIN  data_block     ON time_log_fact_hist.data_block_key = data_block.data_block_key
      LEFT JOIN  plan_item_hist ON time_log_fact_hist.plan_item_key  = plan_item_hist.plan_item_key
      LEFT JOIN  phase          ON plan_item_hist.phase_key          = phase.phase_key
      LEFT JOIN  process        ON phase.process_key                 = process.process_key
    WHERE   project_key IN (", str_unit, ")
      AND   time_log_fact_hist.row_current_flag  = 1
      AND   plan_item_hist.row_current_flag      = 1
    ORDER BY time_log_fact_key, project_key
    INTO OUTFILE \"",   fnameTime, "\""  , "
    FIELDS TERMINATED BY ','
   )# end union
                    " , sep=""
                      )
           )