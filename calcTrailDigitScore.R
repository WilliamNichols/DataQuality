#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# This code calculates the trailing Digit score
# by comparing the distribution of lowest precision digits to
# a uniform distribuiton
#2015/5/10
#

calcTrailDigitScore <- function(list_number)
{
# ? do I need to strip out "0"
    score_numerator <- 0
    len_list    <- length(list_number)
    trail_digit <- list_number
    max_digits  <- max(nchar(list_number))
    for (i in max_digits:2){
        trail_digit <-(trail_digit - (10^i)*(list_number%/%(10^i)))
    }
    DF_list_number  <- data.frame(number=list_number)   # dataframe has the numbers in the leading column
    trail_digit     <- (list_number-100*(list_number%/%100)) - 10*(list_number-100*(list_number%/%100))%/%10
    len_trail_digit <- length(trail_digit)



    prob     <- 0.1 # uniform probability

    for (i in 0:9) {
                                        #observe <- subset(DF_list_number, firstdigit==i)
                                        #len_obs <- length(observe$firstdigit)
        observe  <- subset(trail_digit, trail_digit==i)
        len_obs  <- length(observe) #  number of observations
        expect   <- prob*len_trail_digit
        std_dev  <- sqrt(expect)
        excess   <- abs(expect-len_obs)
                                        #score_numerator <- score_numerator + excess-2*std_dev
        DF_trail_temp <- data.frame(numeric=i,
                                    sample_size=len_list,
                                    probability=prob,
                                    observation=len_obs,
                                    expectation=expect,
                                    sd=std_dev,
                                    excess=excess
                                    )
        if (i==0) {
            DF_trail <- DF_trail_temp
        } else {
            DF_trail <- rbind(DF_trail, DF_trail_temp)
        }
    } # end for( i in 0:9)

  score                    <- (1-max(DF_trail$excess)*1.5/max(1,len_trail_digit) )*100
  List_trail_result        <- list(score, DF_trail)
  names(List_trail_result) <- c("score","data")

  return(List_trail_result)
}
