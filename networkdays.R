#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Output the number of days between start date and end date
# without weekends and holidays
# 2014/3/21
# Yasutaka Shirai

library(chron)

networkdays <- function(start, end, holidays) 
{
#dates <- seq(start, end, by="day")
dates <- seq(as.Date(start), as.Date(end), by="day") 
weekends <- 0

for(i in seq_along(dates)) {
	month_val <- as.numeric(format(dates[i], "%m"))
	day_val <- as.numeric(format(dates[i], "%d"))
	year_val <- as.numeric(format(dates[i], "%Y"))
	
	weekday <- day.of.week(month=month_val, day=day_val, year=year_val)
	
	if((weekday == 0) || (weekday == 6)) {
		weekends <- weekends + 1
	}
}

if(missing(holidays)) {
	holidays <- 0 
} else {
	holidays <- length(holidays)
}

#sum(as.numeric(format(dates, "%w") > 1)) - weekends - holidays 
length(dates) - weekends - holidays
} 

