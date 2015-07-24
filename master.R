#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Master file for the integration tool which extract data from SEMPRE
# 2014/7/17
# Yasutaka Shirai
# Updated: 2014/9/14, Yasutaka Shirai
# Update MySQL command for extracting basic fact sheet

require(data.table)
require(chron)
require(DBI)
require(RMySQL)
require(knitr)
library(lattice)
library(xlsx)

## Set the directory which include this file as work directory
frame_files <- lapply(sys.frames(), function(x) x$ofile)
frame_files <- Filter(Negate(is.null), frame_files)
setwd(dirname(frame_files[[length(frame_files)]]))

# GEt current directory path
currentDirectory <- getwd()

# Get present date
presentDate <- Sys.Date()
  
## Read the configuration file
source("config.txt")

## Connect and authenticate to a MySQL database
con<-dbConnect(m,user=MyName,password=MyPass,host='localhost',dbname=MydbName);

## Execute verifying Data Quality


## Extract Basic fact sheets
# Basic fact sheets are extracted from SEMPRE by using MysQL command direcly
##
# Extract Time fact sheet
#dbGetQuery(con, paste("SELECT 'time_log_fact_key', 'project_key', 'person_key', 'team_key', 'wbs_element_key', 'plan_item_key', 'time_log_start_date', 'time_log_end_date', 'time_log_delta_minutes', 'time_log_interrupt_minutes', 'phase_key', 'phase_short_name', 'phase.process_key', 'process_name' union (select time_log_fact_key, project_key, person_key, team_key, wbs_element_key, time_log_fact_hist.plan_item_key, time_log_start_date, time_log_end_date, time_log_delta_minutes, time_log_interrupt_minutes, plan_item_hist.phase_key, phase_short_name, phase.process_key, process_name FROM time_log_fact_hist left join data_block on time_log_fact_hist.data_block_key = data_block.data_block_key left join plan_item_hist on time_log_fact_hist.plan_item_key = plan_item_hist.plan_item_key left join phase on plan_item_hist.phase_key = phase.phase_key left join process on phase.process_key = process.process_key order by time_log_fact_key into outfile \"", currentDirectory, "/basic_time_fact_sheet_", presentDate,".csv\" fields terminated by ',')", sep=""))
#dbGetQuery(con, paste("SELECT 'time_log_fact_key', 'project_key', 'person_key', 'team_key', 'wbs_element_key', 'plan_item_key', 'time_log_start_date', 'time_log_end_date', 'time_log_delta_minutes', 'time_log_interrupt_minutes', 'phase_key', 'phase_short_name', 'phase.process_key', 'process_name' union (select time_log_fact_key, project_key, person_key, team_key, wbs_element_key, time_log_fact_hist.plan_item_key, time_log_start_date, time_log_end_date, time_log_delta_minutes, time_log_interrupt_minutes, plan_item_hist.phase_key, phase_short_name, phase.process_key, process_name FROM time_log_fact_hist left join data_block on time_log_fact_hist.data_block_key = data_block.data_block_key left join plan_item_hist on time_log_fact_hist.plan_item_key = plan_item_hist.plan_item_key left join phase on plan_item_hist.phase_key = phase.phase_key left join process on phase.process_key = process.process_key order by time_log_fact_key into outfile \"basic_time_fact_sheet_", presentDate,".csv\" fields terminated by ',')", sep=""))
# Extract defect fact sheet
#dbGetQuery(con, paste("SELECT 'defect_log_fact_key', 'project_key', 'person_key', 'team_key', 'wbs_element_key', 'plan_item_key', 'defect_fix_count', 'defect_fix_time_minutes', 'defect_found_date', 'defect_type_key', 'defect_removed_phase_key', 'removed_phase.phase_short_name', 'defect_injected_phase_key', 'injected_phase.phase_short_name', 'defect_found_date_key', 'removed_phase.process_key', 'process_name' union (SELECT defect_log_fact_key, project_key, person_key, team_key, wbs_element_key, defect_log_fact_hist.plan_item_key, defect_fix_count, defect_fix_time_minutes, defect_found_date, defect_type_key, defect_removed_phase_key, removed_phase.phase_short_name, defect_injected_phase_key, injected_phase.phase_short_name, defect_found_date_key, removed_phase.process_key, process_name FROM defect_log_fact_hist left join data_block on defect_log_fact_hist.data_block_key = data_block.data_block_key left join plan_item_hist on defect_log_fact_hist.plan_item_key = plan_item_hist.plan_item_key left join phase as injected_phase on defect_log_fact_hist.defect_injected_phase_key = injected_phase.phase_key left join phase as removed_phase on defect_log_fact_hist.defect_removed_phase_key = removed_phase.phase_key left join process on removed_phase.process_key = process.process_key order by defect_log_fact_key into outfile \"", currentDirectory, "/basic_defect_fact_sheet_", presentDate,".csv\" fields terminated by ',')", sep=""))
#dbGetQuery(con, paste("SELECT 'defect_log_fact_key', 'project_key', 'person_key', 'team_key', 'wbs_element_key', 'plan_item_key', 'defect_fix_count', 'defect_fix_time_minutes', 'defect_found_date', 'defect_type_key', 'defect_removed_phase_key', 'removed_phase.phase_short_name', 'defect_injected_phase_key', 'injected_phase.phase_short_name', 'defect_found_date_key', 'removed_phase.process_key', 'process_name' union (SELECT defect_log_fact_key, project_key, person_key, team_key, wbs_element_key, defect_log_fact_hist.plan_item_key, defect_fix_count, defect_fix_time_minutes, defect_found_date, defect_type_key, defect_removed_phase_key, removed_phase.phase_short_name, defect_injected_phase_key, injected_phase.phase_short_name, defect_found_date_key, removed_phase.process_key, process_name FROM defect_log_fact_hist left join data_block on defect_log_fact_hist.data_block_key = data_block.data_block_key left join plan_item_hist on defect_log_fact_hist.plan_item_key = plan_item_hist.plan_item_key left join phase as injected_phase on defect_log_fact_hist.defect_injected_phase_key = injected_phase.phase_key left join phase as removed_phase on defect_log_fact_hist.defect_removed_phase_key = removed_phase.phase_key left join process on removed_phase.process_key = process.process_key order by defect_log_fact_key into outfile \"basic_defect_fact_sheet_", presentDate,".csv\" fields terminated by ',')", sep=""))
# Extract size fact sheet
#dbGetQuery(con, paste("SELECT 'size_fact_key', 'project_key', 'person_key', 'team_key', 'wbs_element_key', 'plan_item_key', 'size_added_and_modified', 'size_added', 'size_base', 'size_deleted', 'size_modified', 'size_reused', 'size_total', 'measurement_type_key', 'measurement_type_name', 'size_metric_key', 'size_metric_name', 'size_metric_short_name', 'phase_key', 'phase_short_name', 'process_key', 'process_name' union (SELECT size_fact_key, project_key, person_key, team_key, wbs_element_key, size_fact_hist.plan_item_key, size_added_and_modified, size_added, size_base, size_deleted, size_modified, size_reused, size_total, size_fact_hist.measurement_type_key, measurement_type_name, size_fact_hist.size_metric_key, size_metric_name, size_metric_short_name, plan_item_hist.phase_key, phase_short_name, phase.process_key, process_name FROM size_fact_hist left join data_block on size_fact_hist.data_block_key = data_block.data_block_key left join plan_item_hist on size_fact_hist.plan_item_key = plan_item_hist.plan_item_key left join phase on plan_item_hist.phase_key = phase.phase_key left join process on phase.process_key = process.process_key left join measurement_type on size_fact_hist.measurement_type_key = measurement_type.measurement_type_key left join size_metric on size_fact_hist.size_metric_key = size_metric.size_metric_key order by size_fact_key into outfile \"", currentDirectory, "/basic_size_fact_sheet_", presentDate,".csv\" fields terminated by ',')", sep=""))
#dbGetQuery(con, paste("SELECT 'size_fact_key', 'project_key', 'person_key', 'team_key', 'wbs_element_key', 'plan_item_key', 'size_added_and_modified', 'size_added', 'size_base', 'size_deleted', 'size_modified', 'size_reused', 'size_total', 'measurement_type_key', 'measurement_type_name', 'size_metric_key', 'size_metric_name', 'size_metric_short_name', 'phase_key', 'phase_short_name', 'process_key', 'process_name' union (SELECT size_fact_key, project_key, person_key, team_key, wbs_element_key, size_fact_hist.plan_item_key, size_added_and_modified, size_added, size_base, size_deleted, size_modified, size_reused, size_total, size_fact_hist.measurement_type_key, measurement_type_name, size_fact_hist.size_metric_key, size_metric_name, size_metric_short_name, plan_item_hist.phase_key, phase_short_name, phase.process_key, process_name FROM size_fact_hist left join data_block on size_fact_hist.data_block_key = data_block.data_block_key left join plan_item_hist on size_fact_hist.plan_item_key = plan_item_hist.plan_item_key left join phase on plan_item_hist.phase_key = phase.phase_key left join process on phase.process_key = process.process_key left join measurement_type on size_fact_hist.measurement_type_key = measurement_type.measurement_type_key left join size_metric on size_fact_hist.size_metric_key = size_metric.size_metric_key order by size_fact_key into outfile \"basic_size_fact_sheet_", presentDate,".csv\" fields terminated by ',')", sep=""))
# Extract task fact sheet
#dbGetQuery(con, paste("SELECT 'task_status_fact_key', 'project_key', 'person_key', 'team_key', 'wbs_element_key', 'plan_item_key', 'task_actual_start_date', 'task_actual_complete_date', 'task_actual_time_minutes', 'task_plan_time_minutes', 'task_actual_start_date_key', 'task_actual_complete_date_key', 'phase_key', 'phase_short_name', 'phase.process_key', 'process_name' union (SELECT task_status_fact_key, project_key, person_key, team_key, wbs_element_key, task_status_fact_hist.plan_item_key, task_actual_start_date, task_actual_complete_date, task_actual_time_minutes, task_plan_time_minutes, task_actual_start_date_key, task_actual_complete_date_key, plan_item_hist.phase_key, phase_short_name, phase.process_key, process_name FROM task_status_fact_hist left join data_block on task_status_fact_hist.data_block_key = data_block.data_block_key left join plan_item_hist on task_status_fact_hist.plan_item_key = plan_item_hist.plan_item_key left join phase on plan_item_hist.phase_key = phase.phase_key left join process on phase.process_key = process.process_key order by task_status_fact_key into outfile \"", currentDirectory, "/basic_task_fact_sheet_", presentDate,".csv\" fields terminated by ',')", sep=""))
#dbGetQuery(con, paste("SELECT 'task_status_fact_key', 'project_key', 'person_key', 'team_key', 'wbs_element_key', 'plan_item_key', 'task_actual_start_date', 'task_actual_complete_date', 'task_actual_time_minutes', 'task_plan_time_minutes', 'task_actual_start_date_key', 'task_actual_complete_date_key', 'phase_key', 'phase_short_name', 'phase.process_key', 'process_name' union (SELECT task_status_fact_key, project_key, person_key, team_key, wbs_element_key, task_status_fact_hist.plan_item_key, task_actual_start_date, task_actual_complete_date, task_actual_time_minutes, task_plan_time_minutes, task_actual_start_date_key, task_actual_complete_date_key, plan_item_hist.phase_key, phase_short_name, phase.process_key, process_name FROM task_status_fact_hist left join data_block on task_status_fact_hist.data_block_key = data_block.data_block_key left join plan_item_hist on task_status_fact_hist.plan_item_key = plan_item_hist.plan_item_key left join phase on plan_item_hist.phase_key = phase.phase_key left join process on phase.process_key = process.process_key order by task_status_fact_key into outfile \"basic_task_fact_sheet_", presentDate,".csv\" fields terminated by ',')", sep=""))

## Extract Aggregated fact sheets
# Extract Project fact sheet and Project process fidelity sheet
#source("extractProjectFact.R")
#extractProjectFact(con, currentDirectory)
# Extract Component fact sheet and Component process fidelity sheet
#source("extractComponentFact.R")
#extractComponentFact(con, currentDirectory)

## Generate data quality report
source("extractDataQuality.R")
extractDataQuality(con, currentDirectory)
#knitr::knit("data_quality_report.Rmd")
#rmd_analysis_dq <- knit("data_quality_report.Rmd")
#pandoc(rmd_analysis_dq, format='docx')

## Extract digits evaluation sheet
#source("examineDigitsEvaluation.R")
#examineDigitsEvaluation(con, currentDirectory)

## Generate production rate report
#knitr::knit("examineFitDist-of-ProductionRate.Rmd")

## Generate docx report 
#rmd_analysis_all <- knit("examineStatAnalysis-of-AllWorkItem_DLD-UT.Rmd")
#pandoc(rmd_analysis_all, format='docx')

#rmd_analysis_PR_pj <- knit("examineFitDist-of-ProductionRate-byPj_DLD-UT.Rmd")
#pandoc(rmd_analysis_PR_pj, format='docx')

#rmd_analysis_PR_ind <- knit("examineFitDist-of-ProductionRate-byInd_DLD-UT.Rmd")
#pandoc(rmd_analysis_PR_ind, format='docx')

#rmd_analysis_DIR_pj <- knit("examineFitDist-of-DefectInjectionRate-byPj_DLD-UT.Rmd")
#pandoc(rmd_analysis_DIR_pj, format='docx')

#rmd_analysis_DIR_ind <- knit("examineFitDist-of-DefectInjectionRate-byInd_DLD-UT.Rmd")
#pandoc(rmd_analysis_DIR_ind, format='docx')

#rmd_analysis_DRR_pj <- knit("examineFitDist-of-DefectRemovalRate-byPj_DLD-UT.Rmd")
#pandoc(rmd_analysis_DRR_pj, format='docx')

#rmd_analysis_DRR_ind <- knit("examineFitDist-of-DefectRemovalRate-byInd_DLD-UT.Rmd")
#pandoc(rmd_analysis_DRR_ind, format='docx')

#rmd_analysis_all <- knit("examineProjectCharacteristics.Rmd")
#pandoc(rmd_analysis_all, format='docx')

#rmd_analysis_benford <- knit("examineDigitsEvaluation.Rmd")
#pandoc(rmd_analysis_benford, format='docx')

#rmd_analysis_PY <- knit("examinePhaseYield_DLD-UT_PJ.Rmd")
#pandoc(rmd_analysis_PY, format='docx')

#rmd_analysis_BN <- knit("executeBayesianNetwork.Rmd")
#pandoc(rmd_analysis_BN, format='docx')

#rmd_analysis_MC <- knit("execMCSimulation.Rmd")
#pandoc(rmd_analysis_MC, format='docx')