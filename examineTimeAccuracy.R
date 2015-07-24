#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Examine the Accuracy of Data Quality for time_log_fact_hist table
# 2014/9/1
# Yasutaka Shirai

source ("nullCheck.R")
source ("illegalDateCheck.R")
source ("minusCheck.R")
source ("zeroCheck.R")

examineTimeAccuracy <- function(DF)
{
  table <- "time_log_fact_hist"
  
  # Check null values in the columns
  list_for_nullch <- list("time_log_delta_minutes","time_log_interrupt_minutes", "time_log_start_date", "time_log_end_date")
  DF_nullch <- nullCheck(DF,list_for_nullch,"time_log_fact_key")

  # Check zero values in the columns
  list_for_zeroch <- list("time_log_delta_minutes")
  DF_zeroch <- zeroCheck(DF,list_for_zeroch,"time_log_fact_key")
  
  # Check minus values in the columns
  list_for_minusch <- list("time_log_delta_minutes","time_log_interrupt_minutes")
  DF_minusch <- minusCheck(DF,list_for_minusch,"time_log_fact_key")
  
  # Check illegal date values in the columns
  list_for_illdate <- list("time_log_start_date","time_log_end_date")
  DF_illdatech <- illegalDateCheck(DF,list_for_illdate,"time_log_fact_key")
  
  # Check other illegal values in the columns
  # No check other illegal values for time_log_fact_hist table
  
  DF_inaccuracy <- rbind(DF_nullch,DF_zeroch)
  DF_inaccuracy <- rbind(DF_inaccuracy,DF_minusch)
  DF_inaccuracy <- rbind(DF_inaccuracy,DF_illdatech)
  DF_inaccuracy$table <- table
  
  return(DF_inaccuracy)
}