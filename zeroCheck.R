#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Check the zero value
# 2014/9/1
# Yasutaka Shirai

zeroCheck <- function(DF, columns, key_column)
{ 
  i <- 1
  
  for (col in columns) {
    DF_temp <- subset(DF, DF[col] == 0)
    
    if (nrow(DF_temp) > 0) {    
      DF_zero_temp <- data.frame(key=as.character(DF_temp[,key_column]),column=col,data=as.character(DF_temp[,col]),data_quality="zero data")
    } else {
      DF_zero_temp <- data.frame(key=key_column,column=col,data="no data",data_quality="no zero data")
    }
    
    
    if (i == 1) {
      DF_zero <- DF_zero_temp
    } else {
      DF_zero <- rbind(DF_zero,DF_zero_temp)
    }
    i <- i+1
  }

  return (DF_zero)
}