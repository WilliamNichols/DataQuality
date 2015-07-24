#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# This code calculates the Benford score
# 2015/2/13
# Yasutaka Shirai
#
#
##
#William Nichols
# Input : list_number     - a vector of values
# Return: list_ben_result - LIST ( score, DATA_FRAME(df_ben)
# Output: none
##
#
#

calcBenfordScore <- function(list_number)
{
    score_numerator <- 0

    DF_list_number            <- data.frame(number=list_number)
    DF_list_number$firstdigit <- DF_list_number$number%/%(10^(nchar(floor(DF_list_number$number))-1))  # extract the leading digit
    DF_list_number$fd_dec     <- DF_list_number$firstdigit
    DF_list_number$fd_dec[DF_list_number$number < 1.0] <- DF_list_number$number[DF_list_number$number < 1.0]*10

                                        #sample <- subset(DF_list_number, firstdigit > 0)
                                        #len_sample <- length(sample$firstdigit)
    sample      <- subset(DF_list_number, fd_dec > 0) # remove all with (leading digit i.e. value ==0)
    len_sample  <- length(sample$fd_dec)
    deviation_i <- numeric(9)

    for (i in 1:9) {
        prob     <- log10(1+1/i)
                                        #observe <- subset(DF_list_number, firstdigit==i)
                                        #len_obs <- length(observe$firstdigit)
        observe    <- subset(DF_list_number, fd_dec==i) # select the first (digit == i)
        len_obs    <- length(observe$fd_dec)            # count how many selected
        expec      <- prob*len_sample                   # compute the expected value
        std_dev    <- sqrt(expec)                       # and the statistical variation
        deviation  <- expec-len_obs
        excess     <- abs(expec-len_obs)
        rel_excess <-0
        if( std_dev >0) {
            rel_excess     <- excess/std_dev
            abs_rel_excess <- abs(excess/std_dev)
        }
        #deviation_i[i] <- excess
                                        #score_numerator <- score_numerator + excess-2*std_dev
        DF_ben_temp <- data.frame(
            numeric        = i,
            sample_size    = len_sample,
            probability    = prob,
            observation    = len_obs,
            expectation    = expec,
            sd             = std_dev,
            deviation      = deviation,
            excess         = excess,
            rel_excess     = rel_excess,
            abs_rel_excess = abs_rel_excess
        )
        if (i==1) {
            DF_ben <- DF_ben_temp
        } else {
            DF_ben <- rbind(DF_ben, DF_ben_temp)
        }
    } # end for( i in 1:9)

    mean_deviation <- sum(DF_ben["abs_rel_excess"])/length(DF_ben$abs_rel_excess)

  score                  <- (1-max(DF_ben$excess)*1.5/len_sample)*100
  List_ben_result        <- list(score, DF_ben)
  names(List_ben_result) <- c("score","data")

  return(List_ben_result)
}
