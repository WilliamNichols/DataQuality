#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Output the number of stop days between start date and end date
# without weekends and holidays
# 2014/7/17
# Yasutaka Shirai

library(chron)

stopdays <- function(start, end, date_df) 
{ 
  all_dates <- seq(as.Date(start), as.Date(end), by="day") 
  work_dates <- list()
  stop_days <- 0
  
  for (i in 1:length(date_df$start_day)) {
    work_dates_each_row <- seq(as.Date(date_df[i, "start_day"]), as.Date(date_df[i, "end_day"]), by="day")
    work_dates <- c(work_dates, work_dates_each_row)
  }
  match_result <- match(all_dates, unique(work_dates))
  
  for (j in seq_along(match_result)) {
    if (is.na(match_result[j])) {
      
	    month_val <- as.numeric(format(all_dates[j], "%m"))
	    day_val <- as.numeric(format(all_dates[j], "%d"))
	    year_val <- as.numeric(format(all_dates[j], "%Y"))
	    
	    weekday <- day.of.week(month=month_val, day=day_val, year=year_val)
	    
	    if((weekday > 0) && (weekday < 6)) {
        stop_days <- stop_days + 1
	    }
    }
  }
  return(stop_days)
}