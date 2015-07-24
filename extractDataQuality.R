#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Extract the data quality sheet
# 2015/2/22
# Yasutaka Shirai

source("getDQDataFrame.R")

extractDataQuality <- function(con, currentDirectory)
{
  
  # Get project data from SEMPR
  tab_project_info_layer<-dbGetQuery(con, "select project.project_key,quote(project_name) as project_name, parent_project_key, project_pattern from project left join project_layer on project.project_key = project_layer.project_key")
  
  # Check the existence of the text file for project selection
  if (file.access("select_projects.txt") != 0) {
    unit_list <- unique(tab_project_info$project_key)
  } else {
    # Read project selection from text file
    pj_selection <- read.table("select_projects.txt", header=T, comment.char="#")
    if (length(pj_selection$project_key) == 0) {
      unit_list <- unique(tab_project_info$project_key)
    } else {
      unit_list <- unique(pj_selection$project_key)
    }  
  }
  
  str_unit <- paste(unit_list,collapse=",")
  
  # Get necessary data records from SEMPR
source("tab_project_info.R")
source("tab_organization_info.R")
source("tab_teams_info.R")
source("tab_person_info.R")
source("tab_time_info.R")
source("tab_defect_info.R")
source("tab_size_info.R")
source("tab_task_info.R")

 # for examination of consistency
source("tab_time_def_info.R")
source("tab_time_overlap_info.R")

  # Read data selection from text file
  fact_selection            <- read.table("select_project-fact_data.txt", header=T, comment.char="#", sep=",")
  fidelity_selection        <- read.table("select_project-fidelity_data.txt", header=T, comment.char="#", sep=",")
  quality_selection         <- read.table("select_project-quality_data.txt", header=T, comment.char="#", sep=",")
  selection_flgs            <- list(fact_selection, fidelity_selection)
  names(selection_flgs) <- c("fact_selection", "fidelity_selection")
  
  # Get data frame for project fact and project process fidelity
  DF_list        <- list(tab_project_info,     tab_organization_info,  tab_teams_info, 
                         tab_person_info,      tab_time_info,          tab_defect_info, 
                         tab_size_info,        tab_task_info,          tab_time_def_info,
                         tab_time_overlap_info
                         )
  names(DF_list)  <- c("tab_project_info", "tab_organization_info", "tab_teams_info", 
                      "tab_person_info",  "tab_time_info",         "tab_defect_info", 
                      "tab_size_info",    "tab_task_info",         "tab_time_def_info", 
                      "tab_time_overlap_info"
                      ) 
  
  DF_dq <- getDQDataFrame(unit_list, DF_list, selection_flgs,  currentDirectory, "project")
  
  file_path <- paste(currentDirectory, "/project_data_quality_", Sys.Date(), ".csv", sep="")
  write.csv(DF_dq, file_path, row.names=F)
  
  
  number_of_size_records   = DF_dq$number_of_size_records
  number_of_planned_size   = DF_dq$number_of_size_records - DF_dq$number_of_no_plan_records_in_size
  number_of_actual_size    = DF_dq$number_of_size_records - DF_dq$number_of_no_actual_records_in_size

  data_score        <-0.0
  plan_size_score   <-0.0 
  actual_size_score <-0.0

  #if (number_of_planned_size == 0.0) {
 #     plan_size_score = 0.0
#	} else	{
	plan_size_score = number_of_planned_size/max(1.0,number_of_size_records)*100.
#	}
 # if (number_of_actual_size == 0.0)  { 
#	actual_size_score = 0.0
 # }else {
	actual_size_score = number_of_actual_size/max(number_of_size_records)*100.
 # }
   benford_score_in_time            = DF_dq$benford_score_in_time
   trailDigit_score_in_time         = DF_dq$trailDigit_score_in_time
   benford_score_in_defect          = DF_dq$benford_score_in_defect
   trailDigit_score_in_defect       = DF_dq$trailDigit_score_in_defect
   
   data_score = (  plan_size_score         + actual_size_score        
                 + benford_score_in_time   + trailDigit_score_in_time 
			     + benford_score_in_defect + trailDigit_score_in_defect ) / 6.0
  
  DF_score <- data.frame( 
        project                    = DF_dq$element,
	    	data_score                 = data_score,                    
	      benford_score_in_time      = benford_score_in_time,
		    trailDigit_score_in_time   = trailDigit_score_in_time,
	      benford_score_in_defect    = benford_score_in_defect,
		    trailDigit_score_in_defect = trailDigit_score_in_defect,
		    plan_size_score            = plan_size_score,
	    	actual_size_score          = actual_size_score
		)
  score_file_name <- paste(currentDirectory, "/data_quality_scores", Sys.Date(), ".csv", sep="")
  write.csv(DF_score, score_file_name, row.names=F)
 
}