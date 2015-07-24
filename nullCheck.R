#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Check the null value
# 2014/9/1
# Yasutaka Shirai

nullCheck <- function(DF, columns, key_column)
{ 
  i <- 1
  
  for (col in columns) {
    # Null value in MySQL is changed to NA value in the R world.
    DF_temp <- subset(DF, is.na(DF[col])==TRUE)

    if (nrow(DF_temp) > 0) {    
      DF_null_temp <- data.frame(key=as.character(DF_temp[,key_column]),column=col,data=as.character(DF_temp[,col]),data_quality="null data")
    } else {
      DF_null_temp <- data.frame(key=key_column,column=col,data="no data",data_quality="no null data")
    }
    
    
    if (i == 1) {
      DF_null <- DF_null_temp
    } else {
      DF_null <- rbind(DF_null,DF_null_temp)
    }
    i <- i+1
  }
  return (DF_null)
}