#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Callable function to
# Extract the data quality data
#
# Arguments
#   unit - project key(s) from database key
#   DF_list
#   selection_flgs ? not used?
#   unit_name -
#   currentDirectory ? not used?
#
# wrn note, may want to decompose this into several modules, one for each type of data
#
#
# Return
#   DF_dq # the data quality data frame
#
# 2015/2/22
# Yasutaka Shirai
# William Nichols
# add trail digit score
# Uses
source ("examineTimeAccuracy.R")
source ("examineDefectAccuracy.R")
source ("examineSizeAccuracy.R")
source ("examineTaskAccuracy.R")
source ("calcBenfordScore.R")
source ("calcTrailDigitScore.R")


# Notification for no data
NoData <- "No Data"

getDQDataFrame <- function(unit_list, DF_list, selection_flgs, currentDirectory, unit_name) {
#getDQDataFrame <- function(unit_list, DF_list, unit_name) {

  # Exchange second argument into each data frame which is used in this function
  tab_project_info      <- DF_list$tab_project_info
  tab_organization_info <- DF_list$tab_organization_info
  tab_team_info         <- DF_list$tab_teams_info
  tab_person_info       <- DF_list$tab_person_info
  tab_time_info         <- DF_list$tab_time_info
  tab_defect_info       <- DF_list$tab_defect_info
  tab_size_info         <- DF_list$tab_size_info
  tab_task_info         <- DF_list$tab_task_info
  tab_time_def_info     <- DF_list$tab_time_def_info
  tab_time_overlap_info <- DF_list$tab_time_overlap_info

  ## Determine the unit_key (project or component)
  if (unit_name == "project") {
    unit_key <- "project_key"
  }

  ## Extract data by each unit
  i_units_processed <- 0
  for (element in unit_list) {

    ## Extract project information from project table
    if (nrow(tab_project_info) == 0) {
      if (unit_name == "project") {
        project_name <- NoData
      } else if (unit_name == "component") {
        project_key <- NoData
      }
    } else {
      project_info <- subset(tab_project_info, get(unit_key)==element)

      if (unit_name == "project") {
        project_name <- project_info$project_name
      } else if (unit_name == "component") {
        project_key <- paste(project_info$project_key, collapse=";")
      }
    }
#

    ## Extract data quality of time log
    # Get the time log data frame for each project
    time_info <- subset(tab_time_info, get(unit_key)==element)
    
    num_time_records       <- 0
	num_time_records   <- nrow(time_info)

	
	#WRN_note, these should be set by default, not in a conditinal
	# process if there are >0 rows of time data
    if (nrow(time_info) == 0) {
        num_interrupt          <- NA
		DF_benford_time        <- NA
        ben_score_time         <- NA
		    DF_trailDigit_time     <- NA
		    trailDigit_score_time  <- NA
        length_inaccuracy_time <- NA
        num_null_delta         <- NA
        num_zero_delta         <- NA
        num_negative_delta     <- NA
        num_future_time        <- NA
        num_illyear_time       <- NA
        num_illmonth_time      <- NA
        num_illday_time        <- NA
        num_illhour_time       <- NA
        num_illminute_time     <- NA
        num_illsecond_time     <- NA
    } else {
      # Get the Benford data for time log
        time_positive_info     <- subset(time_info, time_log_delta_minutes > 0)
        DF_benford_time        <- calcBenfordScore(time_positive_info$time_log_delta_minutes)
        ben_score_time         <- DF_benford_time$score
	   	  DF_trailDigit_time     <- calcTrailDigitScore(time_positive_info$time_log_delta_minutes)
		    trailDigit_score_time  <- DF_trailDigit_time$score

      # Get the interruption time data for time log
        time_interrupt_info   <- subset(time_info, time_log_interrupt_minutes > 0)
        num_interrupt         <- nrow(time_interrupt_info)

      # Get the data accuracy data for time log
        DF_accuracy_time       <- examineTimeAccuracy(time_info)
        DF_inaccuracy_time     <- subset(DF_accuracy_time, data != "no data")

        length_inaccuracy_time <- length(unique(DF_inaccuracy_time$key))

        DF_time_null           <- subset(DF_accuracy_time, data_quality=="null data")
        DF_time_zero           <- subset(DF_accuracy_time, data_quality=="zero data")
        DF_time_negative       <- subset(DF_accuracy_time, data_quality=="minus data")
        DF_time_illegal_future <- subset(DF_accuracy_time, data_quality=="future date")
        DF_time_illegal_year   <- subset(DF_accuracy_time, data_quality=="illegal year data")
        DF_time_illegal_month  <- subset(DF_accuracy_time, data_quality=="illegal month data")
        DF_time_illegal_day    <- subset(DF_accuracy_time, data_quality=="illegal day data")
        DF_time_illegal_hour   <- subset(DF_accuracy_time, data_quality=="illegal hour data")
        DF_time_illegal_minute <- subset(DF_accuracy_time, data_quality=="illegal minute data")
        DF_time_illegal_second <- subset(DF_accuracy_time, data_quality=="illegal second data")

        num_null_delta     <- nrow(DF_time_null)
        num_zero_delta     <- nrow(DF_time_zero)
        num_negative_delta <- nrow(DF_time_negative)
        num_future_time    <- nrow(DF_time_illegal_future)
        num_illyear_time   <- nrow(DF_time_illegal_year)
        num_illmonth_time  <- nrow(DF_time_illegal_month)
        num_illday_time    <- nrow(DF_time_illegal_day)
        num_illhour_time   <- nrow(DF_time_illegal_hour)
        num_illminute_time <- nrow(DF_time_illegal_minute)
        num_illsecond_time <- nrow(DF_time_illegal_second)
    }

    # Get the time overlapping data for time log
    time_overlap_info <- subset(tab_time_overlap_info, get(unit_key)==element)
#
#
	#, wrn note, these need to be evaluated by individual
	# sort by person_key
#

    if (nrow(time_overlap_info) == 0) {
        num_overlap   <- NA
        total_overlap <- NA
    } else {
        DF_overlap_temp            <- subset(time_overlap_info,pre_time_log_end_date > time_log_start_date)
        DF_overlap_temp$difference <- as.POSIXct(DF_overlap_temp$pre_time_log_end_date) -
                                      as.POSIXct(DF_overlap_temp$time_log_start_date )
        DF_overlap       <- DF_overlap_temp[,c(1,2,3,4,5,13)]

        num_overlap      <- nrow(DF_overlap)
        total_overlap    <- sum(DF_overlap$difference)
    } # end if else

	#
	#   Defect data
    # Get the defect log data frame for each project
  defect_info <- subset(tab_defect_info, get(unit_key)==element)
  num_defect_records <- 0
  num_defect_records <- nrow(defect_info)	
# process only if >0 records of defect data  
  if (nrow(defect_info) == 0) {
      num_defect_records        <- 0
	    DF_benford_deftime        <- NA
      ben_score_deftime         <- 0.0
	    DF_trailDigit_deftime     <- 0.0
	    trailDigit_score_deftime  <- 0.0
      length_inaccuracy_defect  <- NA
#
      num_zero_deftime          <- NA
      num_null_deftime          <- NA
      num_negative_deftime      <- NA
      num_future_deftime        <- NA
      num_illyear_deftime       <- NA
      num_illmonth_deftime      <- NA
      num_illday_deftime        <- NA
      num_illhour_deftime       <- NA
      num_illminute_deftime     <- NA
      num_illsecond_deftime     <- NA
 } else {
 #       num_defect_records <- nrow(defect_info)
      # Get the Benford data for defect log
        deftime_positive_info      <- subset(defect_info, defect_fix_time_minutes > 0)

        DF_benford_deftime         <- calcBenfordScore(deftime_positive_info$defect_fix_time_minutes)
        ben_score_deftime          <- DF_benford_deftime$score
	    	DF_trailDigit_deftime      <- calcTrailDigitScore(deftime_positive_info$defect_fix_time_minutes)
	      trailDigit_score_deftime   <- DF_trailDigit_deftime$score
#
      # Get the data accuracy data for defect log
        element_number        <- element
        DF_accuracy_defect    <- examineDefectAccuracy(defect_info, element_number)  #wrn add element_number
        write.csv(DF_accuracy_defect, paste("DF_accuracy_defect_", element_number, ".csv", sep=""), row.names=F)
#		
      #DF_inaccuracy_defect      <- subset(DF_accuracy_defect,!grepl("no data", DF_accuracy_defect$data))
        DF_inaccuracy_defect     <- subset(DF_accuracy_defect, data != "no data")
        length_inaccuracy_defect <- length(unique(DF_inaccuracy_defect$key))

        DF_defect_zero           <- subset(DF_accuracy_defect, data_quality == "zero data")
        DF_defect_null           <- subset(DF_accuracy_defect, data_quality == "null data")
        DF_defect_negative       <- subset(DF_accuracy_defect, data_quality == "minus data")
        DF_defect_illegal_future <- subset(DF_accuracy_defect, data_quality == "future date")
        DF_defect_illegal_year   <- subset(DF_accuracy_defect, data_quality == "illegal year data")
        DF_defect_illegal_month  <- subset(DF_accuracy_defect, data_quality == "illegal month data")
        DF_defect_illegal_day    <- subset(DF_accuracy_defect, data_quality == "illegal day data")
        DF_defect_illegal_hour   <- subset(DF_accuracy_defect, data_quality == "illegal hour data")
        DF_defect_illegal_minute <- subset(DF_accuracy_defect, data_quality == "illegal minute data")
        DF_defect_illegal_second <- subset(DF_accuracy_defect, data_quality == "illegal second data")

        num_zero_deftime      <- nrow(DF_defect_zero)
        num_null_deftime      <- nrow(DF_defect_null)
        num_negative_deftime  <- nrow(DF_defect_negative)
        num_future_deftime    <- nrow(DF_defect_illegal_future)
        num_illyear_deftime   <- nrow(DF_defect_illegal_year)
        num_illmonth_deftime  <- nrow(DF_defect_illegal_month)
        num_illday_deftime    <- nrow(DF_defect_illegal_day)
        num_illhour_deftime   <- nrow(DF_defect_illegal_hour)
        num_illminute_deftime <- nrow(DF_defect_illegal_minute)
        num_illsecond_deftime <- nrow(DF_defect_illegal_second)
    }

    # Get the size data frame for each project
    size_info        <- subset(tab_size_info, get(unit_key)==element)
    num_size_records <- nrow(size_info)
	#
    if (nrow(size_info) == 0) {
        num_size_records       <- 0
        length_inaccuracy_size <- NA
        num_null_size          <- NA
        num_negative_size      <- NA
        num_no_plan_size       <- 0
        num_no_actual_size     <- 0
    } else {
        num_size_records <- nrow(size_info)

      # Get the data accuracy data for size log
        DF_accuracy_size       <- examineSizeAccuracy(size_info)

        DF_inaccuracy_size     <- subset(DF_accuracy_size, data != "no data")
        length_inaccuracy_size <- length(unique(DF_inaccuracy_size$key))

        DF_size_null           <- subset(DF_inaccuracy_size, data_quality == "null data")
        DF_size_negative       <- subset(DF_inaccuracy_size, data_quality == "minus data")
        DF_size_no_plan        <- subset(DF_inaccuracy_size, data_quality == "no planned size data")
        DF_size_no_actual      <- subset(DF_inaccuracy_size, data_quality == "no actual size data")

        num_null_size          <- nrow(DF_size_null)
        num_negative_size      <- nrow(DF_size_negative)
        num_no_plan_size       <- nrow(DF_size_no_plan)
        num_no_actual_size     <- nrow(DF_size_no_actual)
    }

    # Get the data accuracy data for task log
    task_info <- subset(tab_task_info, get(unit_key)==element)

    if (nrow(task_info) == 0) {
        length_inaccuracy_task <- NA
        num_negative_task      <- NA
        num_future_task        <- NA
        num_illyear_task       <- NA
        num_illmonth_task      <- NA
        num_illday_task        <- NA
        num_illhour_task       <- NA
        num_illminute_task     <- NA
        num_illsecond_task     <- NA
    } else {
        DF_accuracy_task       <- examineTaskAccuracy(task_info)

        DF_inaccuracy_task     <- subset(DF_accuracy_task, data != "no data")
        length_inaccuracy_task <- length(unique(DF_inaccuracy_task$key))

        DF_task_negative        <- subset(DF_inaccuracy_task, data_quality == "minus data")
        DF_task_illegal_future  <- subset(DF_inaccuracy_task, data_quality == "future date")
        DF_task_illegal_year    <- subset(DF_inaccuracy_task, data_quality == "illegal year data")
        DF_task_illegal_month   <- subset(DF_inaccuracy_task, data_quality == "illegal month data")
        DF_task_illegal_day     <- subset(DF_inaccuracy_task, data_quality == "illegal day data")
        DF_task_illegal_hour    <- subset(DF_inaccuracy_task, data_quality == "illegal hour data")
        DF_task_illegal_minute  <- subset(DF_inaccuracy_task, data_quality == "illegal minute data")
        DF_task_illegal_second  <- subset(DF_inaccuracy_task, data_quality == "illegal second data")
        DF_task_no_start        <- subset(DF_inaccuracy_task, data_quality == "no start task data")
        DF_task_no_completion   <- subset(DF_inaccuracy_task, data_quality == "no complete task data")

        num_negative_task      <- nrow(DF_task_negative)
        num_future_task        <- nrow(DF_task_illegal_future)
        num_illyear_task       <- nrow(DF_task_illegal_year)
        num_illmonth_task      <- nrow(DF_task_illegal_month)
        num_illday_task        <- nrow(DF_task_illegal_day)
        num_illhour_task       <- nrow(DF_task_illegal_hour)
        num_illminute_task     <- nrow(DF_task_illegal_minute)
        num_illsecond_task     <- nrow(DF_task_illegal_second)
        num_no_start_task      <- nrow(DF_task_no_start)
        num_no_completion_task <- nrow(DF_task_no_completion)
    }

    DF_dq_temp <- data.frame(
        element                              = element,
        number_of_time_records               = num_time_records,
        benford_score_in_time                = ben_score_time,
    	trailDigit_score_in_time             = trailDigit_score_time,
        number_of_interrupt_in_time          = num_interrupt,
        number_of_inaccuracy_records_in_time = length_inaccuracy_time,
        number_of_null_in_time               = num_null_delta,
        number_of_zero_in_time               = num_zero_delta,
        number_of_negative_in_time           = num_negative_delta,
        number_of_future_date_in_time        = num_future_time,
        number_of_illedal_year_in_time       = num_illyear_time,
        number_of_illegal_month_in_time      = num_illmonth_time,
        number_of_illegal_day_in_time        = num_illday_time,
        number_of_illegal_hour_in_time       = num_illhour_time,
        number_of_illegal_minute_in_time     = num_illminute_time,
        number_of_illegal_second_in_time     = num_illsecond_time,
        number_of_overlap_records            = num_overlap,
        total_overlap_time                   = total_overlap,
        number_of_defect_records             = num_defect_records,
        benford_score_in_defect              = ben_score_deftime,
		trailDigit_score_in_defect           = trailDigit_score_deftime,
        number_of_inaccuracy_records_in_defect = length_inaccuracy_defect,
        number_of_zero_in_deffixtime         = num_zero_deftime,
        number_of_null_in_defect             = num_null_deftime,
        number_of_negative_in_deffixtime     = num_negative_deftime,
        number_of_future_date_in_defect      = num_future_deftime,
        number_of_illegal_year_in_defect     = num_illyear_deftime,
        number_of_illegal_month_in_defect    = num_illmonth_deftime,
        number_of_illegal_day_in_defect      = num_illday_deftime,
        number_of_illegal_hour_in_defect     = num_illhour_deftime,
        number_of_illegal_minute_in_defect   = num_illminute_deftime,
        number_of_illegal_second_in_defect   = num_illsecond_deftime,
        number_of_size_records               = num_size_records,
        number_of_inaccuracy_records_in_size = length_inaccuracy_size,
        number_of_null_in_size               = num_null_size,
        number_of_negative_in_size           = num_negative_size,
        number_of_no_plan_records_in_size    = num_no_plan_size,
        number_of_no_actual_records_in_size  = num_no_actual_size,
        number_of_negative_in_task           = num_negative_task,
        number_of_future_date_in_task        = num_future_task,
        number_of_illegal_year_in_task       = num_illyear_task,
        number_of_illegal_month_in_task      = num_illmonth_task,
        number_of_illegal_day_in_task        = num_illday_task,
        number_of_illegal_hour_in_task       = num_illhour_task,
        number_of_illegal_minute_in_task     = num_illminute_task,
        number_of_illegal_second_in_task     = num_illsecond_task,
        number_of_no_start_date_in_task      = num_no_start_task,
        number_of_no_completion_date_in_task = num_no_completion_task)

    if (i_units_processed == 0) {
	# first time through, initialize the data quality frame
        DF_dq <- DF_dq_temp
    } else {
	# not the first time through, append data to the data quality frame
        DF_dq <- rbind(DF_dq, DF_dq_temp)
    }
    i_units_processed <- i_units_processed + 1
  }
  return(DF_dq)
}
