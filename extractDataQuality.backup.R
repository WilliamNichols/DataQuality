#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Extract the data quality sheet
# 2015/2/22
# Yasutaka Shirai

source("getDQDataFrame.R")

extractDataQuality <- function(con, currentDirectory)
{
  
  # Get project data from SEMPR
  tab_project_info<-dbGetQuery(con, "select project.project_key,quote(project_name) as project_name, parent_project_key, project_pattern from project left join project_layer on project.project_key = project_layer.project_key")
  
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
  
  # Get necessary data records from SEMPRE
  tab_project_info<-dbGetQuery(con, paste("select project_key,quote(project_name) from project where project_key in (", str_unit, ")", seq=""))
  tab_organization_info<-dbGetQuery(con, paste("select project_key,org_mapping.organization_key, quote(organization_name) as organization_name from organization left join org_mapping on organization.organization_key = org_mapping.organization_key where project_key in (", str_unit, ")", seq=""))
  tab_teams_info<-dbGetQuery(con, paste("SELECT distinct project_key, team_key FROM time_log_fact_hist join data_block on time_log_fact_hist.data_block_key = data_block.data_block_key join plan_item on time_log_fact_hist.plan_item_key = plan_item.plan_item_key where project_key in (", str_unit, ")", seq=""))
  tab_person_info<-dbGetQuery(con, paste("SELECT distinct project_key, person_key FROM time_log_fact_hist join data_block on time_log_fact_hist.data_block_key = data_block.data_block_key join plan_item on time_log_fact_hist.plan_item_key = plan_item.plan_item_key where project_key in (", str_unit, ")", seq=""))
  tab_time_info<-dbGetQuery(con, paste("SELECT distinct time_log_fact_key, time_log_delta_minutes, time_log_interrupt_minutes, time_log_start_date, time_log_start_date_key, time_log_end_date, team_key, person_key, wbs_element_key, project_key, time_log_fact_hist.data_block_key, time_log_fact_hist.plan_item_key FROM time_log_fact_hist left join plan_item on time_log_fact_hist.plan_item_key = plan_item.plan_item_key left join data_block on time_log_fact_hist.data_block_key = data_block.data_block_key where project_key in (", str_unit, ")", seq=""))
  tab_defect_info<-dbGetQuery(con, paste("SELECT distinct defect_log_fact_key, defect_fix_count, defect_fix_time_minutes, defect_fix_defect_identifier, defect_found_date, defect_type_key, defect_removed_phase_key, removed_phase.phase_short_name as defect_removed_phase_short_name, defect_injected_phase_key, injected_phase.phase_short_name as defect_injected_phase_short_name, team_key, person_key, wbs_element_key, project_key, defect_log_fact_hist.data_block_key, defect_log_fact_hist.plan_item_key FROM defect_log_fact_hist left join plan_item on defect_log_fact_hist.plan_item_key = plan_item.plan_item_key left join data_block on defect_log_fact_hist.data_block_key = data_block.data_block_key left join phase as removed_phase on defect_log_fact_hist.defect_removed_phase_key = removed_phase.phase_key left join phase as injected_phase on defect_log_fact_hist.defect_injected_phase_key = injected_phase.phase_key where project_key in (", str_unit, ")", seq=""))
  tab_size_info<-dbGetQuery(con, paste("SELECT distinct size_fact_key, size_added_and_modified, size_added, size_base, size_deleted, size_modified, size_reused, size_total, measurement_type_key, size_fact_hist.size_metric_key, size_metric_name, team_key, person_key, wbs_element_key, project_key, size_fact_hist.data_block_key, size_fact_hist.plan_item_key FROM size_fact_hist left join plan_item on size_fact_hist.plan_item_key = plan_item.plan_item_key left join data_block on size_fact_hist.data_block_key = data_block.data_block_key left join size_metric on size_fact_hist.size_metric_key = size_metric.size_metric_key where project_key in (", str_unit, ")", seq=""))
  tab_task_info<-dbGetQuery(con, paste("SELECT distinct task_status_fact_key, task_actual_start_date, task_actual_complete_date, task_actual_time_minutes, task_plan_time_minutes, task_actual_start_date_key, task_actual_complete_date_key, team_key, person_key, wbs_element_key, project_key, task_status_fact_hist.data_block_key, task_status_fact_hist.plan_item_key FROM task_status_fact_hist left join plan_item on task_status_fact_hist.plan_item_key = plan_item.plan_item_key left join data_block on task_status_fact_hist.data_block_key = data_block.data_block_key where project_key in (", str_unit, ")" , seq=""))

  # for examination of consistency
  tab_time_def_info<-dbGetQuery(con, paste("select time.plan_item_key,time.project_key,time.phase_short_name,ifnull(time.time_log_min,'0') as time_start_date,ifnull(time.time_log_max,'0') as time_end_date,ifnull(defect.def_log_min,'0') as def_fix_start_date,ifnull(defect.def_log_max,'0') as def_fix_end_date, time_sum, def_fix_time_sum from ((select time_log_fact_hist.plan_item_key,plan_item.project_key,phase_short_name,min(time_log_start_date) as time_log_min,max(time_log_end_date) as time_log_max,sum(time_log_delta_minutes) as time_sum from time_log_fact_hist left join plan_item on plan_item.plan_item_key = time_log_fact_hist.plan_item_key left join phase on plan_item.phase_key = phase.phase_key left join project on plan_item.project_key = project.project_key group by time_log_fact_hist.plan_item_key) as time left join (select defect_log_fact_hist.plan_item_key,plan_item.project_key,phase_short_name,min(defect_found_date) as def_log_min,max(defect_found_date) as def_log_max, sum(defect_fix_time_minutes) as def_fix_time_sum from defect_log_fact_hist left join plan_item on plan_item.plan_item_key = defect_log_fact_hist.plan_item_key left join phase on plan_item.phase_key = phase.phase_key left join project on plan_item.project_key = project.project_key group by defect_log_fact_hist.plan_item_key) as defect on time.plan_item_key = defect.plan_item_key) where time.project_key in (", str_unit, ")", seq=""))

  # for examination of time overlapping
  tab_time_overlap_info<-dbGetQuery(con, paste("select time_log_fact_key,time_log_fact_hist.plan_item_key,wbs_element_key,person_key,project_key,(select time_log_end_date from time_log_fact_hist as t2 left join data_block as d2 on t2.data_block_key = d2.data_block_key where d2.person_key = d1.person_key and t2.time_log_fact_key = time_log_fact_hist.time_log_fact_key-1)  as pre_time_log_end_date,time_log_start_date,time_log_end_date,date_format(time_log_start_date, '%Y-%m-%d') as start_day, date_format(time_log_end_date, '%Y-%m-%d') as end_day,time_log_delta_minutes,time_log_interrupt_minutes from time_log_fact_hist left join data_block as d1 on time_log_fact_hist.data_block_key = d1.data_block_key left join plan_item on time_log_fact_hist.plan_item_key = plan_item.plan_item_key where project_key in (", str_unit, ") order by project_key,person_key,time_log_start_date", seq=""))

  # Read data selection from text file
  fact_selection <- read.table("select_project-fact_data.txt", header=T, comment.char="#", sep=",")
  fidelity_selection <- read.table("select_project-fidelity_data.txt", header=T, comment.char="#", sep=",")
  selection_flgs <- list(fact_selection, fidelity_selection)
  names(selection_flgs) <- c("fact_selection", "fidelity_selection")
  
  # Get data frame for project fact and project process fidelity
  DF_list <- list(tab_project_info, tab_organization_info, tab_teams_info, tab_person_info, tab_time_info, tab_defect_info, tab_size_info, tab_task_info, tab_time_def_info, tab_time_overlap_info)
  names(DF_list) <- c("tab_project_info", "tab_organization_info","tab_teams_info", "tab_person_info", "tab_time_info", "tab_defect_info", "tab_size_info", "tab_task_info", "tab_time_def_info", "tab_time_overlap_info") 
  
  DF_dq <- getDQDataFrame(unit, DF_list, selection_flgs, currentDirectory, "project")
  
  file_path <- paste(currentDirectory, "/project_data_quality_", Sys.Date(), ".csv", sep="")
  write.csv(DF_dq, file_path, row.names=F)
}