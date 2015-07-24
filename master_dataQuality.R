#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Master file for the integration tool which extract data from SEMPRE
# 2014/7/17
# Yasutaka Shirai
# Updated: 2014/9/14, Yasutaka Shirai
# Update MySQL command for extracting basic fact sheet

require(data.table)
require(chron)
require(DBI)
require(RMySQL)
require(knitr)
library(lattice)
library(xlsx)

# USES
source("extractDataQuality.R")



 
## Set the directory which include this file as work directory
frame_files <- lapply(sys.frames(), function(x) x$ofile)
frame_files <- Filter(Negate(is.null), frame_files)
setwd(dirname(frame_files[[length(frame_files)]]))

setwd("C:/SEI/FactSheets/DataQuality")
# GEt current directory path
currentDirectory <- getwd()

# Get present date
presentDate <- Sys.Date()


## Read the configuration file
source("config.txt")

## Connect and authenticate to a MySQL database
con<-dbConnect(m,user=MyName,password=MyPass,host='localhost',dbname=MydbName);
 

## Execute verifying Data Quality
## Generate data quality report

extractDataQuality(con, currentDirectory)

