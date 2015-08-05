#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Extract the project fact sheet and project process fidelity sheet
# 2014/7/17
# Yasutaka Shirai
# Update: 2015/2/21
# Add the function to select projects for extracting fact sheet
# Yasutaka Shirai
#
# wrn: this version includes use of project profile

extractProjectFact <- function(con, currentDirectory)
{
#
# Get project data from SEMPR
#
tab_project_info<-dbGetQuery(con, "
  SELECT project_key,
         Quote(project_name) AS project_name
  FROM   project
                                  ")

# Check the existence of the text file for project selection
if (file.access("select_projects.txt") != 0) {
  unit <- unique(tab_project_info$project_key)
} else {
  # Read project selection from text file
  pj_selection <- read.table("select_projects.txt", header=T, comment.char="#")
  if (length(pj_selection$project_key) == 0) {
    unit <- unique(tab_project_info$project_key)
  } else {
    unit <- unique(pj_selection$project_key)
  }
}

str_unit <- paste(unit,collapse=",")

# Get necessary data records from SEMPR

# "project_key"        "project_name"       "parent_project_key" "project_pattern"
tab_project_info<-dbGetQuery(con, paste("
  SELECT    project.project_key,
            Quote(project_name) AS project_name,
            parent_project_key,
            project_pattern
  FROM      project
  LEFT JOIN project_layer
  ON        project.project_key = project_layer.project_key
  WHERE     project.project_key IN (", str_unit ,")
                                        ", seq=""))
#"project_key"       "organization_key"  "organization_name"
tab_organization_info<-dbGetQuery(con, paste("
SELECT    project_key,
          org_mapping.organization_key,
          Quote(organization_name) AS organization_name
FROM      organization
LEFT JOIN org_mapping
ON        organization.organization_key = org_mapping.organization_key
WHERE     project_key IN (", str_unit, ")
                                             ", seq=""))

#"project_key"  "process_key"  "process_name"
tab_process_info<-dbGetQuery(con, paste("
SELECT DISTINCT project_key,
                phase.process_key,
                Quote(process_name) AS process_name
FROM   plan_item_hist
       LEFT JOIN phase
              ON plan_item_hist.phase_key = phase.phase_key
       LEFT JOIN process
              ON phase.process_key = process.process_key
WHERE  phase.process_key IS NOT NULL
       AND project_key IN ( ", str_unit," )
                                         ", seq=""))

#
# "project_key" "team_key"    "team_name"   "person_key" 
tab_teams_info<-dbGetQuery(con, paste("
SELECT DISTINCT project_key,
                data_block.team_key,
                Quote(team_name) AS team_name,
                person_key
FROM         task_status_fact_hist
  LEFT JOIN  plan_item_hist
         ON    task_status_fact_hist.plan_item_key = plan_item_hist.plan_item_key
  LEFT JOIN  data_block
         ON    task_status_fact_hist.data_block_key = data_block.data_block_key
  LEFT JOIN  team
         ON     data_block.team_key = team.team_key
WHERE      project_key IN (", str_unit, ")
  AND      task_status_fact_hist.row_current_flag  = 1
  AND      plan_item_hist.row_current_flag         = 1

                                             ", seq=""))

# "start_date"   "start_week"   "end_date"     "end_week"     "actual_weeks" "project_key"
tab_duration_info<-dbGetQuery(con, paste("
SELECT Min(time_log_start_date)                          AS start_date,
       Date_format(Min(time_log_start_date), '%Y%u')     AS start_week,
       Max(time_log_end_date)                            AS end_date,
       Date_format(Max(time_log_start_date), '%Y%u')     AS end_week,
       ( Date_format(Max(time_log_start_date), '%Y%u') -
         Date_format(Min(time_log_start_date), '%Y%u') ) AS duration_weeks,
       ( Date_format(Max(time_log_start_date), '%Y%j') -
         Date_format(Min(time_log_start_date), '%Y%j') ) AS duration_days,
       project_key
FROM   time_log_fact_hist
       JOIN plan_item_hist
         ON time_log_fact_hist.plan_item_key = plan_item_hist.plan_item_key
WHERE  time_log_fact_key != 23000
       AND time_log_fact_hist.row_current_flag = 1
       AND plan_item_hist.row_current_flag     = 1
       AND project_key IN ( ", str_unit," )
GROUP  BY project_key
                                      " , seq=""))

#  task data
# "project_key"      "phase_short_name" "phase_base_key"   "phase_ordinal"    
# "task_begin_date"  "task_end_date"   "sum_actual_time"  "sum_plan_time"    "phase_type"
tab_time_info<-dbGetQuery(con, paste("
SELECT   project_key,
         phase_base.phase_short_name,
         phase_base.phase_base_key,
         phase_base.phase_ordinal,
         Min(task_actual_start_date_key)    AS task_begin_date,
         Max(task_actual_complete_date_key) AS task_end_date,
         Sum(task_actual_time_minutes)      AS sum_actual_time,
         Sum(task_plan_time_minutes)        AS sum_plan_time,
         phase_type
FROM     task_status_fact_hist
  LEFT JOIN plan_item_hist
    ON        task_status_fact_hist.plan_item_key = plan_item_hist.plan_item_key
  LEFT JOIN phase
    ON        plan_item_hist.phase_key = phase.phase_key
  LEFT JOIN phase_mapping
    ON        phase.phase_key = phase_mapping.phase_key
  LEFT JOIN phase_base
    ON        phase_mapping.phase_base_key = phase_base.phase_base_key
WHERE     phase_base.phase_base_key IS NOT NULL
  AND     plan_item_hist.row_current_flag        = 1
  AND     task_status_fact_hist.row_current_flag = 1
  AND     project_key IN (", str_unit, ")
GROUP BY  project_key,
          phase_short_name
ORDER BY  project_key,
          phase_base.phase_ordinal,
          phase_base.phase_base_key
                                     " , seq=""))


# time log data
#"time_log_fact_key"      "project_key"            "time_log_delta_minutes" "time_log_start_date"   
#"time_log_end_date"      "start_day"              "end_day"                "phase_base_key"        
# "phase_short_name"    
tab_time_log_info<-dbGetQuery(con, paste("
  SELECT time_log_fact_key,
         project_key,
         time_log_delta_minutes,
         time_log_start_date,
         time_log_end_date,
         Date_format(time_log_start_date, '%Y-%m-%d') AS start_day,
         Date_format(time_log_end_date, '%Y-%m-%d')   AS end_day,
         phase_base.phase_base_key,
         phase_base.phase_short_name
  FROM   time_log_fact_hist
         LEFT JOIN plan_item_hist
              ON time_log_fact_hist.plan_item_key = plan_item_hist.plan_item_key
         LEFT JOIN phase
              ON plan_item_hist.phase_key = phase.phase_key
         LEFT JOIN phase_mapping
              ON phase.phase_key = phase_mapping.phase_key
         LEFT JOIN phase_base
              ON phase_mapping.phase_base_key = phase_base.phase_base_key
  WHERE  plan_item_hist.row_current_flag     = 1
     AND time_log_fact_hist.row_current_flag = 1
     AND time_log_start_date > '1900-01-01 00:00:00'
     AND time_log_end_date > '1900-01-01 00:00:00'
     AND project_key IN ( ", str_unit," )
                                           " , seq=""))


# task information
#    get up to 4 rows for each task
#        plan, replan, forecast, actual 
# from task_date_fact_history, join to plan_item_history
#
#
# "task_date_fact_key"   "project_key"          "task_date_key"        
# "task_completion_date" "measurement_type_key"
# "phase_short_name"     "wbs_element_key" "plan_item_key"
#
tab_task_completion_info<-dbGetQuery(con, paste("
SELECT    task_date_fact_key
         , project_key
         , task_date_key
         , Date_format(task_date_key, '%Y-%m-%d') AS task_completion_date
         , measurement_type_key
         , phase_base.phase_short_name
         , plan_item_hist.plan_item_key
         , wbs_element_key
FROM       task_date_fact_hist
  LEFT JOIN  plan_item_hist
         ON     task_date_fact_hist.plan_item_key = plan_item_hist.plan_item_key
  LEFT JOIN phase
         ON     plan_item_hist.phase_key = phase.phase_key
  LEFT JOIN phase_mapping
         ON     phase.phase_key = phase_mapping.phase_key
  LEFT JOIN phase_base
         ON     phase_mapping.phase_base_key = phase_base.phase_base_key
WHERE       task_date_fact_hist.row_current_flag = 1
  AND       plan_item_hist.row_current_flag      = 1
  AND       project_key IN (", str_unit, ")
ORDER BY    project_key, wbs_element_key, plan_item_key, measurement_type_key
                                        " , seq=""))
                                           
#  from the task_status_fact_history table, join to plan item, phase, and phase mapping
#  summarizes plan and actual data for a task
# "project_key"                   "phase_base_key"                "wbs_element_key"              
# "phase_short_name"              "phase_type"                    "task_key"                     
# "task_actual_time_minutes"      "task_plan_time_minutes"        "task_actual_complete_date_key"
# "defects_found"  
#
#remove defects or fix, the join to plan_item is causing duplicatoin
tab_task_info<-dbGetQuery(con, paste(" # getting the wrong number of defects, because of key on plan_item, defects map to plan item, not task? 
SELECT DISTINCT project_key,
                phase_base.phase_base_key,
                wbs_element_key,
                task_status_fact_hist.plan_item_key, 
                task_status_fact_hist.task_status_fact_key AS task_key,
                phase_base.phase_short_name,
                phase_type,
                task_status_fact_hist.task_actual_time_minutes,
                task_status_fact_hist.task_plan_time_minutes,
                task_status_fact_hist.task_actual_start_date_key,
                task_status_fact_hist.task_actual_complete_date_key,
                task_status_fact_hist.task_actual_start_date,
                task_status_fact_hist.task_actual_complete_date,
                defects_found
FROM            task_status_fact_hist
   LEFT JOIN    plan_item_hist
          ON        task_status_fact_hist.plan_item_key = plan_item_hist.plan_item_key
   LEFT JOIN    phase
          ON        plan_item_hist.phase_key = phase.phase_key
   LEFT JOIN   phase_mapping
          ON        phase.phase_key = phase_mapping.phase_key
   LEFT JOIN    phase_base
          ON        phase_mapping.phase_base_key = phase_base.phase_base_key
   LEFT JOIN
                (SELECT   Sum(defect_fix_count) AS defects_found,
                          plan_item_key
                  FROM     defect_log_fact_hist
                  GROUP BY plan_item_key) AS defect_table
           ON    defect_table.plan_item_key = task_status_fact_hist.plan_item_key
WHERE         task_status_fact_hist.row_current_flag = 1
  AND         plan_item_hist.row_current_flag        = 1
  AND         project_key IN (", str_unit, ")
                                             " , seq=""))


### WRN, this is not correctly named, 
### not very relevant at this time
### SPI is not useful after completion
#
# project_key, sum_plan_minutes
tab_bcws_info<-dbGetQuery(con, paste("
  SELECT project_key,
         Sum(s.task_plan_time_minutes) AS sum_plan_minutes
  FROM   task_status_fact s,
         task_date_fact   d,
         measurement_type t,
         plan_item_hist   h
  WHERE  s.plan_item_key             = d.plan_item_key

    AND  s.data_block_key        = d.data_block_key
    AND  d.measurement_type_key  = t.measurement_type_key
    AND  t.measurement_type_name = 'Plan'
    AND  d.task_date_key        <= 29991231
    AND  s.plan_item_key         = h.plan_item_key
    AND  s.row_current_flag      = 1
    AND  h.row_current_flag      = 1
    AND  d.row_current_flag      = 1
    AND  project_key IN ( ", str_unit," )
  GROUP  BY project_key
                                             ", seq=""))

# multiple rows for each project for each combination of measurement_type_key and size_metric_name
# 
#"project_key"          "measurement_type_key" "size_metric_name"     "sum_size_am"          "sum_size_added"      
# "sum_size_base"        "sum_size_deleted"     "sum_size_modified"    "sum_size_reused"      "sum_size_total" 
tab_size_info<-dbGetQuery(con, paste("
  SELECT project_key,
         measurement_type_key,
         size_metric_name,
         Sum(size_added_and_modified) AS sum_size_am,
         Sum(size_added)              AS sum_size_added,
         Sum(size_base)               AS sum_size_base,
         Sum(size_deleted)            AS sum_size_deleted,
         Sum(size_modified)           AS sum_size_modified,
         Sum(size_reused)             AS sum_size_reused,
         Sum(size_total)              AS sum_size_total
  FROM   size_fact_hist
    JOIN plan_item_hist
      ON   size_fact_hist.plan_item_key = plan_item_hist.plan_item_key
    JOIN size_metric
     ON    size_fact_hist.size_metric_key = size_metric.size_metric_key
WHERE  size_fact_hist.row_current_flag = 1
 AND   plan_item_hist.row_current_flag = 1
       AND project_key IN ( ", str_unit," )
GROUP  BY project_key,
          measurement_type_key,
          size_fact_hist.size_metric_key
                                     ", seq=""))
#
# defects injected per phase in the project, uses phase_base
#
# "project_key"                "sum_defect_fix_count"       "sum_defect_records"         
#" defect_injected_phase_name" "phase_ordinal"              "phase_type"
#
tab_defect_injected_info<-dbGetQuery(con, paste("
SELECT project_key
      , Sum(defect_fix_count)       AS sum_defect_fix_count
      , Count(defect_log_fact_key)  AS sum_defect_records
      , phase_base.phase_short_name AS defect_injected_phase_name
      , phase_base.phase_ordinal    AS phase_ordinal
      , phase_type
  FROM         defect_log_fact_hist
     LEFT JOIN plan_item_hist
            ON   defect_log_fact_hist.plan_item_key =  plan_item_hist.plan_item_key
    LEFT JOIN phase
           ON   defect_log_fact_hist.defect_injected_phase_key =  phase.phase_key
    LEFT JOIN phase_mapping
           ON   phase.phase_key = phase_mapping.phase_key
    LEFT JOIN phase_base
           ON   phase_mapping.phase_base_key = phase_base.phase_base_key
        WHERE   defect_log_fact_hist.row_current_flag = 1
          AND   plan_item_hist.row_current_flag       = 1
          AND   project_key IN ( ", str_unit," )
  GROUP  BY project_key,
          phase_base.phase_base_key
  ORDER BY project_key, phase_ordinal
                                        " , seq=""))


# "project_key"               "sum_defect_fix_count"      "sum_defect_records"       
#"defect_removed_phase_name"  "phase_ordinal"             "phase_type"
tab_defect_removed_info<-dbGetQuery(con, paste("
  SELECT project_key
         , Sum(defect_fix_count)       AS sum_defect_fix_count
         , Count(defect_log_fact_key)  AS sum_defect_records
         , phase_base.phase_short_name AS defect_removed_phase_name
         , phase_base.phase_ordinal    AS phase_ordinal
         , phase_type
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
  ORDER  BY project_key, phase_ordinal
                                            ", seq=""))

#   "project_key"         "phase_base_key"      "phase_short_name"    "phase_ordinal"       
#   "sum_defect_fix_time"
tab_defect_fix_time_info<-dbGetQuery(con, paste("
  SELECT project_key
         , phase_base.phase_base_key
         , phase_base.phase_short_name
         , phase_base.phase_ordinal
         , phase_type
         , Sum(defect_fix_time_minutes) AS sum_defect_fix_time
  FROM   defect_log_fact_hist
      LEFT JOIN plan_item_hist
             ON   defect_log_fact_hist.plan_item_key = plan_item_hist.plan_item_key
      LEFT JOIN phase
             ON   plan_item_hist.phase_key = phase.phase_key
      LEFT JOIN phase_mapping
             ON   phase.phase_key = phase_mapping.phase_key
      LEFT JOIN phase_base
             ON   phase_mapping.phase_base_key = phase_base.phase_base_key
          WHERE   defect_log_fact_hist.row_current_flag = 1
            AND   plan_item_hist.row_current_flag       = 1
            AND   project_key IN ( ", str_unit," )
  GROUP  BY project_key,
          phase_base.phase_base_key
  ORDER BY project_key, phase_ordinal
                                      "  , seq=""))
# use the task data
# This is plan and actual effort by phase
#"project_key"      "phase_short_name" "phase_base_key"   "phase_ordinal"    "task_begin_date"  "task_end_date"   
#"sum_actual_time"  "sum_plan_time"    "phase_type"      
tab_phase_time_info<-dbGetQuery(con, paste("
  SELECT   project_key
         , phase_base.phase_base_key
         , phase_base.phase_short_name
         , phase_base.phase_ordinal
         , min(task_actual_start_date_key)    as task_begin_date_key
         , max(task_actual_complete_date_key) as task_end_date_key
         , min(task_actual_start_date)        as task_begin_date
         , max(task_actual_complete_date)     as task_end_date
         , sum(task_actual_time_minutes)      as sum_actual_time
         , sum(task_plan_time_minutes)        as sum_plan_time
         , phase_type
  FROM   task_status_fact_hist
       LEFT JOIN plan_item_hist 
              ON task_status_fact_hist.plan_item_key = plan_item_hist.plan_item_key
       LEFT JOIN phase 
              ON plan_item_hist.phase_key = phase.phase_key
       LEFT JOIN phase_mapping
              ON phase.phase_key = phase_mapping.phase_key
       LEFT JOIN phase_base
              ON phase_mapping.phase_base_key = phase_base.phase_base_key
           WHERE phase_base.phase_base_key is not null
             AND task_status_fact_hist.row_current_flag = 1
             AND plan_item_hist.row_current_flag        = 1
             AND task_actual_complete_date_key > 20000101
             AND task_actual_complete_date_key < 99990000
             AND project_key in (", str_unit, ")
  GROUP BY project_key,
         phase_short_name
  ORDER BY project_key,
         phase_base.phase_ordinal,
         phase_base.phase_base_key
                                            ", seq=""))

# Read data selection from text file
fact_selection         <- read.table("select_project-fact_data.txt"     , header=T, comment.char="#"                           , sep=",")
fidelity_selection     <- read.table("select_project-fidelity_data.txt" , header=T, comment.char="#", sep=",")
qualitySheet_selection <- read.table("select_project-quality_data.txt"  , header=T, comment.char="#", sep=",")

selection_flgs        <-list( fact_selection,   fidelity_selection,   qualitySheet_selection)
names(selection_flgs) <-   c("fact_selection", "fidelity_selection", "qualitySheeet_selection")

# Get data frame for project fact and project process fidelity
DF_list <- list(
     tab_project_info,           tab_organization_info,     tab_process_info,            tab_teams_info,
     tab_duration_info,          tab_time_info,             tab_time_log_info,           tab_task_info,
     tab_bcws_info,              tab_size_info,             tab_defect_injected_info,    tab_defect_removed_info,
     tab_defect_fix_time_info,   tab_task_completion_info,  tab_phase_time_info
	 )
names(DF_list) <- c(
    "tab_project_info",         "tab_organization_info",   "tab_process_info",          "tab_teams_info",
    "tab_duration_info",        "tab_time_info",           "tab_time_log_info",         "tab_task_info",
    "tab_bcws_info",            "tab_size_info",           "tab_defect_injected_info",  "tab_defect_removed_info",
    "tab_defect_fix_time_info", "tab_task_completion_info","tab_phase_time_info"
)

source("getFactDataFrame.R")
getFactDataFrame(unit, DF_list, selection_flgs, currentDirectory, "project")

#if(FALSE){ # build this later
# source("buildQuality.R")
# builQualitySheet(unit, DF_list, selection_flgs, currentDirectory)
#}
}
