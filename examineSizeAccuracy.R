#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Examine the Accuracy of Data Quality for size_fact_hist table
# 2014/9/1
# Yasutaka Shirai

source ("nullCheck.R")
source ("illegalDateCheck.R")
source ("minusCheck.R")
source ("zeroCheck.R")

examineSizeAccuracy <- function(DF)
{
  table <- "size_fact_hist"
  
  # Check null values in the columns
  list_for_nullch <- list("size_added_and_modified","size_added","size_base","size_deleted","size_modified","size_reused","size_total")
  DF_nullch <- nullCheck(DF,list_for_nullch,"size_fact_key")
  
  # Check zero values in the columns
  # No check zero values for time_log_fact_hist table
  
  # Check minus values in the columns
  list_for_minusch <- list("size_added_and_modified","size_added","size_base","size_deleted","size_modified","size_reused","size_total")
  DF_minusch <- minusCheck(DF,list_for_minusch,"size_fact_key")
    
  # Check illegal date values in the columns
  # No check illegal date values for time_log_fact_hist table
  
  # Check other illegal values in the columns
  # evaluate the ratio of the number of records which have planned size value to the number of records which have actual size value  DF_planned_size <- subset(DF, measurement_type_key == 1)
  DF_planned_size <- subset(DF, measurement_type_key == 1)
  DF_actual_size  <- subset(DF, measurement_type_key == 4)
  
  v_key_planned_size <- DF_planned_size$plan_item_key
  v_key_actual_size  <- DF_actual_size$plan_item_key
  
  DF_temp_no_actual_size  <- subset(DF_planned_size,! DF_planned_size$plan_item_key %in% v_key_actual_size)
  DF_temp_no_planned_size <- subset(DF_actual_size,! DF_actual_size$plan_item_key %in% v_key_planned_size)
  
  if (nrow(DF_temp_no_actual_size) > 0) {
    DF_no_actual_size <- data.frame(key=as.character(DF_temp_no_actual_size[,"size_fact_key"]),column="plan_item_key",data=as.character(DF_temp_no_actual_size[,"plan_item_key"]),data_quality="no actual size data")
  } else {
    DF_no_actual_size <- data.frame(key="size_fact_key",column="all column",data="no data",data_quality="all records which have planned size have actual size data")
  }
  if (nrow(DF_temp_no_planned_size) > 0) {
    DF_no_planned_size <- data.frame(key=as.character(DF_temp_no_planned_size[,"size_fact_key"]),column="plan_item_key",data=as.character(DF_temp_no_planned_size[,"plan_item_key"]),data_quality="no planned size data")
  } else {
    DF_no_planned_size <- data.frame(key="size_fact_key",column="all column",data="no data",data_quality="all records which have actual size have planned size data")    
  }
  
  DF_inaccuracy <- rbind(DF_nullch,DF_minusch)
  DF_inaccuracy <- rbind(DF_inaccuracy,DF_no_actual_size)
  DF_inaccuracy <- rbind(DF_inaccuracy,DF_no_planned_size)
  DF_inaccuracy$table <- table
  
  return(DF_inaccuracy)
}