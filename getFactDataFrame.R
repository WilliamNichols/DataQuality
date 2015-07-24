#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Extract the fact data and the process fidelity data
# 2014/7/17
# Yasutaka Shirai
# Update: 2014/9/14, Yasutaka Shirai
# Updated the formula of defect removal yield by each phase
# Update: 2015/1/28, Yasutaka Shirai
# Added the function to extract the parent_project_key

source("networkdays.R") # need to specify absolute path
source("stopdays.R") # need to specify absolute path
source("calcweeks.R") #need to specify absolute path

# Notification for no data
NoData <- "No Data"

getFactDataFrame <- function(unit, DF_list, selection_flgs, currentDirectory, unit_name) {
  
  # Exchange second argument into each data frame which is used in this function
  tab_project_info         <- DF_list$tab_project_info
  tab_organization_info    <- DF_list$tab_organization_info
  tab_process_info         <- DF_list$tab_process_info
  tab_teams_info           <- DF_list$tab_teams_info
  tab_duration_info        <- DF_list$tab_duration_info
  tab_time_info            <- DF_list$tab_time_info
  tab_completed_task_time_info <- DF_list$tab_completed_task_time_info
  tab_time_log_info        <- DF_list$tab_time_log_info
  tab_ev_info              <- DF_list$tab_ev_info
  tab_bcws_info            <- DF_list$tab_bcws_info   # this one may not be useful (WRN, not actually schedule data)
  tab_size_info            <- DF_list$tab_size_info
  tab_defect_injected_info <- DF_list$tab_defect_injected_info
  tab_defect_removed_info  <- DF_list$tab_defect_removed_info
  tab_defect_fix_time_info <- DF_list$tab_defect_fix_time_info
  tab_task_completion_info <- DF_list$tab_task_completion_info  # used for launch data and plan duration
  source("default_PlaningParameters.R")
  
  if (unit_name == "component") {
    tab_wbs_info <- DF_list$tab_wbs_info
  }
  
  ## Output CSV header which is selected
  # fact sheet CSV header
  fact_data_att_list <- subset(selection_flgs$fact_selection, selection_flg==1)
  increment_fact <- 1
  # fidelity sheet CSV header
  fidelity_data_att_list <- subset(selection_flgs$fidelity_selection, selection_flg==1)
  increment_fidelity <- 1
  
  if (unit_name == "project") {
    file_path_fact <- paste(currentDirectory, "/project_fact_sheet_", Sys.Date(), ".csv", sep="")
    file_path_fidelity <- paste(currentDirectory, "/project_process_fidelity_sheet_", Sys.Date(), ".csv", sep="")
    unit_key <- "project_key"
  } else if (unit_name == "component") {
    file_path_fact <- paste(currentDirectory, "/component_fact_sheet_", Sys.Date(), ".csv", sep="")
    file_path_fidelity <- paste(currentDirectory, "/component_process_fidelity_sheet_", Sys.Date(), ".csv", sep="")
    unit_key <- "wbs_element_key"
  }
  
  out_fact <- file(file_path_fact, "w")   
  
  for (fact_data_att in fact_data_att_list$attribute) {
    if (increment_fact < length(fact_data_att_list$attribute)) {
      writeLines(paste(fact_data_att), out_fact, sep=",")  
    } else {
      writeLines(paste(fact_data_att), out_fact, sep="\n")
    }
    
    increment_fact <- increment_fact + 1
  }
  
  out_fidelity <- file(file_path_fidelity, "w")
  
  for (fidelity_data_att in fidelity_data_att_list$attribute) {
    if (increment_fidelity < length(fidelity_data_att_list$attribute)) {
      writeLines(paste(fidelity_data_att), out_fidelity, sep=",")  
    } else {
      writeLines(paste(fidelity_data_att), out_fidelity, sep="\n")
    }
    
    increment_fidelity <- increment_fidelity + 1
  }
  
  ## Extract data by each unit
  for (element in unit) {
  
    ## Prepare vector for internal variable
    phase_vector <- list()
    ## Extract project inormation from project table
    if (nrow(tab_project_info) == 0) {
      if (unit_name == "project") {
        project_name <- NoData
      } else if (unit_name == "component") {
        project_key <- NoData
      }
    } else {
      #project_info <- subset(tab_project_info, project_key==element) 
      project_info <- subset(tab_project_info, get(unit_key)==element)

      if (unit_name == "project") {
        project_name <- project_info$project_name
        parent_project_key <- project_info$parent_project_key
      } else if (unit_name == "component") {
        project_key <- paste(project_info$project_key, collapse=";")
        parent_project_key <- paste(project_info$parent_project_key, collapse=";")
      }
    }
    
    ## Extract wbs name information from wbs element table
    if (unit_name == "component") {
      wbs_info <- subset(tab_wbs_info, get(unit_key)==element)
      wbs_element_name <- wbs_info$wbs_element_name
    }
    
    ## Extract organization information from organization table
    organization_info <- subset(tab_organization_info, get(unit_key)==element)
    
    if (length(organization_info$organization_key) > 0) {
      if (unit_name == "project") {
        organization_key <- organization_info$organization_key
      } else if (unit_name == "component") {
        organization_key <- paste(unique(organization_info$organization_key), collapse=";")
      }
    } else {
      organization_key <- NoData
    }
    
    ## Extract team and individuals information
    if (nrow(tab_teams_info) == 0) {
      if (unit_name == "project") {
        team_name <- NoData
        team_size <- NoData
        individuals <- NoData
      } else if (unit_name == "component") {
        team_key <- NoData
      }
    } else {
      #team_info <- subset(tab_teams_info, project_key==element)
      team_info <- subset(tab_teams_info, get(unit_key)==element)
      if (unit_name == "project") {
        if (length(unique(team_info$team_name)) == 0) {
          team_name <- NoData
        } else {
          team_name <- unique(team_info$team_name)
        }
      } else if (unit_name == "component") {
        if (length(unique(team_info$team_key)) == 0) {
          team_key <- NoData
        } else {
          team_key_tmp <- unique(team_info$team_key)
          team_key <- paste(team_key_tmp, collapse=";")
        }
      }
      if (length(team_info$person_key) == 0) {
        team_size <- NoData
        individuals <- NoData
      } else {
        team_size <- length(team_info$person_key)
        individuals <- paste(team_info$person_key, collapse=":")
      }
    }
    
    ## Extract process information
    if (nrow(tab_process_info) == 0) {
      process_name <- NoData
    } else {
      #process_info <- subset(tab_process_info, project_key==element)
      process_info <- subset(tab_process_info, get(unit_key)==element)
      if (length(process_info$process_name) == 0) {
        process_name <- NoData
      } else if (length(process_info$process_name) > 1) {
        process_name <- paste(process_info$process_name, collapse=";")
      } else {
        process_name <- process_info$process_name
      }
    }
  
    ## Extract project date informatio from time log fact hist table
    if (nrow(tab_duration_info) == 0) {
      start_date_char <- NoData
      end_date_char <- NoData
    } else {  
      #duration_info <- subset(tab_duration_info, project_key==element)
      duration_info <- subset(tab_duration_info, get(unit_key)==element)
      
      if (length(duration_info$start_date) == 0) {
        start_date_char <- NoData
        start_week <- NoData
      } else {
        start_date_char <- duration_info$start_date
        start_week <- duration_info$start_week
      }
      
      if (length(duration_info$end_date) == 0) {
        end_date_char <- NoData
        end_week <- NoData
      } else {
        end_date_char <- duration_info$end_date
        end_week <- duration_info$end_week
      }
    }

    ## Calculate duration
    if (length(duration_info$start_date) == 0 || length(duration_info$end_date) == 0) {
      actual_duration <- 0
      actual_weeks <- NoData
    } else {
      start_date_char_vector <- unlist(strsplit(start_date_char, "-"))
      end_date_char_vector <- unlist(strsplit(end_date_char, "-"))
      
      start_date_year <- as.numeric(start_date_char_vector[1])
      start_date_month <- as.numeric(start_date_char_vector[2])
      start_day_vector <- unlist(strsplit(start_date_char_vector[3], " "))
      start_date_day <- as.numeric(start_day_vector[1])
      
      end_date_year <- as.numeric(end_date_char_vector[1])
      end_date_month <- as.numeric(end_date_char_vector[2])
      end_day_vector <- unlist(strsplit(end_date_char_vector[3], " "))
      end_date_day <- as.numeric(end_day_vector[1])
      
      if ((start_date_year >= 2000) && (end_date_year >= 2000)) {
        if ((start_date_month <= 12) && (end_date_month <= 12)) {
          if ((start_date_day <= 31) && (end_date_day <= 31)) {
            project_start_date <- as.Date(start_date_char)
            project_end_date <- as.Date(end_date_char)
            
            actual_duration <- networkdays(project_start_date, project_end_date)
          }
        }
      }
      actual_weeks <- duration_info$actual_weeks
    }
    
    ## Calculate stop days
    #time_log_info <- subset(tab_time_log_info, project_key==element)
    time_log_info <- subset(tab_time_log_info, get(unit_key)==element)
    
    if (length(time_log_info$time_log_start_date) == 0 || length(time_log_info$time_log_end_date) == 0) {
      stop_days <- 0
    } else {
      date_df <- data.frame(start_day=time_log_info$start_day, end_day=time_log_info$end_day)
      stop_days <- stopdays(min(time_log_info$start_day), max(time_log_info$end_day), date_df)
    }
    
    ## Extract task date information by each unit
    #task_completion_info <- subset(tab_task_completion_info, project_key==element)
    task_completion_info <- subset(tab_task_completion_info, get(unit_key)==element)

    work_plan_info <- subset(task_completion_info, measurement_type_key==1 & task_date_key > 19900000 & task_date_key < 29991231)
    # Extract task effort data from task status fact hist table by each phase and unit
    #time_info <- subset(tab_time_info, project_key==element)
    time_info <- subset(tab_time_info, get(unit_key)==element)

    # Extract plan and actual time info with completed task
    completed_task_time_info <- subset(tab_completed_task_time_info, get(unit_key)==element)

    # Extract plan duration
    #plan_start_date <- as.Date(min(work_plan_info$task_completion_date), format="%Y%m%d")
    #plan_end_date <- as.Date(max(work_plan_info$task_completion_date), format="%Y%m%d")

    if (length(work_plan_info$task_completion_date) == 0) {
      plan_duration <- 0
    } else {
      task_completion_date <- work_plan_info$task_completion_date[!is.na(work_plan_info$task_completion_date)]
      plan_duration        <- networkdays(min(task_completion_date), max(task_completion_date))
      #plan_duration <- networkdays(min(work_plan_info$task_completion_date), max(work_plan_info$task_completion_date))
    }

    # plan variance of duration
    duration_variance <- actual_duration - plan_duration
    
    # % variance of duration
    duration_variance_percent <- (duration_variance/plan_duration)*100.
    
    ## Extract earned value from ev schedule period fact hist table
    # Calculate BAC, BCWP, and ACWP
    if (length(tab_ev_info) == 0) {
      BAC  <- NoData
      BCWP <- NoData
      ACWP <- NoData
    } else {
      #ev_info                <- subset(tab_ev_info,      project_key==element)   
      ev_info                 <- subset(tab_ev_info,      get(unit_key)==element)    # all tasks,
#      ev_plan_info            <- subset(ev_info,          measurement_type_key==1)  # 
      ev_complete_info        <- subset(ev_info,          task_actual_complete_date_key < 99990000)  # is this the best way to sepaRate
###      ev_plan_complete_info   <- subset(ev_complete_info, measurement_type_key==1)
###      ev_actual_complete_info <- subset(ev_complete_info, measurement_type_key==4)
  
      ev_actual_complete_info <- ev_complete_info

      
      BAC  <- sum(ev_info$task_plan_time_minutes, na.rm=TRUE)/60
      BCWP <- sum(ev_complete_info$task_plan_time_minutes, na.rm=TRUE)/60
      ACWP <- sum(ev_complete_info$task_actual_time_minutes, na.rm=TRUE)/60
    }
    
    # Calculate BCWS
    if (length(tab_bcws_info) == 0) {
    } else {
      #bcws_info <- subset(tab_bcws_info, project_key==element)
      bcws_info <- subset(tab_bcws_info, get(unit_key)==element)
      
      if (length(bcws_info$sum_plan_minutes) == 0) {
        BCWS <- NoData
      } else {
        BCWS <- bcws_info$sum_plan_minutes/60
      }
    }
  
    # Calculate CPI and CV
    if (BCWP == NoData || ACWP == NoData) {
      CPI <- NoData
      CV <- NoData
    } else {
      CPI <- BCWP/ACWP
      CV <- BCWP-ACWP
    }
    
    # Calculate SPI and SV  ### WRN, this is not correct becasue BCWS is wrong
    if (BCWP == NoData || BCWS == NoData) {
      SPI <- NoData
      SV <- NoData
    } else {
      SPI <- BCWP/BCWS
      SV  <- BCWP-BCWS
    }
    
    
    # this "might" be useful to estimate work scheduled but not performed
    # Calculate BAC, BCWP, and Final_EV  
    CumPV <- BAC
    CumEV <- BCWP
    Final_EV <- NoData
    
    # Calculate effort variance  # cost variance does not appear anywhere elase
    effort_variance          <- BCWP-ACWP
    effort_variance_percent  <- (effort_variance/BCWP)*100.
  
    ## task hours estimation
    #### wrn, this is the task estimion, not resource!
  
    baseline_task_hours                   <- NoData
    project_completed_parts_plan_hours    <- sum(completed_task_time_info$sum_plan_time, na.rm=TRUE)/60
    project_completed_parts_actual_hours  <- sum(completed_task_time_info$sum_actual_time, na.rm=TRUE)/60
    growth_in_task_hours_baseline_to_plan <- NoData
  
    plan_date_set <- subset(ev_info, task_plan_key < 99999000)   #wrn, removed "_plan" because the selectino did not work, instead each record has a plan component

    if (length(plan_date_set$task_plan_key) == 0) {
      plan_date <- NoData
    } else {
      plan_date <- max(plan_date_set$task_plan_key)
    }
    
    ## Extract all phases information
    if (length(time_info$phase_short_name) == 0) {
      all_phases <- NoData
    } else {
      all_phases_vector <- time_info$phase_short_name
      all_phases <- paste(all_phases_vector[!is.na(all_phases_vector)], collapse=":")
    }
    
    ## Calculate plan task hours and actual task hours by using time_info
    actual_task_hours <- sum(time_info$sum_actual_time, na.rm=TRUE)/60
    plan_task_hours   <- sum(time_info$sum_plan_time, na.rm=TRUE)/60
    if (actual_weeks == NoData || team_size == NoData) {
      mean_team_task_hours_week <- NoData
      mean_team_member_task_hours_week <- NoData
    } else {
      mean_team_task_hours_week <- actual_task_hours/actual_weeks
      mean_team_member_task_hours_week <- actual_task_hours/(actual_weeks*team_size)
    }
    
    ## Extract plan size and actual size infomation from size fact hist table 
    #plan_size_info <- subset(tab_size_info, project_key==element & measurement_type_key=="1" & size_metric_name=="Lines of Code")
    #actual_size_info <- subset(tab_size_info, project_key==element & measurement_type_key=="4" & size_metric_name=="Lines of Code")
    plan_size_info   <- subset(tab_size_info, get(unit_key)==element & measurement_type_key=="1" & size_metric_name=="Lines of Code")
    actual_size_info <- subset(tab_size_info, get(unit_key)==element & measurement_type_key=="4" & size_metric_name=="Lines of Code")
    
    if (length(plan_size_info$sum_size_base) == 0 || is.na(plan_size_info$sum_size_base)) {
      planB <- 0
    } else {
      planB <- plan_size_info$sum_size_base
    }
    
    if (length(plan_size_info$sum_size_deleted) == 0 || is.na(plan_size_info$sum_size_deleted)) {
      planD <- 0
    } else {
      planD <- plan_size_info$sum_size_deleted
    }
    
    if (length(plan_size_info$sum_size_modified) == 0 || is.na(plan_size_info$sum_size_modified)) {
      planM <- 0
    } else {
      planM <- plan_size_info$sum_size_modified
    }
    
    if (length(plan_size_info$sum_size_added) == 0 || is.na(plan_size_info$sum_size_added)) {
      planA <- 0
    } else {
      planA <- plan_size_info$sum_size_added
    }
  
    if (length(plan_size_info$sum_size_reused) == 0 || is.na(plan_size_info$sum_size_reused)) {
      planR <- 0
    } else {
      planR <- plan_size_info$sum_size_reused
    }
    
    if (length(plan_size_info$sum_size_am) == 0 || is.na(plan_size_info$sum_size_am)) {
      planAM <- 0
    } else {
      planAM <- plan_size_info$sum_size_am
    }
    
    if (length(plan_size_info$sum_size_total) == 0 || is.na(plan_size_info$sum_size_total)) {
      planT <- 0
    } else {
      planT <- plan_size_info$sum_size_total
    }
    
    planNR <- NoData
  
    if (length(actual_size_info$sum_size_base) == 0 || is.na(actual_size_info$sum_size_base)) {
      actualB <- 0
    } else {
      actualB <- actual_size_info$sum_size_base
    }
    
    if (length(actual_size_info$sum_size_deleted) == 0 || is.na(actual_size_info$sum_size_deleted)) {
      actualD <- 0
    } else {
      actualD <- actual_size_info$sum_size_deleted
    }
    
    if (length(actual_size_info$sum_size_modified) == 0 || is.na(actual_size_info$sum_size_modified)) {
      actualM <- 0
    } else {
      actualM <- actual_size_info$sum_size_modified
    }
    
    if (length(actual_size_info$sum_size_added) == 0 || is.na(actual_size_info$sum_size_added)) {
      actualA <- 0
    } else {
      actualA <- actual_size_info$sum_size_added
    }
    
    if (length(actual_size_info$sum_size_reused) == 0 || is.na(actual_size_info$sum_size_reused)) {
      actualR <- 0
    } else {
      actualR <- actual_size_info$sum_size_reused
    }
    
    if (length(actual_size_info$sum_size_am) == 0 || is.na(actual_size_info$sum_size_am)) {
      actualAM <- 0
    } else {
      actualAM <- actual_size_info$sum_size_am
    }
    
    if (length(actual_size_info$sum_size_total) == 0 || is.na(actual_size_info$sum_size_total)) {
      actualT <- 0
    } else {
      actualT <- actual_size_info$sum_size_total
    }
    
    actualNR <- NoData
  
    ## Extract defect injected and defect removed information from defect log fact hist table  
    # Extract defect injected and defect removed information by each project
    #defect_inj_info <- subset(tab_defect_injected_info, project_key==element)
    #defect_rem_info <- subset(tab_defect_removed_info, project_key==element)
    defect_inj_info <- subset(tab_defect_injected_info, get(unit_key)==element)
    defect_rem_info <- subset(tab_defect_removed_info, get(unit_key)==element)
    
    # Extract defect injected information by each phase 

    adise_set <- subset(defect_inj_info, defect_injected_phase_name=="Sys Eng")
    adimm_set <- subset(defect_inj_info, defect_injected_phase_name=="Misc")
    adils_set <- subset(defect_inj_info, defect_injected_phase_name=="StRategy")
    adiplan_set <- subset(defect_inj_info, defect_injected_phase_name=="Planning")
    adireq_set <- subset(defect_inj_info, defect_injected_phase_name=="Reqts")
    adistp_set <- subset(defect_inj_info, defect_injected_phase_name=="Sys Test Plan")
    adireqr_set <- subset(defect_inj_info, defect_injected_phase_name=="Reqts Review")
    adireqinsp_set <- subset(defect_inj_info, defect_injected_phase_name=="Reqts Inspect")
    adihld_set <- subset(defect_inj_info, defect_injected_phase_name=="HLD")
    adiitp_set <- subset(defect_inj_info, defect_injected_phase_name=="Int Test Plan")
    adihldr_set <- subset(defect_inj_info, defect_injected_phase_name=="HLD Review")
    adihldinsp_set <- subset(defect_inj_info, defect_injected_phase_name=="HLD Inspect")
    adidld_set <- subset(defect_inj_info, defect_injected_phase_name=="Design")
    adidldr_set <- subset(defect_inj_info, defect_injected_phase_name=="Design Review")
    aditd_set <- subset(defect_inj_info, defect_injected_phase_name=="Test Devel")
    adidldinsp_set <- subset(defect_inj_info, defect_injected_phase_name=="Design Inspect")
    adicode_set <- subset(defect_inj_info, defect_injected_phase_name=="Code")
    adicr_set <- subset(defect_inj_info, defect_injected_phase_name=="Code Review")
    adicompile_set <- subset(defect_inj_info, defect_injected_phase_name=="Compile")
    adiinsp_set <- subset(defect_inj_info, defect_injected_phase_name=="Code Inspect")
    adiut_set <- subset(defect_inj_info, defect_injected_phase_name=="Test")
    adibit_set <- subset(defect_inj_info, defect_injected_phase_name=="Int Test")
    adist_set <- subset(defect_inj_info, defect_injected_phase_name=="Sys Test")
    adiat_set <- subset(defect_inj_info, defect_injected_phase_name=="Accept Test")
    adipl_set <- subset(defect_inj_info, defect_injected_phase_name=="Product Life")
    adideploy_set <- subset(defect_inj_info, defect_injected_phase_name=="Deployment")
    
    # Extract defect removed information by each phase
    adrse_set <- subset(defect_rem_info, defect_removed_phase_name=="Sys Eng")
    adrmm_set <- subset(defect_rem_info, defect_removed_phase_name=="Misc")
    adrls_set <- subset(defect_rem_info, defect_removed_phase_name=="StRategy")
    adrplan_set <- subset(defect_rem_info, defect_removed_phase_name=="Planning")
    adrreq_set <- subset(defect_rem_info, defect_removed_phase_name=="Reqts")
    adrstp_set <- subset(defect_rem_info, defect_removed_phase_name=="Sys Test Plan")
    adrreqr_set <- subset(defect_rem_info, defect_removed_phase_name=="Reqts Review")
    adrreqinsp_set <- subset(defect_rem_info, defect_removed_phase_name=="Reqts Inspect")
    adrhld_set <- subset(defect_rem_info, defect_removed_phase_name=="HLD")
    adritp_set <- subset(defect_rem_info, defect_removed_phase_name=="Int Test Plan")
    adrhldr_set <- subset(defect_rem_info, defect_removed_phase_name=="HLD Review")
    adrhldinsp_set <- subset(defect_rem_info, defect_removed_phase_name=="HLD Inspect")
    adrdld_set <- subset(defect_rem_info, defect_removed_phase_name=="Design")
    adrdldr_set <- subset(defect_rem_info, defect_removed_phase_name=="Design Review")
    adrtd_set <- subset(defect_rem_info, defect_removed_phase_name=="Test Devel")
    adrdldinsp_set <- subset(defect_rem_info, defect_removed_phase_name=="Design Inspect")
    adrcode_set <- subset(defect_rem_info, defect_removed_phase_name=="Code")
    adrcr_set <- subset(defect_rem_info, defect_removed_phase_name=="Code Review")
    adrcompile_set <- subset(defect_rem_info, defect_removed_phase_name=="Compile")
    adrinsp_set <- subset(defect_rem_info, defect_removed_phase_name=="Code Inspect")
    adrut_set <- subset(defect_rem_info, defect_removed_phase_name=="Test")
    adrbit_set <- subset(defect_rem_info, defect_removed_phase_name=="Int Test")
    adrst_set <- subset(defect_rem_info, defect_removed_phase_name=="Sys Test")
    adrat_set <- subset(defect_rem_info, defect_removed_phase_name=="Accept Test")
    adrpl_set <- subset(defect_rem_info, defect_removed_phase_name=="Product Life")
    adrdeploy_set <- subset(defect_rem_info, defect_removed_phase_name=="Deployment")
    
    # Extract Plan Defects Injected
    PDISE <- NoData
    PDIMM <- NoData
    PDILS <- NoData
    PDIPLAN <- NoData
    PDIREQ <- NoData
    PDISTP <- NoData
    PDIREQINSP <- NoData
    PDIHLD <- NoData
    PDIITP <- NoData
    PDIHLDINSP <- NoData
    PDIDLD <- NoData
    PDIDLDR <- NoData
    PDITD <- NoData
    PDIDLDINSP <- NoData
    PDICODE <- NoData
    PDICR <- NoData
    PDICOMPILE <- NoData
    PDIINSP <- NoData
    PDIUT <- NoData
    PDIBIT <- NoData
    PDIST <- NoData
    PDIAT <- NoData
    PDIPL <- NoData
    PDIDEPLOY <- NoData
    PDITOTAL <- NoData
  
    # Extract Actual Defect Injected
    if (length(adise_set$sum_defect_fix_count) == 0 || is.na(adise_set$sum_defect_fix_count)) {
      ADISE <- 0
    } else {
      ADISE <- adise_set$sum_defect_fix_count
    }

    if (length(adimm_set$sum_defect_fix_count) == 0 || is.na(adimm_set$sum_defect_fix_count)) {
      ADIMM <- 0
    } else {
      ADIMM <- adimm_set$sum_defect_fix_count
    }
    
    if (length(adils_set$sum_defect_fix_count) == 0 || is.na(adils_set$sum_defect_fix_count)) {
      ADILS <- 0
    } else {
      ADILS <- adils_set$sum_defect_fix_count
    }
    
    if (length(adiplan_set$sum_defect_fix_count) == 0 || is.na(adiplan_set$sum_defect_fix_count)) {
      ADIPLAN <- 0
    } else {
      ADIPLAN <- adiplan_set$sum_defect_fix_count
    }
    
    if (length(adireq_set$sum_defect_fix_count) == 0 || is.na(adireq_set$sum_defect_fix_count)) {
      ADIREQ <- 0
    } else {
      ADIREQ <- adireq_set$sum_defect_fix_count
    } 
    
    if (length(adistp_set$sum_defect_fix_count) == 0 || is.na(adistp_set$sum_defect_fix_count)) {
      ADISTP <- 0
    } else {
      ADISTP <- adistp_set$sum_defect_fix_count
    }
  
    if (length(adireqr_set$sum_defect_fix_count) == 0 || is.na(adireqr_set$sum_defect_fix_count)) {
      ADIREQR <- 0
    } else {
      ADIREQR <- adireqr_set$sum_defect_fix_count
    }
      
    if (length(adireqinsp_set$sum_defect_fix_count) == 0 || is.na(adireqinsp_set$sum_defect_fix_count)) {
      ADIREQINSP <- 0
    } else {
      ADIREQINSP <- adireqinsp_set$sum_defect_fix_count
    }
    
    if (length(adihld_set$sum_defect_fix_count) == 0 || is.na(adihld_set$sum_defect_fix_count)) {
      ADIHLD <- 0
    } else {
      ADIHLD <- adihld_set$sum_defect_fix_count
    }
    
    if (length(adiitp_set$sum_defect_fix_count) == 0 || is.na(adiitp_set$sum_defect_fix_count)) {
      ADIITP <- 0
    } else {
      ADIITP <- adiitp_set$sum_defect_fix_count
    }
    
    if (length(adihldr_set$sum_defect_fix_count) == 0 || is.na(adihldr_set$sum_defect_fix_count)) {
      ADIHLDR <- 0
    } else {
      ADIHLDR <- adihldr_set$sum_defect_fix_count
    }
        
    if (length(adihldinsp_set$sum_defect_fix_count) == 0 || is.na(adihldinsp_set$sum_defect_fix_count)) {
      ADIHLDINSP <- 0
    } else {
      ADIHLDINSP <- adihldinsp_set$sum_defect_fix_count
    }
    
    if (length(adidld_set$sum_defect_fix_count) == 0 || is.na(adidld_set$sum_defect_fix_count)) {
      ADIDLD <- 0
    } else {
      ADIDLD <- adidld_set$sum_defect_fix_count
    }
    
    if (length(adidldr_set$sum_defect_fix_count) == 0 || is.na(adidldr_set$sum_defect_fix_count)) {
      ADIDLDR <- 0
    } else {
      ADIDLDR <- adidldr_set$sum_defect_fix_count
    }
  
    if (length(aditd_set$sum_defect_fix_count) == 0 || is.na(aditd_set$sum_defect_fix_count)) {
      ADITD <- 0
    } else {
      ADITD <- aditd_set$sum_defect_fix_count
    }
        
    if (length(adidldinsp_set$sum_defect_fix_count) == 0 || is.na(adidldinsp_set$sum_defect_fix_count)) {
      ADIDLDINSP <- 0
    } else {
      ADIDLDINSP <- adidldinsp_set$sum_defect_fix_count
    }
    
    if (length(adicode_set$sum_defect_fix_count) == 0 || is.na(adicode_set$sum_defect_fix_count)) {
      ADICODE <- 0
    } else {
      ADICODE <- adicode_set$sum_defect_fix_count
    }
    
    if (length(adicr_set$sum_defect_fix_count) == 0 || is.na(adicr_set$sum_defect_fix_count)) {
      ADICR <- 0
    } else {
      ADICR <- adicr_set$sum_defect_fix_count
    }
    
    if (length(adicompile_set$sum_defect_fix_count) == 0 || is.na(adicompile_set$sum_defect_fix_count)) {
      ADICOMPILE <- 0
    } else {
      ADICOMPILE <- adicompile_set$sum_defect_fix_count
    }
    
    if (length(adiinsp_set$sum_defect_fix_count) == 0 || is.na(adiinsp_set$sum_defect_fix_count)) {
      ADIINSP <- 0
    } else {
      ADIINSP <- adiinsp_set$sum_defect_fix_count
    }
    
    if (length(adiut_set$sum_defect_fix_count) == 0 || is.na(adiut_set$sum_defect_fix_count)) {
      ADIUT <- 0
    } else {
      ADIUT <- adiut_set$sum_defect_fix_count
    }
    
    if (length(adibit_set$sum_defect_fix_count) == 0 || is.na(adibit_set$sum_defect_fix_count)) {
      ADIBIT <- 0
    } else {
      ADIBIT <- adibit_set$sum_defect_fix_count
    }
    
    if (length(adist_set$sum_defect_fix_count) == 0 || is.na(adist_set$sum_defect_fix_count)) {
      ADIST <- 0
    } else {
      ADIST <- adist_set$sum_defect_fix_count
    }
    
    if (length(adiat_set$sum_defect_fix_count) == 0 || is.na(adiat_set$sum_defect_fix_count)) {
      ADIAT <- 0
    } else {
      ADIAT <- adiat_set$sum_defect_fix_count
    }
    
    if (length(adipl_set$sum_defect_fix_count) == 0 || is.na(adipl_set$sum_defect_fix_count)) {
      ADIPL <- 0
    } else {
      ADIPL <- adipl_set$sum_defect_fix_count
    }
    
    if (length(adideploy_set$sum_defect_fix_count) == 0 || is.na(adideploy_set$sum_defect_fix_count)) {
      ADIDEPLOY <- 0
    } else {
      ADIDEPLOY <- adideploy_set$sum_defect_fix_count
    }
    
    ADITOTAL <- sum(defect_inj_info$sum_defect_fix_count, na.rm=TRUE)
    
    # Extract Plan Defects Removed
    PDRSE <- NoData
    PDRMM <- NoData
    PDRLS <- NoData
    PDRPLAN <- NoData
    PDRREQ <- NoData
    PDRSTP <- NoData
    PDRREQINSP <- NoData
    PDRHLD <- NoData
    PDRITP <- NoData
    PDRHLDINSP <- NoData
    PDRDLD <- NoData
    PDRDLDR <- NoData
    PDRTD <- NoData
    PDRDLDINSP <- NoData
    PDRCODE <- NoData
    PDRCR <- NoData
    PDRCOMPILE <- NoData
    PDRINSP <- NoData
    PDRUT <- NoData
    PDRBIT <- NoData
    PDRST <- NoData
    PDRAT <- NoData
    PDRPL <- NoData
    PDRDEPLOY <- NoData
    PDRTOTAL <- NoData
    
    # Extract Actual Defect Injected
    if (length(adrse_set$sum_defect_fix_count) == 0 || is.na(adrse_set$sum_defect_fix_count)) {
      ADRSE <- 0
    } else {
      ADRSE <- adrse_set$sum_defect_fix_count
    }
    
    if (length(adrmm_set$sum_defect_fix_count) == 0 || is.na(adrmm_set$sum_defect_fix_count)) {
      ADRMM <- 0
    } else {
      ADRMM <- adrmm_set$sum_defect_fix_count
    }
    
    if (length(adrls_set$sum_defect_fix_count) == 0 || is.na(adrls_set$sum_defect_fix_count)) {
      ADRLS <- 0
    } else {
      ADRLS <- adrls_set$sum_defect_fix_count
    }
    
    if (length(adrplan_set$sum_defect_fix_count) == 0 || is.na(adrplan_set$sum_defect_fix_count)) {
      ADRPLAN <- 0
    } else {
      ADRPLAN <- adrplan_set$sum_defect_fix_count
    }
    
    if (length(adrreq_set$sum_defect_fix_count) == 0 || is.na(adrreq_set$sum_defect_fix_count)) {
      ADRREQ <- 0
    } else {
      ADRREQ <- adrreq_set$sum_defect_fix_count
    }
    
    if (length(adrstp_set$sum_defect_fix_count) == 0 || is.na(adrstp_set$sum_defect_fix_count)) {
      ADRSTP <- 0
    } else {
      ADRSTP <- adrstp_set$sum_defect_fix_count
    }
    
    if (length(adrreqr_set$sum_defect_fix_count) == 0 || is.na(adrreqr_set$sum_defect_fix_count)) {
      ADRREQR <- 0
    } else {
      ADRREQR <- adrreqr_set$sum_defect_fix_count
    }
     
    if (length(adrreqinsp_set$sum_defect_fix_count) == 0 || is.na(adrreqinsp_set$sum_defect_fix_count)) {
      ADRREQINSP <- 0
    } else {
      ADRREQINSP <- adrreqinsp_set$sum_defect_fix_count
    }
  
    if (length(adrhld_set$sum_defect_fix_count) == 0 || is.na(adrhld_set$sum_defect_fix_count)) {
      ADRHLD <- 0
    } else {
      ADRHLD <- adrhld_set$sum_defect_fix_count
    }
    
    if (length(adritp_set$sum_defect_fix_count) == 0 || is.na(adritp_set$sum_defect_fix_count)) {
      ADRITP <- 0
    } else {
      ADRITP <- adritp_set$sum_defect_fix_count
    }
    
    if (length(adrhldr_set$sum_defect_fix_count) == 0 || is.na(adrhldr_set$sum_defect_fix_count)) {
      ADRHLDR <- 0
    } else {
      ADRHLDR <- adrhldr_set$sum_defect_fix_count
    }
    
    if (length(adrhldinsp_set$sum_defect_fix_count) == 0 || is.na(adrhldinsp_set$sum_defect_fix_count)) {
      ADRHLDINSP <- 0
    } else {
      ADRHLDINSP <- adrhldinsp_set$sum_defect_fix_count
    }
    
    if (length(adrdld_set$sum_defect_fix_count) == 0 || is.na(adrdld_set$sum_defect_fix_count)) {
      ADRDLD <- 0
    } else {
      ADRDLD <- adrdld_set$sum_defect_fix_count
    }
    
    if (length(adrdldr_set$sum_defect_fix_count) == 0 || is.na(adrdldr_set$sum_defect_fix_count)) {
      ADRDLDR <- 0
    } else {
      ADRDLDR <- adrdldr_set$sum_defect_fix_count
    }
    
    if (length(adrtd_set$sum_defect_fix_count) == 0 || is.na(adrtd_set$sum_defect_fix_count)) {
      ADRTD <- 0
    } else {
      ADRTD <- adrtd_set$sum_defect_fix_count
    }
    
    if (length(adrdldinsp_set$sum_defect_fix_count) == 0 || is.na(adrdldinsp_set$sum_defect_fix_count)) {
      ADRDLDINSP <- 0
    } else {
      ADRDLDINSP <- adrdldinsp_set$sum_defect_fix_count
    }
    
    if (length(adrcode_set$sum_defect_fix_count) == 0 || is.na(adrcode_set$sum_defect_fix_count)) {
      ADRCODE <- 0
    } else {
      ADRCODE <- adrcode_set$sum_defect_fix_count
    }
    
    if (length(adrcr_set$sum_defect_fix_count) == 0 || is.na(adrcr_set$sum_defect_fix_count)) {
      ADRCR <- 0
    } else {
      ADRCR <- adrcr_set$sum_defect_fix_count
    }
    
    if (length(adrcompile_set$sum_defect_fix_count) == 0 || is.na(adrcompile_set$sum_defect_fix_count)) {
      ADRCOMPILE <- 0
    } else {
      ADRCOMPILE <- adrcompile_set$sum_defect_fix_count
    }
    
    if (length(adrinsp_set$sum_defect_fix_count) == 0 || is.na(adrinsp_set$sum_defect_fix_count)) {
      ADRINSP <- 0
    } else {
      ADRINSP <- adrinsp_set$sum_defect_fix_count
    }
    
    if (length(adrut_set$sum_defect_fix_count) == 0 || is.na(adrut_set$sum_defect_fix_count)) {
      ADRUT <- 0
    } else {
      ADRUT <- adrut_set$sum_defect_fix_count
    }
    
    if (length(adrbit_set$sum_defect_fix_count) == 0 || is.na(adrbit_set$sum_defect_fix_count)) {
      ADRBIT <- 0
    } else {
      ADRBIT <- adrbit_set$sum_defect_fix_count
    }
    
    if (length(adrst_set$sum_defect_fix_count) == 0 || is.na(adrst_set$sum_defect_fix_count)) {
      ADRST <- 0
    } else {
      ADRST <- adrst_set$sum_defect_fix_count
    }
    
    if (length(adrat_set$sum_defect_fix_count) == 0 || is.na(adrat_set$sum_defect_fix_count)) {
      ADRAT <- 0
    } else {
      ADRAT <- adrat_set$sum_defect_fix_count
    }
    
    if (length(adrpl_set$sum_defect_fix_count) == 0 || is.na(adrpl_set$sum_defect_fix_count)) {
      ADRPL <- 0
    } else {
      ADRPL <- adrpl_set$sum_defect_fix_count
    }
    
    if (length(adrdeploy_set$sum_defect_fix_count) == 0 || is.na(adrdeploy_set$sum_defect_fix_count)) {
      ADRDEPLOY <- 0
    } else {
      ADRDEPLOY <- adrdeploy_set$sum_defect_fix_count
    }
    
    ADRTOTAL <- sum(defect_rem_info$sum_defect_fix_count, na.rm=TRUE)
  
    # Extract defect find and fix time in each phase
    #defect_fix_time_info <- subset(tab_defect_fix_time_info, project_key==element)
    defect_fix_time_info <- subset(tab_defect_fix_time_info, get(unit_key)==element)
    deft_ut_set <- subset(defect_fix_time_info, phase_short_name=="Test")
    project_key <- element
    
    if (length(deft_ut_set$sum_defect_fix_time) == 0 || is.na(deft_ut_set$sum_defect_fix_time)) {
      DEFFIXTUT <- 0
    } else {
      DEFFIXTUT <- deft_ut_set$sum_defect_fix_time/60
    }
  
    # Extract time in phase information from task status fact hist table by each phase 
    tse_set <- subset(time_info, phase_short_name=="Sys Eng")
    tmm_set <- subset(time_info, phase_short_name=="Misc")
    tls_set <- subset(time_info, phase_short_name=="StRategy")
    tplan_set <- subset(time_info, phase_short_name=="Planning")
    treq_set <- subset(time_info, phase_short_name=="Reqts")
    tstp_set <- subset(time_info, phase_short_name=="Sys Test Plan")
    treqinsp_set <- subset(time_info, phase_short_name=="Reqts Inspect")
    thld_set <- subset(time_info, phase_short_name=="HLD")
    titp_set <- subset(time_info, phase_short_name=="Int Test Plan")
    thldinsp_set <- subset(time_info, phase_short_name=="HLD Inspect")
    tdld_set <- subset(time_info, phase_short_name=="Design")
    tdldr_set <- subset(time_info, phase_short_name=="Design Review")
    ttd_set <- subset(time_info, phase_short_name=="Test Devel")
    tdldinsp_set <- subset(time_info, phase_short_name=="Design Inspect")
    tcode_set <- subset(time_info, phase_short_name=="Code")
    tcr_set <- subset(time_info, phase_short_name=="Code Review")
    tcompile_set <- subset(time_info, phase_short_name=="Compile")
    tinsp_set <- subset(time_info, phase_short_name=="Code Inspect")
    tut_set <- subset(time_info, phase_short_name=="Test")
    tbit_set <- subset(time_info, phase_short_name=="Int Test")
    tst_set <- subset(time_info, phase_short_name=="Sys Test")
    tdoc_set <- subset(time_info, phase_short_name=="Documentation")
    tpm_set <- subset(time_info, phase_short_name=="Postmortem")
    tat_set <- subset(time_info, phase_short_name=="Accept Test")
    tpl_set <- subset(time_info, phase_short_name=="Product Life")
    tdeploy_set <- subset(time_info, phase_short_name=="Deployment")
    total_plan_minutes <- sum(time_info$sum_plan_time, na.rm=TRUE)
    total_actual_minutes <- sum(time_info$sum_actual_time, na.rm=TRUE)
  
    # Extract Launch date information
    # Launch_begin_date is extracted from time_log_fact_hist table
    # Launch_end_date is extracted from task_date_fact_hist table
    if (length(tls_set$task_begin_date) == 0) {
      launch_begin_date <- NoData
    } else {
      launch_begin_date <- tls_set$task_begin_date
    }
  
    launch_completion_info <- subset(task_completion_info, phase_short_name=="StRategy" & measurement_type_key==4)
  
    if (length(launch_completion_info$task_date_key) == 0) {
      launch_end_date <- NoData
    } else {
      launch_end_date <- min(launch_completion_info$task_date_key)
    }
  
    # Extract work start date plan information
    # Work_start_date_plan is extracted from task_date_fact_hist_table 
  
    if (length(work_plan_info$task_date_key) == 0) {
      work_start_date_plan <- NoData
      work_end_date_plan <- NoData
    } else {
      work_start_date_plan <- min(work_plan_info$task_date_key)
      work_end_date_plan   <- max(work_plan_info$task_date_key)
    }
  
    # Extract final product delivery date information
    # Final product delivery date information is regarded as end date of testing activity by each unit 
    # Final_product_delivery_plan is extracted from task_date_fact_hist_table Final_product_delivery_actual is extracted from time_log_fact_hist
    product_delivery_plan_info <- subset(work_plan_info, regexpr("\\Test$", work_plan_info$phase_short_name) != -1)

    if (length(product_delivery_plan_info$task_date_key) == 0) {
      final_product_delivery_plan <- NoData
    } else {
      final_product_delivery_plan <- max(product_delivery_plan_info$task_completion_date)
    }
  
    product_delivery_actual_info <- subset(time_info, regexpr("\\Test$", time_info$phase_short_name) != -1 & task_end_date < 99990000)
  
    if (length(product_delivery_actual_info$task_end_date) == 0) {
      final_product_delivery_actual <- NoData
    } else {
      final_product_delivery_actual <- max(product_delivery_actual_info$task_end_date)
    }
  
    baseline_date <- NoData
    predicted_date <- NoData
    if (work_start_date_plan == NoData || work_end_date_plan == NoData) {
      plan_weeks <- NoData
    } else {
      start_date_plan_str <- paste(substring(work_start_date_plan,1,4),"-",substring(work_start_date_plan,5,6),"-",substring(work_start_date_plan,7,8),sep="")
      end_date_plan_str <- paste(substring(work_end_date_plan,1,4),"-",substring(work_end_date_plan,5,6),"-",substring(work_end_date_plan,7,8),sep="")
      start_week_plan_str <- format(as.Date(start_date_plan_str), "%Y%W")
      end_week_plan_str <- format(as.Date(end_date_plan_str),"%Y%W")
      #plan_weeks <- format(as.Date(end_date_plan_str),"%Y%W")-format(as.Date(start_date_plan_str), "%Y%W")
      #plan_weeks <- as.Date(end_date_plan_str,"%Y%W")-as.Date(start_date_plan_str,"%Y%W")
      plan_weeks  <- calcweeks(start_week_plan_str, end_week_plan_str)
    }
    baseline_weeks <- NoData
    growth_schedule_baseline <- NoData
    
    # Extract Planned Time in Phase, Planned Phase Rate, and  Planned Time Percent in Phase
    if (length(tse_set$sum_plan_time) == 0 || is.na(tse_set$sum_plan_time)) {
      PTSE <- 0
      PRate_SE <- 0
      PT_PERCENT_SE <- 0
    } else {
      PTSE <- tse_set$sum_plan_time
      PRate_SE <- planAM/PTSE*60
      PT_PERCENT_SE <- PTSE/total_plan_minutes*100
    }
    
    if (length(tmm_set$sum_plan_time) == 0 || is.na(tmm_set$sum_plan_time)) {
      PTMM <- 0
      PRate_MM <- 0
      PT_PERCENT_MM <- 0
    } else {
      PTMM <- tmm_set$sum_plan_time
      PRate_MM <- planAM/PTMM*60
      PT_PERCENT_MM <- PTMM/total_plan_minutes*100
    }
  
    if (length(tls_set$sum_plan_time) == 0 || is.na(tls_set$sum_plan_time)) {
      PTLS <- 0
      PRate_LS <- 0
      PT_PERCENT_LS <- 0
    } else {
      PTLS <- tls_set$sum_plan_time
      PRate_LS <- planAM/PTLS*60
      PT_PERCENT_LS <- PTLS/total_plan_minutes*100
    }
    
    if (length(tplan_set$sum_plan_time) == 0 || is.na(tplan_set$sum_plan_time)) {
      PTPLAN <- 0
      PRate_PLAN <- 0
      PT_PERCENT_PLAN <- 0
    } else {
      PTPLAN <- tplan_set$sum_plan_time
      PRate_PLAN <- planAM/PTPLAN*60
      PT_PERCENT_PLAN <- PTPLAN/total_plan_minutes*100
    }
    
    if (length(treq_set$sum_plan_time) == 0 || is.na(treq_set$sum_plan_time)) {
      PTREQ <- 0
      PRate_REQ <- 0
      PT_PERCENT_REQ <- 0
    } else {
      PTREQ <- treq_set$sum_plan_time
      PRate_REQ <- planAM/PTREQ*60
      PT_PERCENT_REQ <- PTREQ/total_plan_minutes*100
    }
    
    if (length(tstp_set$sum_plan_time) == 0 || is.na(tstp_set$sum_plan_time)) {
      PTSTP <- 0
      PRate_STP <- 0
      PT_PERCENT_STP <- 0
    } else {
      PTSTP <- tstp_set$sum_plan_time
      PRate_STP <- planAM/PTSTP*60
      PT_PERCENT_STP <- PTSTP/total_plan_minutes*100
    }
    
    if (length(treqinsp_set$sum_plan_time) == 0 || is.na(treqinsp_set$sum_plan_time)) {
      PTREQINSP <- 0
      PRate_REQINSP <- 0
      PT_PERCENT_REQINSP <- 0
    } else {
      PTREQINSP <- treqinsp_set$sum_plan_time
      PRate_REQINSP <- planAM/PTREQINSP*60
      PT_PERCENT_REQINSP <- PTREQINSP/total_plan_minutes*100
    }
    
    if (length(thld_set$sum_plan_time) == 0 || is.na(thld_set$sum_plan_time)) {
      PTHLD <- 0
      PRate_HLD <- 0
      PT_PERCENT_HLD <- 0
    } else {  
      PTHLD <- thld_set$sum_plan_time
      PRate_HLD <- planAM/PTHLD*60
      PT_PERCENT_HLD <- PTHLD/total_plan_minutes*100
    }
    
    if (length(titp_set$sum_plan_time) == 0 || is.na(titp_set$sum_plan_time)) {
      PTITP <- 0
      PRate_ITP <- 0
      PT_PERCENT_ITP <- 0
    } else {
      PTITP <- titp_set$sum_plan_time
      PRate_ITP <- planAM/PTITP*60
      PT_PERCENT_ITP <- PTITP/total_plan_minutes*100
    }
    
    if (length(thldinsp_set$sum_plan_time) == 0 || is.na(thldinsp_set$sum_plan_time)) {
      PTHLDINSP <- 0
      PRate_HLDINSP <- 0
      PT_PERCENT_HLDINSP <- 0
    } else {
      PTHLDINSP <- thldinsp_set$sum_plan_time
      PRate_HLDINSP <- planAM/PTHLDINSP*60
      PT_PERCENT_HLDINSP <- PTHLDINSP/total_plan_minutes*100
    }
    
    if (length(tdld_set$sum_plan_time) == 0 || is.na(tdld_set$sum_plan_time)) {
      PTDLD <- 0
      PRate_DLD <- 0
      PT_PERCENT_DLD <- 0
    } else {
      PTDLD <- tdld_set$sum_plan_time
      PRate_DLD <- planAM/PTDLD*60
      PT_PERCENT_DLD <- PTDLD/total_plan_minutes*100
    }
    
    if (length(tdldr_set$sum_plan_time) == 0 || is.na(tdldr_set$sum_plan_time)) {
      PTDLDR <- 0
      PRate_DLDR <- 0
      PT_PERCENT_DLDR <- 0
    } else {
      PTDLDR <- tdldr_set$sum_plan_time
      PRate_DLDR <- planAM/PTDLDR*60
      PT_PERCENT_DLDR <- PTDLDR/total_plan_minutes*100
    }
    
    if (length(ttd_set$sum_plan_time) == 0 || is.na(ttd_set$sum_plan_time)) {
      PTTD <- 0
      PRate_TD <- 0
      PT_PERCENT_TD <- 0
    } else {
      PTTD <- ttd_set$sum_plan_time
      PRate_TD <- planAM/PTTD*60
      PT_PERCENT_TD <- PTTD/total_plan_minutes*100
    }
    
    if (length(tdldinsp_set$sum_plan_time) == 0 || is.na(tdldinsp_set$sum_plan_time)) {
      PTDLDINSP <- 0
      PRate_DLDINSP <- 0
      PT_PERCENT_DLDINSP <- 0
    } else {
      PTDLDINSP <- tdldinsp_set$sum_plan_time
      PRate_DLDINSP <- planAM/PTDLDINSP*60
      PT_PERCENT_DLDINSP <- PTDLDINSP/total_plan_minutes*100
    }
     
    if (length(tcode_set$sum_plan_time) == 0 || is.na(tcode_set$sum_plan_time)) {
      PTCODE <- 0
      PRate_CODE <- 0
      PT_PERCENT_CODE <- 0
    } else {
      PTCODE <- tcode_set$sum_plan_time
      PRate_CODE <- planAM/PTCODE*60
      PT_PERCENT_CODE <- PTCODE/total_plan_minutes*100
    }
    
    if (length(tcr_set$sum_plan_time) == 0 || is.na(tcr_set$sum_plan_time)) {
      PTCR <- 0
      PRate_CR <- 0
      PT_PERCENT_CR <- 0
    } else {
      PTCR <- tcr_set$sum_plan_time
      PRate_CR <- planAM/PTCR*60
      PT_PERCENT_CR <- PTCR/total_plan_minutes*100
    }
    
    if (length(tcompile_set$sum_plan_time) == 0 || is.na(tcompile_set$sum_plan_time)) {
      PTCOMPILE <- 0
      PRate_COMPILE <- 0
      PT_PERCENT_COMPILE <- 0
    } else {
      PTCOMPILE <- tcompile_set$sum_plan_time
      PRate_COMPILE <- planAM/PTCOMPILE*60
      PT_PERCENT_COMPILE <- PTCOMPILE/total_plan_minutes*100
    }
    
    if (length(tinsp_set$sum_plan_time) == 0 || is.na(tinsp_set$sum_plan_time)) {
      PTINSP <- 0
      PRate_INSP <- 0
      PT_PERCENT_INSP <- 0
    } else {
      PTINSP <- tinsp_set$sum_plan_time
      PRate_INSP <- planAM/PTINSP*60
      PT_PERCENT_INSP <- PTINSP/total_plan_minutes*100
    }
    
    if (length(tut_set$sum_plan_time) == 0 || is.na(tut_set$sum_plan_time)) {
      PTUT <- 0
      PRate_UT <- 0
      PT_PERCENT_UT <- 0
    } else {
      PTUT <- tut_set$sum_plan_time
      PRate_UT <- planAM/PTUT*60
      PT_PERCENT_UT <- PTUT/total_plan_minutes*100
    }
    
    if (length(tbit_set$sum_plan_time) == 0 || is.na(tbit_set$sum_plan_time)) {
      PTBIT <- 0
      PRate_BIT <- 0
      PT_PERCENT_BIT <- 0
    } else {
      PTBIT <- tbit_set$sum_plan_time
      PRate_BIT <- planAM/PTBIT*60
      PT_PERCENT_BIT <- PTBIT/total_plan_minutes*100
    }
    
    if (length(tst_set$sum_plan_time) == 0 || is.na(tst_set$sum_plan_time)) {
      PTST <- 0
      PRate_ST <- 0
      PT_PERCENT_ST <- 0
    } else {
      PTST <- tst_set$sum_plan_time
      PRate_ST <- planAM/PTST*60
      PT_PERCENT_ST <- PTST/total_plan_minutes*100
    }
    
    if (length(tdoc_set$sum_plan_time) == 0 || is.na(tdoc_set$sum_plan_time)) {
      PTDOC <- 0
      PRate_DOC <- 0
      PT_PERCENT_DOC <- 0
    } else {
      PTDOC <- tdoc_set$sum_plan_time
      PRate_DOC <- planAM/PTDOC*60
      PT_PERCENT_DOC <- PTDOC/total_plan_minutes*100
    }
    
    if (length(tpm_set$sum_plan_time) == 0 || is.na(tpm_set$sum_plan_time)) {
      PTPM <- 0
      PRate_PM <- 0
      PT_PERCENT_PM <- 0
    } else {
      PTPM <- tpm_set$sum_plan_time
      PRate_PM <- planAM/PTPM*60
      PT_PERCENT_PM <- PTPM/total_plan_minutes*100
    }
    
    if (length(tat_set$sum_plan_time) == 0 || is.na(tat_set$sum_plan_time)) {
      PTAT <- 0
      PRate_AT <- 0
      PT_PERCENT_AT <- 0
    } else {
      PTAT <- tat_set$sum_plan_time
      PRate_AT <- planAM/PTAT*60
      PT_PERCENT_AT <- PTAT/total_plan_minutes*100
    }
    
    if (length(tpl_set$sum_plan_time) == 0 || is.na(tpl_set$sum_plan_time)) {
      PTPL <- 0
      PRate_PL <- 0
      PT_PERCENT_PL <- 0
    } else {
      PTPL <- tpl_set$sum_plan_time
      PRate_PL <- planAM/PTPL*60
      PT_PERCENT_PL <- PTPL/total_plan_minutes*100
    }
    
    if (length(tdeploy_set$sum_plan_time) == 0 || is.na(tdeploy_set$sum_plan_time)) {
      PTDEPLOY <- 0
      PRate_DEPLOY <- 0
      PT_PERCENT_DEPLOY <- 0
    } else {
      PTDEPLOY <- tdeploy_set$sum_plan_time
      PRate_DEPLOY <- planAM/PTDEPLOY*60
      PT_PERCENT_DEPLOY <- PTDEPLOY/total_plan_minutes*100
    }
    
    PTTOTAL <- sum(time_info$sum_plan_time, na.rm=TRUE)
    
    # Extract Actual Time in Phase, Actual Phase Rate, and  Actual Time Percent in Phase
    if (length(tse_set$sum_actual_time) == 0 || is.na(tse_set$sum_actual_time)) {
      ATSE <- 0
      ARate_SE <- 0
      AT_PERCENT_SE <- 0
    } else {
      ATSE <- tse_set$sum_actual_time
      ARate_SE <- planAM/ATSE*60
      AT_PERCENT_SE <- ATSE/total_actual_minutes*100
    }
    
    if (length(tmm_set$sum_actual_time) == 0 || is.na(tmm_set$sum_actual_time)) {
      ATMM <- 0
      ARate_MM <- 0
      AT_PERCENT_MM <- 0
    } else {
      ATMM <- tmm_set$sum_actual_time
      ARate_MM <- planAM/ATMM*60
      AT_PERCENT_MM <- ATMM/total_actual_minutes*100
    }
    
    if (length(tls_set$sum_actual_time) == 0 || is.na(tls_set$sum_actual_time)) {
      ATLS <- 0
      ARate_LS <- 0
      AT_PERCENT_LS <- 0
    } else {
      ATLS <- tls_set$sum_actual_time
      ARate_LS <- planAM/ATLS*60
      AT_PERCENT_LS <- ATLS/total_actual_minutes*100
    }
    
    if (length(tplan_set$sum_actual_time) == 0 || is.na(tplan_set$sum_actual_time)) {
      ATPLAN <- 0
      ARate_PLAN <- 0
      AT_PERCENT_PLAN <- 0
    } else {
      ATPLAN <- tplan_set$sum_actual_time
      ARate_PLAN <- planAM/ATPLAN*60
      AT_PERCENT_PLAN <- ATPLAN/total_actual_minutes*100
    }
    
    if (length(treq_set$sum_actual_time) == 0 || is.na(treq_set$sum_actual_time)) {
      ATREQ <- 0
      ARate_REQ <- 0
      AT_PERCENT_REQ <- 0
    } else {
      ATREQ <- treq_set$sum_actual_time
      ARate_REQ <- planAM/ATREQ*60
      AT_PERCENT_REQ <- ATREQ/total_actual_minutes*100
      phase_vector[length(phase_vector)+1] = "Req"
    }
    
    if (length(tstp_set$sum_actual_time) == 0 || is.na(tstp_set$sum_actual_time)) {
      ATSTP <- 0
      ARate_STP <- 0
      AT_PERCENT_STP <- 0
    } else {
      ATSTP <- tstp_set$sum_actual_time
      ARate_STP <- planAM/ATSTP*60
      AT_PERCENT_STP <- ATSTP/total_actual_minutes*100
    }
    
    if (length(treqinsp_set$sum_actual_time) == 0 || is.na(treqinsp_set$sum_actual_time)) {
      ATREQINSP <- 0
      ARate_REQINSP <- 0
      AT_PERCENT_REQINSP <- 0
    } else {
      ATREQINSP <- treqinsp_set$sum_actual_time
      ARate_REQINSP <- planAM/ATREQINSP*60
      AT_PERCENT_REQINSP <- ATREQINSP/total_actual_minutes*100
    }
    
    if (length(thld_set$sum_actual_time) == 0 || is.na(thld_set$sum_actual_time)) {
      ATHLD <- 0
      ARate_HLD <- 0
      AT_PERCENT_HLD <- 0
    } else {  
      ATHLD <- thld_set$sum_actual_time
      ARate_HLD <- planAM/ATHLD*60
      AT_PERCENT_HLD <- ATHLD/total_actual_minutes*100
      phase_vector[length(phase_vector)+1] = "HLD"
    }
    
    if (length(titp_set$sum_actual_time) == 0 || is.na(titp_set$sum_actual_time)) {
      ATITP <- 0
      ARate_ITP <- 0
      AT_PERCENT_ITP <- 0
    } else {
      ATITP <- titp_set$sum_actual_time
      ARate_ITP <- planAM/ATITP*60
      AT_PERCENT_ITP <- ATITP/total_actual_minutes*100
    }
    
    if (length(thldinsp_set$sum_actual_time) == 0 || is.na(thldinsp_set$sum_actual_time)) {
      ATHLDINSP <- 0
      ARate_HLDINSP <- 0
      AT_PERCENT_HLDINSP <- 0
    } else {
      ATHLDINSP <- thldinsp_set$sum_actual_time
      ARate_HLDINSP <- planAM/ATHLDINSP*60
      AT_PERCENT_HLDINSP <- ATHLDINSP/total_actual_minutes*100
    }
    
    if (length(tdld_set$sum_actual_time) == 0 || is.na(tdld_set$sum_actual_time)) {
      ATDLD <- 0
      ARate_DLD <- 0
      AT_PERCENT_DLD <- 0
    } else {
      ATDLD <- tdld_set$sum_actual_time
      ARate_DLD <- planAM/ATDLD*60
      AT_PERCENT_DLD <- ATDLD/total_actual_minutes*100
      phase_vector[length(phase_vector)+1] = "DLD"
    }
    
    if (length(tdldr_set$sum_actual_time) == 0 || is.na(tdldr_set$sum_actual_time)) {
      ATDLDR <- 0
      ARate_DLDR <- 0
      AT_PERCENT_DLDR <- 0
    } else {
      ATDLDR <- tdldr_set$sum_actual_time
      ARate_DLDR <- planAM/ATDLDR*60
      AT_PERCENT_DLDR <- ATDLDR/total_actual_minutes*100
    }
    
    if (length(ttd_set$sum_actual_time) == 0 || is.na(ttd_set$sum_actual_time)) {
      ATTD <- 0
      ARate_TD <- 0
      AT_PERCENT_TD <- 0
    } else {
      ATTD <- ttd_set$sum_actual_time
      ARate_TD <- planAM/ATTD*60
      AT_PERCENT_TD <- ATTD/total_actual_minutes*100
    }
    
    if (length(tdldinsp_set$sum_actual_time) == 0 || is.na(tdldinsp_set$sum_actual_time)) {
      ATDLDINSP <- 0
      ARate_DLDINSP <- 0
      AT_PERCENT_DLDINSP <- 0
    } else {
      ATDLDINSP <- tdldinsp_set$sum_actual_time
      ARate_DLDINSP <- planAM/ATDLDINSP*60
      AT_PERCENT_DLDINSP <- ATDLDINSP/total_actual_minutes*100
    }
    
    if (length(tcode_set$sum_actual_time) == 0 || is.na(tcode_set$sum_actual_time)) {
      ATCODE <- 0
      ARate_CODE <- 0
      AT_PERCENT_CODE <- 0
    } else {
      ATCODE <- tcode_set$sum_actual_time
      ARate_CODE <- planAM/ATCODE*60
      AT_PERCENT_CODE <- ATCODE/total_actual_minutes*100
      phase_vector[length(phase_vector)+1] = "Code"
    }
    
    if (length(tcr_set$sum_actual_time) == 0 || is.na(tcr_set$sum_actual_time)) {
      ATCR <- 0
      ARate_CR <- 0
      AT_PERCENT_CR <- 0
    } else {
      ATCR <- tcr_set$sum_actual_time
      ARate_CR <- planAM/ATCR*60
      AT_PERCENT_CR <- ATCR/total_actual_minutes*100
    }
    
    if (length(tcompile_set$sum_actual_time) == 0 || is.na(tcompile_set$sum_actual_time)) {
      ATCOMPILE <- 0
      ARate_COMPILE <- 0
      AT_PERCENT_COMPILE <- 0
    } else {
      ATCOMPILE <- tcompile_set$sum_actual_time
      ARate_COMPILE <- planAM/ATCOMPILE*60
      AT_PERCENT_COMPILE <- ATCOMPILE/total_actual_minutes*100
      phase_vector[length(phase_vector)+1] = "Compile"
    }
    
    if (length(tinsp_set$sum_actual_time) == 0 || is.na(tinsp_set$sum_actual_time)) {
      ATINSP <- 0
      ARate_INSP <- 0
      AT_PERCENT_INSP <- 0
    } else {
      ATINSP <- tinsp_set$sum_actual_time
      ARate_INSP <- planAM/ATINSP*60
      AT_PERCENT_INSP <- ATINSP/total_actual_minutes*100
    }
    
    if (length(tut_set$sum_actual_time) == 0 || is.na(tut_set$sum_actual_time)) {
      ATUT <- 0
      ARate_UT <- 0
      AT_PERCENT_UT <- 0
    } else {
      ATUT <- tut_set$sum_actual_time
      ARate_UT <- planAM/ATUT*60
      AT_PERCENT_UT <- ATUT/total_actual_minutes*100
      phase_vector[length(phase_vector)+1] = "UT"
    }
    
    if (length(tbit_set$sum_actual_time) == 0 || is.na(tbit_set$sum_actual_time)) {
      ATBIT <- 0
      ARate_BIT <- 0
      AT_PERCENT_BIT <- 0
    } else {
      ATBIT <- tbit_set$sum_actual_time
      ARate_BIT <- planAM/ATBIT*60
      AT_PERCENT_BIT <- ATBIT/total_actual_minutes*100
      phase_vector[length(phase_vector)+1] = "BIT"
    }
    
    if (length(tst_set$sum_actual_time) == 0 || is.na(tst_set$sum_actual_time)) {
      ATST <- 0
      ARate_ST <- 0
      AT_PERCENT_ST <- 0
    } else {
      ATST <- tst_set$sum_actual_time
      ARate_ST <- planAM/ATST*60
      AT_PERCENT_ST <- ATST/total_actual_minutes*100
      phase_vector[length(phase_vector)+1] = "ST"
    }
    
    if (length(tdoc_set$sum_actual_time) == 0 || is.na(tdoc_set$sum_actual_time)) {
      ATDOC <- 0
      ARate_DOC <- 0
      AT_PERCENT_DOC <- 0
    } else {
      ATDOC <- tdoc_set$sum_actual_time
      ARate_DOC <- planAM/ATDOC*60
      AT_PERCENT_DOC <- ATDOC/total_actual_minutes*100
    }
    
    if (length(tpm_set$sum_actual_time) == 0 || is.na(tpm_set$sum_actual_time)) {
      ATPM <- 0
      ARate_PM <- 0
      AT_PERCENT_PM <- 0
    } else {
      ATPM <- tpm_set$sum_actual_time
      ARate_PM <- planAM/ATPM*60
      AT_PERCENT_PM <- ATPM/total_actual_minutes*100
    }
    
    if (length(tat_set$sum_actual_time) == 0 || is.na(tat_set$sum_actual_time)) {
      ATAT <- 0
      ARate_AT <- 0
      AT_PERCENT_AT <- 0
    } else {
      ATAT <- tat_set$sum_actual_time
      ARate_AT <- planAM/ATAT*60
      AT_PERCENT_AT <- ATAT/total_actual_minutes*100
      #phase_vector[length(phase_vector)+1] = "AT"
    }
    
    if (length(tpl_set$sum_actual_time) == 0 || is.na(tpl_set$sum_actual_time)) {
      ATPL <- 0
      ARate_PL <- 0
      AT_PERCENT_PL <- 0
    } else {
      ATPL <- tpl_set$sum_actual_time
      ARate_PL <- planAM/ATPL*60
      AT_PERCENT_PL <- ATPL/total_actual_minutes*100
    }
    
    if (length(tdeploy_set$sum_actual_time) == 0 || is.na(tdeploy_set$sum_actual_time)) {
      ATDEPLOY <- 0
      ARate_DEPLOY <- 0
      AT_PERCENT_DEPLOY <- 0
    } else {
      ATDEPLOY <- tdeploy_set$sum_actual_time
      ARate_DEPLOY <- planAM/ATDEPLOY*60
      AT_PERCENT_DEPLOY <- ATDEPLOY/total_actual_minutes*100
    }
    
    ATTOTAL <- sum(time_info$sum_actual_time, na.rm=TRUE)
    
    ## Actual Defect Density
    if (actualAM == 0) {
      DDDLDR <- 0
      DDDLDINSP <- 0
      DDCR <- 0
      DDCOMPILE <- 0
      DDINSP <- 0
      DDUT <- 0
      DDBIT <- 0
      DDST <- 0
      DDTOTAL <- 0
    } else {
      DDDLDR <- ADRDLDR*1000/actualAM
      DDDLDINSP <- ADRDLDINSP*1000/actualAM
      DDCR <- ADRCR*1000/actualAM
      DDCOMPILE <- ADRCOMPILE*1000/actualAM
      DDINSP <- ADRINSP*1000/actualAM
      DDUT <- ADRUT*1000/actualAM
      DDBIT <- ADRBIT*1000/actualAM
      DDST <- ADRST*1000/actualAM
      DDTOTAL <- ADRTOTAL*1000/actualAM
    }
    
    ## Plan Defect Injection and Removal Rates
    # Plan Defect Injection Rates
    ### WRN
    ### no plan defect information is currently available (2015.07.20)
    PDINJ_rate_SE      <- NoData
    PDINJ_rate_MM      <- NoData
    PDINJ_rate_LS      <- NoData
    PDINJ_rate_PLAN    <- NoData
    PDINJ_rate_REQ     <- NoData
    PDINJ_rate_STP     <- NoData
    PDINJ_rate_REQINSP <- NoData
    PDINJ_rate_HLD     <- NoData
    PDINJ_rate_ITP     <- NoData
    PDINJ_rate_HLDINSP <- NoData
    PDINJ_rate_DLD     <- NoData
    PDINJ_rate_DLDR    <- NoData
    PDINJ_rate_TD      <- NoData
    PDINJ_rate_DLDINSP <- NoData
    PDINJ_rate_CODE    <- NoData
    PDINJ_rate_CR      <- NoData
    PDINJ_rate_COMPILE <- NoData
    PDINJ_rate_INSP    <- NoData
    PDINJ_rate_UT      <- NoData
    PDINJ_rate_BIT     <- NoData
    PDINJ_rate_ST      <- NoData
    PDINJ_rate_AT      <- NoData
    PDINJ_rate_PL      <- NoData
    PDINJ_rate_DEPLOY  <- NoData
    PDINJ_rate_TOTAL   <- NoData
    
    # Plan Defect Removal Rates
    PDREM_rate_SE      <- NoData
    PDREM_rate_MM      <- NoData
    PDREM_rate_LS      <- NoData
    PDREM_rate_PLAN    <- NoData
    PDREM_rate_REQ     <- NoData
    PDREM_rate_STP     <- NoData
    PDREM_rate_REQINSP <- NoData
    PDREM_rate_HLD     <- NoData
    PDREM_rate_ITP     <- NoData
    PDREM_rate_HLDINSP <- NoData
    PDREM_rate_DLD     <- NoData
    PDREM_rate_DLDR    <- NoData
    PDREM_rate_TD      <- NoData
    PDREM_rate_DLDINSP <- NoData
    PDREM_rate_CODE    <- NoData
    PDREM_rate_CR      <- NoData 
    PDREM_rate_COMPILE <- NoData
    PDREM_rate_INSP    <- NoData
    PDREM_rate_UT      <- NoData
    PDREM_rate_BIT     <- NoData
    PDREM_rate_ST      <- NoData
    PDREM_rate_AT      <- NoData
    PDREM_rate_PL      <- NoData
    PDREM_rate_DEPLOY  <- NoData
    PDREM_rate_TOTAL   <- NoData
    
    # Actual Defect Injection and Removal Rates
    if (ATSE == 0) {
      ADINJ_rate_SE <- 0
      ADREM_rate_SE <- 0
    } else {
      ADINJ_rate_SE <- ADISE/ATSE*60
      ADREM_rate_SE <- ADRSE/ATSE*60
    }
    
    if (ATMM == 0) {
      ADINJ_rate_MM <- 0
      ADREM_rate_MM <- 0
    } else {
      ADINJ_rate_MM <- ADIMM/ATMM*60
      ADREM_rate_MM <- ADRMM/ATMM*60
    }
    
    if (ATLS == 0) {
      ADINJ_rate_LS <- 0
      ADREM_rate_LS <- 0
    } else {
      ADINJ_rate_LS <- ADILS/ATLS*60
      ADREM_rate_LS <- ADRLS/ATLS*60
    }
    
    if (ATPLAN == 0) {
      ADINJ_rate_PLAN <- 0
      ADREM_rate_PLAN <- 0
    } else {
      ADINJ_rate_PLAN <- ADIPLAN/ATPLAN*60
      ADREM_rate_PLAN <- ADRPLAN/ATPLAN*60
    }
  
    if (ATREQ == 0) {
      ADINJ_rate_REQ <- 0
      ADREM_rate_REQ <- 0
    } else {
      ADINJ_rate_REQ <- ADIREQ/ATREQ*60
      ADREM_rate_REQ <- ADRREQ/ATREQ*60
    }
    
    if (ATSTP == 0) {
      ADINJ_rate_STP <- 0
      ADREM_rate_STP <- 0
    } else {
      ADINJ_rate_STP <- ADISTP/ATSTP*60
      ADREM_rate_STP <- ADRSTP/ATSTP*60
    }
    
    if (ATREQINSP == 0) {
      ADINJ_rate_REQINSP <- 0
      ADREM_rate_REQINSP <- 0
    } else {
      ADINJ_rate_REQINSP <- ADIREQINSP/ATREQINSP*60
      ADREM_rate_REQINSP <- ADRREQINSP/ATREQINSP*60
    }
    
    if (ATHLD == 0) {
      ADINJ_rate_HLD <- 0
      ADREM_rate_HLD <- 0
    } else {
      ADINJ_rate_HLD <- ADIHLD/ATHLD*60
      ADREM_rate_HLD <- ADRHLD/ATHLD*60
    }
    
    if (ATITP == 0) {
      ADINJ_rate_ITP <- 0
      ADREM_rate_ITP <- 0
    } else {
      ADINJ_rate_ITP <- ADIITP/ATITP*60
      ADREM_rate_ITP <- ADRITP/ATITP*60
    }
    
    if (ATHLDINSP == 0) {
      ADINJ_rate_HLDINSP <- 0
      ADREM_rate_HLDINSP <- 0
    } else {
      ADINJ_rate_HLDINSP <- ADIHLDINSP/ATHLDINSP*60
      ADREM_rate_HLDINSP <- ADRHLDINSP/ATHLDINSP*60
    }
    
    if (ATDLD == 0) {
      ADINJ_rate_DLD <- 0
      ADREM_rate_DLD <- 0
    } else {
      ADINJ_rate_DLD <- ADIDLD/ATDLD*60
      ADREM_rate_DLD <- ADRDLD/ATDLD*60
    }
    
    if (ATDLDR == 0) {
      ADINJ_rate_DLDR <- 0
      ADREM_rate_DLDR <- 0
    } else {
      ADINJ_rate_DLDR <- ADIDLDR/ATDLDR*60
      ADREM_rate_DLDR <- ADRDLDR/ATDLDR*60
    }
    
    if (ATTD == 0) {
      ADINJ_rate_TD <- 0
      ADREM_rate_TD <- 0
    } else {
      ADINJ_rate_TD <- ADITD/ATTD*60
      ADREM_rate_TD <- ADRTD/ATTD*60
    }
    
    if (ATDLDINSP == 0) {
      ADINJ_rate_DLDINSP <- 0
      ADREM_rate_DLDINSP <- 0
    } else {
      ADINJ_rate_DLDINSP <- ADIDLDINSP/ATDLDINSP*60
      ADREM_rate_DLDINSP <- ADRDLDINSP/ATDLDINSP*60
    }
    
    if (ATCODE == 0) {
      ADINJ_rate_CODE <- 0
      ADREM_rate_CODE <- 0
    } else {
      ADINJ_rate_CODE <- ADICODE/ATCODE*60
      ADREM_rate_CODE <- ADRCODE/ATCODE*60
    }
    
    if (ATCR == 0) {
      ADINJ_rate_CR <- 0
      ADREM_rate_CR <- 0
    } else {
      ADINJ_rate_CR <- ADICR/ATCR*60
      ADREM_rate_CR <- ADRCR/ATCR*60
    }
    
    if (ATCOMPILE == 0) {
      ADINJ_rate_COMPILE <- 0
      ADREM_rate_COMPILE <- 0
    } else {
      ADINJ_rate_COMPILE <- ADICOMPILE/ATCOMPILE*60
      ADREM_rate_COMPILE <- ADRCOMPILE/ATCOMPILE*60
    }
    
    if (ATINSP == 0) {
      ADINJ_rate_INSP <- 0
      ADREM_rate_INSP <- 0
    } else {
      ADINJ_rate_INSP <- ADIINSP/ATINSP*60
      ADREM_rate_INSP <- ADRINSP/ATINSP*60
    }
    
    if (ATUT == 0) {
      ADINJ_rate_UT <- 0
      ADREM_rate_UT <- 0
    } else {
      ADINJ_rate_UT <- ADIUT/ATUT*60
      ADREM_rate_UT <- ADRUT/ATUT*60
    }
    
    if (ATBIT == 0) {
      ADINJ_rate_BIT <- 0
      ADREM_rate_BIT <- 0
    } else {
      ADINJ_rate_BIT <- ADIBIT/ATBIT*60
      ADREM_rate_BIT <- ADRBIT/ATBIT*60
    }
    
    if (ATST == 0) {
      ADINJ_rate_ST <- 0
      ADREM_rate_ST <- 0
    } else {
      ADINJ_rate_ST <- ADIST/ATST*60
      ADREM_rate_ST <- ADRST/ATST*60
    }
    
    if (ATAT == 0) {
      ADINJ_rate_AT <- 0
      ADREM_rate_AT <- 0
    } else {
      ADINJ_rate_AT <- ADIAT/ATAT*60
      ADREM_rate_AT <- ADRAT/ATAT*60
    }
    
    if (ATPL == 0) {
      ADINJ_rate_PL <- 0
      ADREM_rate_PL <- 0
    } else {
      ADINJ_rate_PL <- ADIPL/ATPL*60
      ADREM_rate_PL <- ADRPL/ATPL*60
    }
    
    if (ATDEPLOY == 0) {
      ADINJ_rate_DEPLOY <- 0
      ADREM_rate_DEPLOY <- 0
    } else {
      ADINJ_rate_DEPLOY <- ADIDEPLOY/ATDEPLOY*60
      ADREM_rate_DEPLOY <- ADRDEPLOY/ATDEPLOY*60
    }
    
    if (ATTOTAL == 0) {
      ADINJ_rate_TOTAL <- 0
      ADREM_rate_TOTAL <- 0
    } else {
      ADINJ_rate_TOTAL <- ADITOTAL/total_actual_minutes*60
      ADREM_rate_TOTAL <- ADRTOTAL/total_actual_minutes*60
    }


    
    ## Development Phase Effort Ratio
    if (ATREQ == 0) {
      TRREQINSP2REQ <- 0
    } else {
      TRREQINSP2REQ <- ATREQINSP/ATREQ
    }
    
    if (ATHLD == 0) {
      TRHLDINSP2HLD <- 0
    } else {
      TRHLDINSP2HLD <- ATHLDINSP/ATHLD
    }
    
    if (ATDLD == 0) {
      TRDLDINSP2DLD <- 0
    } else {
      TRDLDINSP2DLD <- ATDLDINSP/ATDLD
    }
    
    if (ATDLD == 0) {
      TRDLDR2DLD <- 0
    } else {
      TRDLDR2DLD <- ATDLDR/ATDLD
    }
    
    if (ATCODE == 0) {
      TRCODEINSP2CODE <- 0
    } else {
      TRCODEINSP2CODE <- ATINSP/ATCODE
    }
    
    if (ATCODE == 0) {
      TRCR2CODE <- 0
    } else {
      TRCR2CODE <- ATCR/ATCODE
    }
    
    if (ATCODE == 0) {
      TRDESGN2CODE <- 0
    } else {
      TRDESGN2CODE <- (ATHLD+ATDLD)/ATCODE
    }
    
    ## Defect Removal Phase Yield Parameters
    # Plan Defect Removal Phase Yield Parameters
    # WRN Plan defect data is not available in the warehouse
    PDREM_YIELD_SE      <- NoData
    PDREM_YIELD_MM      <- NoData
    PDREM_YIELD_LS      <- NoData
    PDREM_YIELD_PLAN    <- NoData
    PDREM_YIELD_REQ     <- NoData
    PDREM_YIELD_STP     <- NoData
    PDREM_YIELD_REQR    <- NoData
    PDREM_YIELD_REQINSP <- NoData
    PDREM_YIELD_HLD     <- NoData
    PDREM_YIELD_ITP     <- NoData
    PDREM_YIELD_HLDR    <- NoData
    PDREM_YIELD_HLDINSP <- NoData
    PDREM_YIELD_DLD     <- NoData
    PDREM_YIELD_DLDR    <- NoData
    PDREM_YIELD_TD      <- NoData
    PDREM_YIELD_DLDINSP <- NoData
    PDREM_YIELD_CODE    <- NoData
    PDREM_YIELD_CR      <- NoData
    PDREM_YIELD_COMPILE <- NoData
    PDREM_YIELD_INSP    <- NoData
    PDREM_YIELD_UT      <- NoData
    PDREM_YIELD_BIT     <- NoData
    PDREM_YIELD_ST      <- NoData
    PDREM_YIELD_AT      <- NoData
    PDREM_YIELD_PL      <- NoData
    PDREM_YIELD_DEPLOY  <- NoData
    
    # Actual Defect Removal Phase Yield Parameters
    #wrn, these onlyh work with the TSP process
    #
    sum_defect_se      <- ADISE-ADRSE
    sum_defect_mm      <- sum_defect_se+ADIMM-ADRMM
    sum_defect_ls      <- sum_defect_mm+ADILS-ADRLS
    sum_defect_plan    <- sum_defect_ls+ADIPLAN-ADRPLAN
    sum_defect_req     <- sum_defect_plan+ADIREQ-ADRREQ
    sum_defect_stp     <- sum_defect_req+ADISTP-ADRSTP
    sum_defect_reqr    <- sum_defect_stp+ADIREQR-ADRREQR
    sum_defect_reqinsp <- sum_defect_reqr+ADIREQINSP-ADRREQINSP
    sum_defect_hld     <- sum_defect_reqinsp+ADIHLD-ADRHLD
    sum_defect_itp     <- sum_defect_hld+ADIITP-ADRITP
    sum_defect_hldr    <- sum_defect_itp+ADIHLDR-ADRHLDR
    sum_defect_hldinsp <- sum_defect_hldr+ADIHLDINSP-ADRHLDINSP
    sum_defect_dld     <- sum_defect_hldinsp+ADIDLD-ADRDLD
    sum_defect_dldr    <- sum_defect_dld+ADIDLDR-ADRDLDR
    sum_defect_td      <- sum_defect_dldr+ADITD-ADRTD
    sum_defect_dldinsp <- sum_defect_td+ADRDLDINSP-ADRDLDINSP
    sum_defect_code    <- sum_defect_dldinsp+ADICODE-ADRCODE
    sum_defect_cr      <- sum_defect_code+ADICR-ADRCR
    sum_defect_compile <- sum_defect_cr+ADICOMPILE-ADRCOMPILE
    sum_defect_insp    <- sum_defect_compile+ADIINSP-ADRINSP
    sum_defect_ut      <- sum_defect_insp+ADIUT-ADRUT
    sum_defect_bit     <- sum_defect_ut+ADIBIT-ADRBIT
    sum_defect_st      <- sum_defect_bit+ADIST-ADRST
    sum_defect_at      <- sum_defect_st+ADIAT-ADRAT
    sum_defect_pl      <- sum_defect_at+ADIPL-ADRPL
    sum_defect_deploy  <- sum_defect_pl+ADIDEPLOY-ADRDEPLOY
    
    #if (length(sum_defect_se) == 0 || ADISE == 0) {
    #if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Sys Eng"]) == 0 || ADISE == 0) {
    if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Sys Eng"]) == 0) {
      ADREM_YIELD_SE <- NA
    } else {
      ADREM_YIELD_SE <- ADRSE*100/ADISE
    }
    
    #if (length(sum_defect_mm) == 0 || (ADIMM+sum_defect_se) == 0) {
    #if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Misc"]) == 0 || (ADIMM+sum_defect_se) == 0) {
    if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Misc"]) == 0) {
      ADREM_YIELD_MM <- NA
    } else {
      ADREM_YIELD_MM <- ADRMM*100/(ADIMM+sum_defect_se)
      #ADREM_YIELD_MM <- (ADRMM-ADIMM)*100/sum_defect_se
      #ADREM_YIELD_MM <- ADRMM*100/ADIMM
    }
    
    #if (length(sum_defect_ls) == 0 || (ADILS+sum_defect_mm) == 0) {
    #if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="StRategy"]) == 0 || (ADILS+sum_defect_mm) == 0) {
    if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="StRategy"]) == 0) {
      ADREM_YIELD_LS <- NA
    } else {
      ADREM_YIELD_LS <- ADRLS*100/(ADILS+sum_defect_mm)
      #ADREM_YIELD_LS <- (ADRLS-ADILS)*100/sum_defect_mm
      #ADREM_YIELD_LS <- ADRLS*100/ADILS
    }
    
    #if (length(sum_defect_plan) == 0 || (ADIPLAN+sum_defect_ls) == 0) {
    #if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Planning"]) == 0 || (ADIPLAN+sum_defect_ls) == 0) {
    if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Planning"]) == 0) {
      ADREM_YIELD_PLAN <- NA
    } else {
      ADREM_YIELD_PLAN <- ADRPLAN*100/(ADIPLAN+sum_defect_ls)
      #ADREM_YIELD_PLAN <- (ADRPLAN-ADIPLAN)*100/sum_defect_ls
      #ADREM_YIELD_PLAN <- ADRPLAN*100/ADIPLAN
    }
    
    #if (length(sum_defect_req) == 0 || (ADIREQ+sum_defect_plan) == 0) {
    #if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Reqts"]) == 0 || (ADIREQ+sum_defect_plan) == 0) {
    if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Reqts"]) == 0) {
      ADREM_YIELD_REQ <- NA
    } else {
      ADREM_YIELD_REQ <- ADRREQ*100/(ADIREQ+sum_defect_plan)
      #ADREM_YIELD_REQ <- (ADRREQ-ADIREQ)*100/sum_defect_plan
      #ADREM_YIELD_REQ <- ADRREQ*100/ADIREQ
    }

    #if (length(sum_defect_stp) == 0 || (ADISTP+sum_defect_req) == 0) {
    #if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Sys Test Plan"]) == 0 || (ADISTP+sum_defect_req) == 0) {
    if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Sys Test Plan"]) == 0) {
      ADREM_YIELD_STP <- NA
    } else {
      ADREM_YIELD_STP <- ADRSTP*100/(ADISTP+sum_defect_req)
      #ADREM_YIELD_STP <- (ADRSTP-ADISTP)*100/sum_defect_req
      #ADREM_YIELD_STP <- ADRSTP*100/ADISTP
    }

    #if (length(sum_defect_reqr) == 0 || (ADIREQR+sum_defect_stp) == 0) {
    #if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Reqts Review"]) == 0 || (ADIREQR+sum_defect_stp) == 0) {
    if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Reqts Review"]) == 0) {
      ADREM_YIELD_REQR <- NA
    } else {
      ADREM_YIELD_REQR <- ADRREQR*100/(ADIREQR+sum_defect_stp)
      #ADREM_YIELD_REQR <- (ADRREQR-ADIREQ)*100/sum_defect_stp
      #ADREM_YIELD_REQR <- ADRREQR*100/ADIREQR
    }
    
    #if (length(sum_defect_reqinsp) == 0 || (ADIREQINSP+sum_defect_reqr) == 0) {
    #if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Reqts Inspect"]) == 0 || is.null(ADIREQINSP+sum_defect_reqr) || (ADIREQINSP+sum_defect_reqr) == 0) {
    if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Reqts Inspect"]) == 0) {
      ADREM_YIELD_REQINSP <- NA
    } else {
      ADREM_YIELD_REQINSP <- ADRREQINSP*100/(ADIREQINSP+sum_defect_reqr)
      #ADREM_YIELD_REQINSP <- (ADRREQINSP-ADIREQINSP)*100/sum_defect_reqr
      #ADREM_YIELD_REQINSP <- ADRREQINSP*100/ADIREQINSP
    }

    #if (length(sum_defect_hld) == 0 || (ADIHLD+sum_defect_reqinsp) == 0) {
    #if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="HLD"]) == 0 || (ADIHLD+sum_defect_reqinsp) == 0) {
    if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="HLD"]) == 0) {
      ADREM_YIELD_HLD <- NA
    } else {
      ADREM_YIELD_HLD <- ADRHLD*100/(ADIHLD+sum_defect_reqinsp)
      #ADREM_YIELD_HLD <- (ADRHLD-ADIHLD)*100/sum_defect_reqinsp
      #ADREM_YIELD_HLD <- ADRHLD*100/ADIHLD
    }

    #if (length(sum_defect_itp) == 0 || (ADIITP+sum_defect_hld) == 0) {
    #if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Int Test Plan"]) == 0 || (ADIITP+sum_defect_hld) == 0) {
    if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Int Test Plan"]) == 0) {
      ADREM_YIELD_ITP <- NA
    } else {
      ADREM_YIELD_ITP <- ADRITP*100/(ADIITP+sum_defect_hld)
      #ADREM_YIELD_ITP <- (ADRITP-ADIITP)*100/sum_defect_hld
      #ADREM_YIELD_ITP <- ADRITP*100/ADIITP
    }

    #if (length(sum_defect_hldr) == 0 || (ADIHLDR+sum_defect_itp) == 0) {
    #if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="HLD Review"]) == 0 || (ADIHLDR+sum_defect_itp) == 0) {
    if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="HLD Review"]) == 0) {
      ADREM_YIELD_HLDR <- NA
    } else {
      ADREM_YIELD_HLDR <- ADRHLDR*100/(ADIHLDR+sum_defect_itp)
      #ADREM_YIELD_HLDR <- (ADRHLDR-ADIHLDR)*100/sum_defect_itp
      #ADREM_YIELD_HLDR <- ADRHLDR*100/ADIHLDR
    }
    
    #if (length(sum_defect_hldinsp) == 0 || (ADIHLDINSP+sum_defect_hldr) == 0) {
    #if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="HLD Inspect"]) == 0 || (ADIHLDINSP+sum_defect_hldr) == 0) {
    if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="HLD Inspect"]) == 0) {
      ADREM_YIELD_HLDINSP <- NA
    } else {
      ADREM_YIELD_HLDINSP <- ADRHLDINSP*100/(ADIHLDINSP+sum_defect_hldr)
      #ADREM_YIELD_HLDINSP <- (ADRHLDINSP-ADIHLDINSP)*100/sum_defect_hldr
      #ADREM_YIELD_HLDINSP <- ADRHLDINSP*100/ADIHLDINSP
    }
        
    #if (length(sum_defect_dld) == 0 || (ADIDLD+sum_defect_hldinsp) == 0) {
    #if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Design"]) == 0 || (ADIDLD+sum_defect_hldinsp) == 0) {
    if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Design"]) == 0) {
      ADREM_YIELD_DLD <- NA
    } else {
      ADREM_YIELD_DLD <- ADRDLD*100/(ADIDLD+sum_defect_hldinsp)
      #ADREM_YIELD_DLD <- (ADRDLD-ADIDLD)*100/sum_defect_hldinsp
      #ADREM_YIELD_DLD <- ADRDLD*100/ADIDLD
    }
    
    #if (length(sum_defect_dldr) == 0 || (ADIDLDR+sum_defect_dld) == 0) {
    #if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Design Review"]) == 0 || (ADIDLDR+sum_defect_dld) == 0) {
    if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Design Review"]) == 0) {
      ADREM_YIELD_DLDR <- NA
    } else {
      ADREM_YIELD_DLDR <- ADRDLDR*100/(ADIDLDR+sum_defect_dld)
      #ADREM_YIELD_DLDR <- (ADRDLDR-ADIDLDR)*100/sum_defect_dld
      #ADREM_YIELD_DLDR <- ADRDLDR*100/ADIDLDR
    }
    
    #if (length(sum_defect_td) == 0 || (ADITD+sum_defect_dldr) == 0) {
    #if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Test Devel"]) == 0 || (ADITD+sum_defect_dldr) == 0) {
    if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Test Devel"]) == 0) {
      ADREM_YIELD_TD <- NA
    } else {
      ADREM_YIELD_TD <- ADRTD*100/(ADITD+sum_defect_dldr)
      #ADREM_YIELD_TD <- (ADRTD-ADITD)*100/sum_defect_dldr
      #ADREM_YIELD_TD <- ADRTD*100/ADITD
    }
    
    #if (length(sum_defect_dldinsp) == 0 || (ADIDLDINSP+sum_defect_td) == 0) {
    #if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Design Inspect"]) == 0 || (ADIDLDINSP+sum_defect_td) == 0) {
    if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Design Inspect"]) == 0) {
      ADREM_YIELD_DLDINSP <- NA
    } else {
      ADREM_YIELD_DLDINSP <- ADRDLDINSP*100/(ADIDLDINSP+sum_defect_td)
      #ADREM_YIELD_DLDINSP <- (ADRDLDINSP-ADIDLDINSP)*100/sum_defect_td
      #ADREM_YIELD_DLDINSP <- ADRDLDINSP*100/ADIDLDINSP
    }
    
    #if (length(sum_defect_code) == 0 || (ADICODE+sum_defect_dldinsp) == 0) {
    #if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Code"]) == 0 || (ADICODE+sum_defect_dldinsp) == 0) {
    if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Code"]) == 0) {
      ADREM_YIELD_CODE <- NA
    } else {
      ADREM_YIELD_CODE <- ADRCODE*100/(ADICODE+sum_defect_dldinsp)
      #ADREM_YIELD_CODE <- (ADRCODE-ADICODE)*100/sum_defect_dldinsp
      #ADREM_YIELD_CODE <- ADRCODE*100/ADICODE
    }
    
    #if (length(sum_defect_cr) == 0 || (ADICR+sum_defect_code) == 0) {
    #if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Code Review"]) == 0 || (ADICR+sum_defect_code) == 0) {
    if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Code Review"]) == 0) {
      ADREM_YIELD_CR <- NA
    } else {
      ADREM_YIELD_CR <- ADRCR*100/(ADICR+sum_defect_code)
      #ADREM_YIELD_CR <- (ADRCR-ADICR)*100/sum_defect_code
      #ADREM_YIELD_CR <- ADRCR*100/ADICR
    }
    
    #if (length(sum_defect_compile) == 0 || (ADICOMPILE+sum_defect_cr) == 0) {
    #if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Compile"]) == 0 || (ADICOMPILE+sum_defect_cr) == 0) {
    if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Compile"]) == 0) {
      ADREM_YIELD_COMPILE <- NA
    } else {
      ADREM_YIELD_COMPILE <- ADRCOMPILE*100/(ADICOMPILE+sum_defect_cr)
      #ADREM_YIELD_COMPILE <- (ADRCOMPILE-ADICOMPILE)*100/sum_defect_cr
      #ADREM_YIELD_COMPILE <- ADRCOMPILE*100/ADICOMPILE
    }
    
    #if (length(sum_defect_insp) == 0 || (ADIINSP+sum_defect_compile) == 0) {
    #if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Code Inspect"]) == 0 || (ADIINSP+sum_defect_compile) == 0) {
    if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Code Inspect"]) == 0) {
      ADREM_YIELD_INSP <- NA
    } else {
      ADREM_YIELD_INSP <- ADRINSP*100/(ADIINSP+sum_defect_compile)
      #ADREM_YIELD_INSP <- (ADRINSP-ADIINSP)*100/sum_defect_compile
      #ADREM_YIELD_INSP <- ADRINSP*100/ADIINSP
    }
    
    #if (length(sum_defect_ut) == 0 || (ADIUT+sum_defect_insp) == 0) {
    #if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Test"]) == 0 || (ADIUT+sum_defect_insp) == 0) {
    if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Test"]) == 0) {
      ADREM_YIELD_UT <- NA
    } else {
      ADREM_YIELD_UT <- ADRUT*100/(ADIUT+sum_defect_insp)
      #ADREM_YIELD_UT <- (ADRUT-ADIUT)*100/sum_defect_insp
      #ADREM_YIELD_UT <- ADRUT*100/ADIUT
    }
    
    #if (length(sum_defect_bit) == 0 || (ADIBIT+sum_defect_ut) == 0) {
    #if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Int Test"]) == 0 || (ADIBIT+sum_defect_ut) == 0) {
    if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Int Test"]) == 0) {
      ADREM_YIELD_BIT <- NA
    } else {
      ADREM_YIELD_BIT <- ADRBIT*100/(ADIBIT+sum_defect_ut)
      #ADREM_YIELD_BIT <- (ADRBIT-ADIBIT)*100/sum_defect_ut
      #ADREM_YIELD_BIT <- ADRBIT*100/ADIBIT
    }
    
    #if (length(sum_defect_st) == 0 || (ADIST+sum_defect_bit) == 0) {
    #if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Sys Test"]) == 0 || (ADIST+sum_defect_bit) == 0) {
    if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Sys Test"]) == 0) {
      ADREM_YIELD_ST <- NA
    } else {
      ADREM_YIELD_ST <- ADRST*100/(ADIST+sum_defect_bit)
      #ADREM_YIELD_ST <- (ADRST-ADIST)*100/sum_defect_bit
      #ADREM_YIELD_ST <- ADRST*100/ADIST
    }
    
    #if (length(sum_defect_at) == 0 || (ADIAT+sum_defect_st) == 0) {
    #if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Accept Test"]) == 0 || (ADIAT+sum_defect_st) == 0) {
    if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Accept Test"]) == 0) {
      ADREM_YIELD_AT <- NA
    } else {
      ADREM_YIELD_AT <- ADRAT*100/(ADIAT+sum_defect_st)
      #ADREM_YIELD_AT <- (ADRAT-ADIAT)*100/sum_defect_st
      #ADREM_YIELD_AT <- ADRAT*100/ADIAT
    }
    
    #if (length(sum_defect_pl) == 0 || (ADIPL+ADIDEPLOY+sum_defect_at) == 0) {
    #if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Product Life"]) == 0 && length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Deployment"]) == 0 || (ADIPL+ADIDEPLOY+sum_defect_at) == 0) {
    if (length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Product Life"]) == 0 && length(time_log_info$phase_short_name[time_log_info$phase_short_name=="Deployment"]) == 0) {
      ADREM_YIELD_PL <- NA
    } else {
      ADREM_YIELD_PL <- (ADRPL+ADRDEPLOY)*100/(ADIPL+ADIDEPLOY+sum_defect_at)
      #ADREM_YIELD_PL <- (ADRPL+ADRDEPLOY-ADIPL-ADIDEPLOY)*100/sum_defect_at
      #ADREM_YIELD_PL <- (ADRPL+ADRDEPLOY)*100/(ADIPL+ADIDEPLOY)
    }
    
    ## Plan Defect Removal Effort Per Defect in Test Phaess [Hr/Defect]
    PREMRate_DEFECT_rate_UT  <- NoData
    PREMRate_DEFECT_rate_BIT <- NoData
    PREMRate_DEFECT_rate_ST  <- NoData
    PREMRate_DEFECT_rate_AT  <- NoData
    PREMRate_DEFECT_rate_PL  <- NoData
     
    ## Plan Zero Defect Effort Phases [Hr/Defect]
    PZero_DEFECT_rate_UT  <- NoData
    PZero_DEFECT_rate_BIT <- NoData
    PZero_DEFECT_rate_ST  <- NoData
    PZero_DEFECT_rate_AT  <- NoData
    PZero_DEFECT_rate_PL  <- NoData
    
    ## Size and Estimation Performance
    AM_Size_Estimation_Accuracy <- actualAM/planAM
    Effort_Estimation_Accuracy  <- total_actual_minutes/total_plan_minutes
    
    ## Calculate COA,COF,and COQ
    COA_set <- subset(time_info, phase_type=="Appraisal")
    COF_set <- subset(time_info, phase_type=="Failure")
    construction_set <- subset(time_info, phase_type=="Construction")
    
    # Plan COA, COF, and COQ
    plan_COA                 <- sum(COA_set$sum_plan_time, na.rm=TRUE)/60
    plan_COF                 <- sum(COF_set$sum_plan_time, na.rm=TRUE)/60
    plan_COQ                 <- plan_COA+plan_COF
    
    plan_construction_effort <- sum(construction_set$sum_plan_time, na.rm=TRUE)/60
    total_plan_effort        <- sum(time_info$sum_plan_time, na.rm=TRUE)/60

    plan_AFratio     <- plan_COA/plan_COF
    plan_ADevratio   <- plan_COA/plan_construction_effort
    plan_ATotalratio <- plan_COA/total_plan_effort
    plan_CTotalratio <- plan_construction_effort/total_plan_effort
    plan_FTotalratio <- plan_COF/total_plan_effort
      
    # Actual COA, COF, and COQ
    actual_COA <- sum(COA_set$sum_actual_time, na.rm=TRUE)/60
    actual_COF <- sum(COF_set$sum_actual_time, na.rm=TRUE)/60
    actual_COQ <- actual_COA+actual_COF
    actual_construction_effort <- sum(construction_set$sum_actual_time, na.rm=TRUE)/60
    total_actual_effort        <- sum(time_info$sum_actual_time, na.rm=TRUE)/60
  
    COQPctFailure <- actual_COF/actual_construction_effort
    COQPct        <- actual_COQ/actual_construction_effort
    
    actual_COAratio_size <- actual_COA/actualAM
    actual_COFratio_size <- actual_COF/actualAM
    actual_COQratio_size <- actual_COQ/actualAM
    
    actual_AFratio       <- actual_COA/actual_COF
    actual_ADevratio     <- actual_COA/actual_construction_effort
    actual_ATotalratio   <- actual_COA/total_actual_effort
    actual_CTotalratio   <- actual_construction_effort/total_actual_effort
    actual_FTotalratio   <- actual_COF/total_actual_effort
    actual_ACration      <- actual_COA/actual_construction_effort  # this is same as ADevratio
    
    # COA,COF, and COQ within DLD through UT
    COAinDLDUT_set <- subset(time_info, phase_short_name=="Design Review" | phase_short_name=="Design Inspect" | phase_short_name=="Code Review" | phase_short_name=="Code Inspect")
    COFinDLDUT_set <- subset(time_info, phase_short_name=="Compile" | phase_short_name=="Test")
    
    COAinDLDUT <- sum(COAinDLDUT_set$sum_actual_time, na.rm=TRUE)/60
    COFinDLDUT <- sum(COFinDLDUT_set$sum_actual_time, na.rm=TRUE)/60
    COQinDLDUT <- COAinDLDUT+COFinDLDUT
      
    COAinDLDUTratio_size <- COAinDLDUT/actualAM
    COFinDLDUTratio_size <- COFinDLDUT/actualAM
    COQinDLDUTratio_size <- COQinDLDUT/actualAM
    
    # Process Quality  (needs to be put into a data structure with phases dependent upon the process)
    actual_DLDtoUT        <- ATDLD/ATUT
    actual_CodetoUT       <- ATCODE/ATUT
    actual_DLDCodetoUT    <- (ATDLD+ATCODE)/ATUT
    actual_DLDtoCode      <- ATDLD/ATCODE
    actual_ApprtoConst    <- (ATDLDR+ATDLDINSP+ATCR+ATINSP)/(ATDLD+ATCODE)
    actual_DesignApptoDLD <- (ATDLDR+ATDLDINSP)/ATDLD
    actual_CodeApptoCode  <- (ATCR+ATINSP)/ATCODE
    actual_SizetoCR       <- actualAM*60/ATCR
    actual_SizetoINSP     <- actualAM*60/ATINSP
    actual_SizetoCodeApp  <- actualAM*60/(ATCR+ATINSP)
    
    # Production Rate  
    production_rate_const <- actualAM/actual_construction_effort
    plan_production_rate_total     <-   planAM/total_plan_effort
    actual_production_rate_total   <- actualAM/total_actual_effort
  
    ## Calculate correlation and parameters of regression line
    if (length(ev_actual_complete_info$phase_short_name[!is.na(ev_actual_complete_info$phase_short_name)]) == 0 || length(ev_actual_complete_info$task_plan_time_minutes) == 0 || length(ev_actual_complete_info$task_actual_time_minutes) == 0) {
      R2_phase_effort       <- NoData
      slope_effort_by_phase <- NoData
    } else {
      # aggregated phase effort correlation by each unit
      dataset_effort_by_phase <- aggregate(list(sum_plan_time=ev_actual_complete_info$task_plan_time_minutes, sum_actual_time=ev_actual_complete_info$task_actual_time_minutes), by=list(phase_short_name=ev_actual_complete_info$phase_short_name), FUN=sum, na.rm=TRUE)
      R2_phase_effort <- cor(dataset_effort_by_phase$sum_plan_time[!is.na(dataset_effort_by_phase$sum_plan_time)], dataset_effort_by_phase$sum_actual_time[!is.na(dataset_effort_by_phase$sum_actual_time)])

      # regression line for aggregated phase effort
      if (length(unique(dataset_effort_by_phase$sum_plan_time)) > 1 && length(unique(dataset_effort_by_phase$sum_actual_time)) > 1) {
        regression_effort_by_phase <- lm(sum_actual_time~sum_plan_time, data=dataset_effort_by_phase)
        slope_effort_by_phase <- summary(regression_effort_by_phase)$coefficients["sum_plan_time","Estimate"]
      } else {
        slope_effort_by_phase <- NoData
      }
    }
    
    # task effort correlation by each unit
    
    if (length(ev_actual_complete_info$task_plan_time_minutes) == 0 || length(ev_actual_complete_info$task_actual_time_minutes) == 0) {
      R2_task_effort <- NoData
    } else {
#      R2_task_effort <- cor(ev_actual_complete_info$task_plan_time_minutes, ev_actual_complete_info$task_actual_time_minutes)
      R2_task_effort <- cor(ev_actual_complete_info$task_plan_time_minutes, ev_actual_complete_info$task_actual_time_minutes)
      regress_task_effort <- lm(task_plan_time_minutes~task_actual_time_minutes,data=ev_actual_complete_info)
      slope_task_effort   <- summary(regress_task_effort)$coefficients["task_actual_time_minutes", "Estimate"]
    }

    # aggregated wbs element effort correlation by project
    
    if (length(ev_actual_complete_info$wbs_element_key) == 0) {
      R2_wbs_effort <- NoData
    } else {
      dataset_effort_by_wbs <- aggregate(list(sum_plan_time=ev_actual_complete_info$task_plan_time_minutes, sum_actual_time=ev_actual_complete_info$task_actual_time_minutes), by=list(wbs_element_key=ev_actual_complete_info$wbs_element_key), FUN=sum, na.rm=TRUE)
      R2_wbs_effort <- cor(dataset_effort_by_wbs$sum_plan_time, dataset_effort_by_wbs$sum_actual_time)
      regress_wbs_effort <-lm(sum_plan_time~sum_actual_time,data=dataset_effort_by_wbs)
      slope_wbs_effort   <- summary(regress_wbs_effort)$coefficients["sum_actual_time", "Estimate"]
    }

    ## Phase performance
    ## performance of appraisal phases
    dataset_appraisal <- subset(ev_actual_complete_info, phase_type=="Appraisal")
    dataset_failure   <- subset(ev_actual_complete_info, phase_type=="Failure")
    
    # Count appraisal tasks by each unit
    
    count_appraisal <- length(dataset_appraisal$phase_type)
    count_failure   <- length(dataset_failure$phase_type)
    
    # Count appraisal tasks with >0 time
    dataset_appraisal_with_time <- subset(dataset_appraisal, task_actual_time_minutes>0)   
    dataset_failure_with_time   <- subset(dataset_failure, task_actual_time_minutes>0)   
    count_appraisal_with_time   <- length(dataset_appraisal_with_time$task_actual_time_minutes)
    count_failure_with_time     <- length(dataset_failure_with_time$task_actual_time_minutes)
 
    
    # Count appraisal tasks with >0 defects found
    dataset_appraisal_with_defects <- subset(dataset_appraisal, defects_found>0)
    count_appraisal_with_defects   <- length(dataset_appraisal_with_defects$defects_found)
    dataset_failure_with_defects   <- subset(dataset_failure, defects_found>0)
    count_failure_with_defects     <- length(dataset_failure_with_defects$defects_found)
    #
    # WRN additions to count appraisal and failure find Rates
    plan_appraisal_time_tasks_started <- sum(dataset_appraisal_with_time$task_plan_time_minutes)   ## wrn
    actual_appraisal_time             <- sum(dataset_appraisal_with_time$task_actual_time_minutes) ## wrn
    appraisal_defects                 <- sum(dataset_appraisal_with_defects$defects_found)            ## wrn
    failure_defects                   <- sum(dataset_failure_with_defects$defects_found)            ## wrn
    total_defects                     <- sum(ev_actual_complete_info$defects_found, na.rm = TRUE)
    if( actual_appraisal_time >0){
      appraisal_defect_removal_rate <- (appraisal_defects/actual_appraisal_time)*60.
    }else{
      appraisal_defect_removal_rate  <- 0.0
      }
   
    ## performance of appraisal phases
    dataset_failure <- subset(ev_actual_complete_info, phase_type=="Failure")
    # Count failure tasks by each unit
    count_failure <- length(dataset_failure$phase_type)
    
    ####### failure task analysis
    # Count failure tasks with defects found
    dataset_failure_with_defects <- subset(dataset_failure, defects_found>0)
    count_failure_with_defects   <- length(dataset_failure_with_defects$defects_found)
    
    # Count appraisal tasks with 0 time
    dataset_appraisal_with_time  <- subset(dataset_appraisal, task_actual_time_minutes>0)   
    dataset_failure_with_time    <- subset(dataset_failure,   task_actual_time_minutes>0)
    
    #failure find Rates
    count_failure_with_time         <- length(dataset_failure_with_time$task_actual_time_minutes)
    plan_failure_time_tasks_started <-    sum(dataset_failure_with_time$task_plan_time_minutes)    ## wrn
    actual_failure_time             <-    sum(dataset_failure_with_time$task_actual_time_minutes)  ## wrn
    failure_defects                 <-    sum(dataset_failure_with_defects$defects_found)            ## wrn
    if( actual_failure_time >0){
      failure_defect_removal_rate <- (failure_defects/actual_failure_time)*60.
    }else{
      failure_defect_removal_rate  <- 0.0
    }
    
    # Count failure tasks with 0 defects
    dataset_failure_with_zero_defects <- subset(dataset_failure, defects_found=0) 
    count_failure_with_zero_defects   <- length(dataset_failure_with_zero_defects$defects_found)
    
 
   total_appraisal_defects  <- sum(dataset_appraisal_with_defects$defects_found, na.rm = TRUE)
   total_failure_defects    <- sum(dataset_failure_with_time$defects_found, na.rm = TRUE)
   total_defects            <- sum(ev_actual_complete_info$defects_found, na.rm = TRUE)

   PCTDREM_appraisal    <- 0.0            
   PCTDREM_failure      <- 0.0
   ADREM_rate_appraisal <- 0.0
   ADREM_rate_failure   <- 0.0
   ADREM_rate_AF        <- 0.0
   ADREM_Ratio_AF       <- 0.0

   plan_man_months_FTE     <-  0.0
   actual_man_months_FTE   <-  0.0
   man_months_FTE_variance <-  0.0
   man_months_FTE_CPI      <-  0.0


   if(actual_COA>0.0)               {ADREM_rate_appraisal <- ((appraisal_defects)/actual_COA)}
   if(actual_COF>0.0)               {ADREM_rate_failure   <-  (failure_defects/actual_COF)}
   if((actual_COA+actual_COF)>0.0)  {ADREM_rate_AF        <-  (appraisal_defects+failure_defects)/(actual_COA+actual_COF)}
   if(ADREM_rate_failure>0)         {ADREM_Ratio_AF       <-  (ADREM_rate_appraisal/ADREM_rate_failure)}   
                        
   if(total_defects>0){
     PCTDREM_appraisal    <- (appraisal_defects/total_defects)            
     PCTDREM_failure      <- ( failure_defects/total_defects)
    }

###
   ### hold this, I want to look at planned and actual time in failure phases that find and do not find defects
   ##  are low defect tasks more predictable? 
   ###
   
   ###
   ### write a csv file with the following parameters
   # score score for (ACR, plan review, review_effective score, phase estimation score, wbs estimation score, )
   
   ACRatio_score                 <- min(2*actual_ACration,1.25)
   PCRatio_score                 <- min(2*plan_ADevratio,1.25)
   phase_effort_estimation_score <- R2_phase_effort
   wbs_estimation_score          <- R2_wbs_effort
   appraisal_effective_score     <- max(1.25,appraisal_defect_removal_rate /2.5)
   if(is.nan(AM_Size_Estimation_Accuracy)){size_accuracy_score=0 
    } else {
        if(AM_Size_Estimation_Accuracy>1){
          size_accuracy_score = 1/AM_Size_Estimation_Accuracy
        } else {
          size_accuracy_score = AM_Size_Estimation_Accuracy }
    }
   if(is.nan(Effort_Estimation_Accuracy)){effort_accuracy_score=0 
   } else {
     if(Effort_Estimation_Accuracy>1){
       effort_accuracy_score = 1/Effort_Estimation_Accuracy
     } else {
       effort_accuracy_score  = Effort_Estimation_Accuracy   }
     }
   team_process_score            <- mean( c(ACRatio_score,PCRatio_score, phase_effort_estimation_score, wbs_estimation_score , appraisal_effective_score, size_accuracy_score, effort_accuracy_score) )
     
     
    # execute preprocessing for output  
    if (paste(phase_vector, collapse=":") == "") {
      main_phases  <- NoData
      phase_top    <- NoData
      phase_bottom <- NoData
      phase_top_and_bottom <- NoData
    } else {
        main_phases          <- paste(phase_vector, collapse=":")
        phase_top            <- phase_vector[1]
        phase_bottom         <- phase_vector[length(phase_vector)]
        phase_top_and_bottom <- paste(phase_top, phase_bottom, sep=":")
    }
  
    ## Output CSV data which is selected
    # Output CSV data for fact sheet
    increment_fact <- 1
    
    for (fact_data_att in fact_data_att_list$attribute) {
      if (increment_fact < length(fact_data_att_list$attribute)) {
        writeLines(paste(get(fact_data_att)), out_fact, sep=",")  
      } else {
        writeLines(paste(get(fact_data_att)), out_fact, sep="\n")  ## last one end with newline
      }
      increment_fact <- increment_fact + 1
    }
    
    # Output CSV data for fideity sheet
    increment_fidelity <- 1
    
    for (fidelity_data_att in fidelity_data_att_list$attribute) {
      if (increment_fidelity < length(fidelity_data_att_list$attribute)) {
        writeLines(paste(get(fidelity_data_att)), out_fidelity, sep=",")  
      } else {
        writeLines(paste(get(fidelity_data_att)), out_fidelity, sep="\n")
      }
      increment_fidelity <- increment_fidelity + 1
    }
  }
  #close file
  close(out_fact)
  close(out_fidelity)
}