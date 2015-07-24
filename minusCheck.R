#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Check the minus value
# 2014/9/1
# Yasutaka Shirai

minusCheck <- function(DF, columns, key_column)
{ 
  i <- 1
  
  for (col in columns) {

    DF_temp <- subset(DF, DF[,col] < 0)

    if (nrow(DF_temp) > 0) {    
      #List_minus[[i]] <- list(column=col, data=DF_temp[key_column])
      DF_minus_temp <- data.frame(key=as.character(DF_temp[,key_column]),column=col,data=as.character(DF_temp[,col]),data_quality="minus data")
    } else {
      #List_null[[i]] <- list(column=col, data="no minus data")
      DF_minus_temp <- data.frame(key=key_column,column=col,data="no data",data_quality="no minus data")
    }

    if (i == 1) {
      DF_minus <- DF_minus_temp
    } else {
      DF_minus <- rbind(DF_minus,DF_minus_temp)
    }
    i <- i+1
  }
  
  return (DF_minus)
}