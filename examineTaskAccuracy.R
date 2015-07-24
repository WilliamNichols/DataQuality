#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Examine the Accuracy of Data Quality for task_status_fact_hist table
# 2014/9/1
# Yasutaka Shirai
##
# William Nichols
#
# Input  :  DF - data frame
# Return :  DF - data frame with inaccuracy results
##
#
#

source ("nullCheck.R")
source ("illegalDateCheck.R")
source ("minusCheck.R")
source ("zeroCheck.R")

examineTaskAccuracy <- function(DF)
{
  table <- "task_status_fact_hist"
  
  # Check null values in the columns
  list_for_nullch <- list("task_plan_time_minutes","task_actual_time_minutes")
  DF_nullch <- nullCheck(DF,list_for_nullch,"task_status_fact_key")
  
  # Check zero values in the columns
  # No check zero values for task_status_fact_hist table
  
  # Check minus values in the columns
  list_for_minusch <- list("task_plan_time_minutes","task_actual_time_minutes")
  DF_minusch <- minusCheck(DF,list_for_minusch,"task_status_fact_key")
  
  # Check illegal date values in the columns
  list_for_illdate <- list("task_actual_start_date","task_actual_complete_date")
  DF_illdatech <- illegalDateCheck(DF,list_for_illdate,"task_status_fact_key")
  
  # Check other illegal values in the columns
  # examine the records which have no complete date
  DF_temp_no_complete_task <- subset(DF, task_actual_complete_date_key > 99990000)
  
  if (nrow(DF_temp_no_complete_task) > 0) {
    DF_no_complete_task <- data.frame(key=as.character(DF_temp_no_complete_task[,"task_status_fact_key"]),column="task_actual_complete_date_key",data=as.character(DF_temp_no_complete_task[,"task_actual_complete_date_key"]),data_quality="no complete task data")
  } else {
    DF_no_complete_task <- data.frame(key="task_status_fact_key",column="task_actual_complete_date_key",data="no data",data_quality="all tasks are completed")
  }
  
  # examine the records which have no start date
  DF_temp_no_start_task <- subset(DF, task_actual_start_date_key > 99990000)
  
  if (nrow(DF_temp_no_start_task) > 0) {
    DF_no_start_task <- data.frame(key=as.character(DF_temp_no_start_task[,"task_status_fact_key"]),column="task_actual_start_date_key",data=as.character(DF_temp_no_start_task[,"task_actual_start_date_key"]),data_quality="no start task data")
  } else {
    DF_no_start_task <- data.frame(key="task_status_fact_key",column="task_actual_start_date_key",data="no data",data_quality="all tasks have start date")
  }
  
  
  DF_inaccuracy <- rbind(DF_nullch,DF_minusch)
  DF_inaccuracy <- rbind(DF_inaccuracy,DF_illdatech)
  DF_inaccuracy <- rbind(DF_inaccuracy,DF_no_complete_task)
  DF_inaccuracy <- rbind(DF_inaccuracy,DF_no_start_task)
  DF_inaccuracy$table <- table

  return(DF_inaccuracy)
}