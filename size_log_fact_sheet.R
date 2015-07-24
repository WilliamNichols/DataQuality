# Extract size fact sheet
dbGetQuery( con ,
            paste
            (
                "SELECT 'size_fact_key',    'project_key',                       'person_key',              'team_key',
                         'wbs_element_key',  'plan_item_key',                     'size_added_and_modified', 'size_added',
                         'size_base',        'size_deleted',                      'size_modified',           'size_reused',
                         'size_total',       'measurement_type_key',              'measurement_type_name',   'size_metric_key',
                         'size_metric_name', 'size_metric_short_name',            'phase_key',               'phase_short_name',
                         'process_key',      'process_name',                      'row_current_flag'
                  UNION
                  (
                  SELECT  size_fact_key,      project_key,                         person_key,                team_key,
                          wbs_element_key,    size_fact_hist.plan_item_key,        size_added_and_modified,   size_added,
                          size_base,          size_deleted,                        size_modified,             size_reused,
                          size_total,         size_fact_hist.measurement_type_key, measurement_type_name,     size_fact_hist.size_metric_key,
                          size_metric_name,   size_metric_short_name,              plan_item_hist.phase_key,  phase_short_name,
                          phase.process_key,  process_name, size_fact_hist.row_current_flag
                  FROM         size_fact_hist
                    LEFT JOIN  data_block      ON size_fact_hist.data_block_key       = data_block.data_block_key
                    LEFT JOIN  plan_item_hist  ON size_fact_hist.plan_item_key        = plan_item_hist.plan_item_key
                    LEFT JOIN  phase           ON plan_item_hist.phase_key            = phase.phase_key
                    LEFT JOIN  process          ON phase.process_key                   = process.process_key
                    LEFT JOIN  measurement_type ON size_fact_hist.measurement_type_key = measurement_type.measurement_type_key
                    LEFT JOIN  size_metric      ON size_fact_hist.size_metric_key      = size_metric.size_metric_key
                    WHERE    project_key IN (", str_unit, ")
                      AND    size_fact_hist.row_current_flag = 1
                      AND    plan_item_hist.row_current_flag = 1
                  ORDER BY  size_fact_key, project_key
          INTO OUTFILE \"",   fnameSize, "\""   , "
          FIELDS TERMINATED by ','
                  ) # end UNION
           " , sep=""
            ) # end paste
           )