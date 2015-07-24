#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Check the illegal date value
# 2014/8/DD
# Yasutaka Shirai

require(lubridate)
require(date)

illegalDateCheck <- function(DF, columns, key_column)
{ 
  Sys.setlocale("LC_TIME","C")
  
  i <- 1
  List_illegal_date <- list()
  
  for (col in columns) {
    
    date_vector <- unlist(DF[col])
    date_vector_temp <- as.POSIXlt(date_vector)
    
    yyyymmdd_vector <- format(date_vector_temp, format="%Y-%m-%d")
    year_vector <- year(date_vector_temp)
    month_vector <- month(date_vector_temp)
    day_vector <- mday(date_vector_temp)
    hour_vector <- hour(date_vector_temp)
    minute_vector <- minute(date_vector_temp)
    second_vector <- second(date_vector_temp)
    
    DF_temp <- transform(DF, yyyymmdd_temp=yyyymmdd_vector, year_temp=year_vector, month_temp=month_vector, day_temp=day_vector, hour_temp=hour_vector, minute_temp=minute_vector, second_temp=second_vector)
    
    DF_temp_yyyymmdd <- subset(DF_temp, as.Date(yyyymmdd_temp) > Sys.Date())
    DF_temp_year <- subset(DF_temp, year_temp < 2000 & is.na(year_temp))
    DF_temp_month <- subset(DF_temp, month_temp > 12 & month_temp < 1 & is.na(month_temp))
    DF_temp_day <- subset(DF_temp, day_temp > 31 & day_temp < 1 & is.na(day_temp))
    DF_temp_hour <- subset(DF_temp, hour_temp > 23 & day_temp < 0 & is.na(hour_temp))
    DF_temp_minute <- subset(DF_temp, minute_temp > 59 & minute_temp < 0 & is.na(minute_temp))
    DF_temp_second <- subset(DF_temp, second_temp > 59 & second_temp < 0 & is.na(second_temp))
    
    if (nrow(DF_temp_yyyymmdd) > 0) {    
      DF_illegal_yyyymmdd <- data.frame(key=as.character(DF_temp_yyyymmdd[,key_column]),column=col,data=as.character(DF_temp_yyyymmdd[,col]),data_quality="future date")
    } else {
      DF_illegal_yyyymmdd <- data.frame(key=key_column,column=col,data="no data",data_quality="no future date")
    }
    if (nrow(DF_temp_year) > 0) {    
      DF_illegal_year <- data.frame(key=as.character(DF_temp_year[,key_column]),column=col,data=as.character(DF_temp_year[,col]),data_quality="illegal year data")
    } else {
      DF_illegal_year <- data.frame(key=key_column,column=col,data="no data",data_quality="no illegal year data")
    }
    if (nrow(DF_temp_month) > 0) {    
      DF_illegal_month <- data.frame(as.character(key=DF_temp_month[,key_column]),column=col,data=as.character(DF_temp_month[,col]),data_quality="illegal month data")
    } else {
      DF_illegal_month <- data.frame(key=key_column,column=col,data="no data",data_quality="no illegal month data")
    }
    if (nrow(DF_temp_day) > 0) {
      DF_illegal_day <- data.frame(key=as.character(DF_temp_day[,key_column]),column=col,data=as.character(DF_temp_day[,col]),data_quality="illegal day data")
    } else {
      DF_illegal_day <- data.frame(key=key_column,column=col,data="no data",data_quality="no illegal day data")
    }
    if (nrow(DF_temp_hour) > 0) {
      DF_illegal_hour <- data.frame(key=as.character(DF_temp_hour[,key_column]),column=col,data=as.character(DF_temp_hour[,col]),data_quality="illegal hour data")
    } else {
      DF_illegal_hour <- data.frame(key=key_column,column=col,data="no data",data_quality="no illegal hour data")
    }
    if (nrow(DF_temp_minute) > 0) {    
      DF_illegal_minute <- data.frame(key=as.character(DF_temp_minute[,key_column]),column=col,data=as.character(DF_temp_minute[,col]),data_quality="illegal minute data")
    } else {
      DF_illegal_minute <- data.frame(key=key_column,column=col,data="no data",data_quality="no illegal minute data")
    }
    if (nrow(DF_temp_second) > 0) {    
      DF_illegal_second <- data.frame(key=as.character(DF_temp_second[,key_column]),column=col,data=as.character(DF_temp_second[,col]),data_quality="illegal second data")
    } else {
      DF_illegal_second <- data.frame(key=key_column,column=col,data="no data",data_quality="no illegal second data")
    }
    
    DF_illegal_temp <- rbind(DF_illegal_yyyymmdd,DF_illegal_year)
    DF_illegal_temp <- rbind(DF_illegal_temp,DF_illegal_month)
    DF_illegal_temp <- rbind(DF_illegal_temp,DF_illegal_day)
    DF_illegal_temp <- rbind(DF_illegal_temp,DF_illegal_hour)    
    DF_illegal_temp <- rbind(DF_illegal_temp,DF_illegal_minute)
    DF_illegal_temp <- rbind(DF_illegal_temp,DF_illegal_second)
    
    if (i == 1) {
      DF_illegal <- DF_illegal_temp
    } else {
      DF_illegal <- rbind(DF_illegal,DF_illegal_temp)
    }
    i <- i+1
  }

  return (DF_illegal)
}