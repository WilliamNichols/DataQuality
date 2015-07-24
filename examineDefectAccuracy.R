#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Examine the Accuracy of Data Quality for defect_log_fact_hist table
# 2014/9/1
# Yasutaka Shirai

source ("nullCheck.R")
source ("illegalDateCheck.R")
source ("minusCheck.R")
source ("zeroCheck.R")

examineDefectAccuracy <- function(DF, element_name)  #wrn add element_name
{

    table <- "defect_log_fact_hist"

    DF_element <- element_name # default in case there are no records
    # Check null values in the columns
    list_for_nullch <- list("defect_fix_time_minutes","defect_removed_phase_key","defect_injected_phase_key","defect_type_key")
    DF_nullch       <- nullCheck(DF,list_for_nullch,"defect_log_fact_key")

  # Check zero values in the columns
    list_for_zeroch <- list("defect_fix_time_minutes")
    DF_zeroch       <- zeroCheck(DF,list_for_zeroch,"defect_log_fact_key")

  # Check minus values in the columns
    list_for_minusch <- list("defect_fix_time_minutes")
    DF_minusch       <- minusCheck(DF,list_for_minusch,"defect_log_fact_key")

  # Check illegal date values in the columns
    list_for_illdate <- list("defect_found_date")
    DF_illdatech     <- illegalDateCheck(DF,list_for_illdate,"defect_log_fact_key")

  # Check other illegal values in the columns
  # examine the null value of defect_fix_defect_identifier in records which have compile and testing phase as defect injected phase
    DF_compile <- subset(DF, defect_injected_phase_short_name=="Compile")
    DF_testing <- subset(DF, grepl("*Test",DF$defect_injected_phase_short_name))
    DF_temp    <- rbind( DF_compile,DF_testing)
    DF_temp_nullddid <- subset(DF_testing, is.na(defect_fix_defect_identifier)==TRUE)
    if (nrow(DF_temp_nullddid) > 0) {
#                                   DF_nullddid <- data.frame(key=as.character(DF_temp_nullddid[,"defect_log_fact_key"]),
#                                              column="defect_fix_defect_identifier",
#                                              data=as.character(DF_temp_nullddid[,"defect_fix_defect_identifier"]),
#                                              data_quality="null defect fix defect identifier")

                  DF_nullddid   <- data.frame( key=as.character(DF_temp_nullddid[,"defect_log_fact_key"]),
                                               column="defect_fix_defect_identifier",
                                               data="null",
                                               data_quality="null data")
        } else {         
                   DF_nullddid  <- data.frame( key="defect_log_fact_key",
                                               column="defect_fix_defect_identifier",
                                               data="no data",
                                               data_quality="no null datar")
    }

 #wrn

    DF_inaccuracy       <- rbind(DF_nullch,     DF_zeroch)
#    DF_inaccuracy       <- rbind(DF_inaccuracy, element_name)  #wrn
    DF_inaccuracy       <- rbind(DF_inaccuracy, DF_minusch)
    DF_inaccuracy       <- rbind(DF_inaccuracy, DF_illdatech)
    DF_inaccuracy       <- rbind(DF_inaccuracy, DF_nullddid)
    DF_inaccuracy$table <- table

    return(DF_inaccuracy)
}
