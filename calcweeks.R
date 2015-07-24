#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Output the number of weeks between start week and end week
# 2014/7/17
# Yasutaka Shirai

library(chron)

calcweeks<- function(start, end) 
{
start_year_str <- substring(start,1,4)
start_week_str <- substring(start,5,6)
end_year_str <- substring(end,1,4)
end_week_str <- substring(end,5,6)

weeks <- (as.numeric(end_year_str)-as.numeric(start_year_str))*52+as.numeric(end_week_str)-as.numeric(start_week_str)

return(weeks)
}
