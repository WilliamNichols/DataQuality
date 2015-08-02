#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Master to extract data from SEMPR
# interfact to MySQL  for executing the PACE analysis
# William Nichols
#
# USES
#     "time_log_fact_sheet.R"
#     "defect_log_fact_sheet.R"
#     "size_log_fact_sheet.R"
#     "task_fact_sheet.R"
#     "extractDataQuality.R"
#     "extractProjectFact.R" # extract Project and Fidelity FactSheets
#
require(data.table)
require(chron)
require(DBI)
require(RMySQL)
require(knitr)
library(lattice)
#library(xlsx)
#
#

#
# set up default directory and file names
#
#####################################################################################################
## Set the directory including this file as the default work directory
#
fileExists <- file.access("set_myWorkingDirectory.txt") # returns 0 if file exists
if ( fileExists == 0 ) {
    # if file exists, read the value in the file
    myDirectory<- read.table(
        "set_myWorkingDirectory.txt",
        header=T,
        comment.char="#")
}

# set specified working directory only if both  file exists and contains non-zero length string
if ( ( fileExists == 0 ) & ( length(myDirectory$dir_name ) > 0) )  {
       setwd(paste(myDirectory$dir_name) )
   } else{
     # use the default working directory
         frame_files <- lapply(sys.frames(), function(x) x$ofile)
         frame_files <- Filter(Negate(is.null), frame_files)
         setwd(dirname(frame_files[[length(frame_files)]]))
     }

setwd("C:/SEI/Factsheets/DataQuality")
currentDirectory <- getwd()

# Get present date
presentDate <- Sys.Date()

#check for existance of outputfiles, keep upping the postpend counter until they do not exist
counter    <- 0
postPend   <- "" #empty first time through
fileExists = TRUE
while(fileExists) {
    fileExists = FALSE

    fnameTime   <- paste( currentDirectory, "/basic_time_fact_sheet_"   , presentDate , postPend,  ".csv" , sep='')
    fnameTask   <- paste( currentDirectory, "/basic_task_fact_sheet_"   , presentDate , postPend,  ".csv" , sep='')
    fnameSize   <- paste( currentDirectory, "/basic_size_fact_sheet_"   , presentDate , postPend,  ".csv" , sep='')
    fnameDefect <- paste( currentDirectory, "/basic_defect_fact_sheet_" , presentDate , postPend,  ".csv" , sep='')

    if (file.access(paste(fnameTime))   == 0) {fileExists = TRUE}
    if (file.access(paste(fnameTask))   == 0) {fileExists = TRUE}
    if (file.access(paste(fnameSize))   == 0) {fileExists = TRUE}
    if (file.access(paste(fnameDefect)) == 0) {fileExists = TRUE}
    counter  <- counter+1
    postPend <- paste("_",counter,sep='')
}

# Check the existence of select_projects.txt and Create projects list for extracting fact sheets

####
####
#################################################################################################################################
#
#
#######################################################################################
# connect to database
#
#     Read the configuration file
source("config.txt")
#
#    Connect and authenticate to a MySQL database
con<-dbConnect(m,user=MyName,password=MyPass,host='localhost',dbname=MydbName)
#
#######################################################################################
##


# Select Projects for processing. List should be in a configuration file
#
tab_project_info<-dbGetQuery(con, "
  SELECT project_key,
         Quote(project_name) AS project_name
  FROM   project
")

if (file.access("select_projects.txt") != 0) {
  unit <- unique(tab_project_info$project_key)
} else {
  # Read project selection from text file
  pj_selection <- read.table("select_projects.txt", header=T, comment.char="#")
  if (length(pj_selection$project_key) == 0) {
    unit <- unique(tab_project_info$project_key)
  } else {
    unit <- unique(pj_selection$project_key)
  }
}

str_unit <- paste(unit,collapse=",")  # list of projects


if(FALSE){
## Execute Data Quality
## Generate data quality report
source("extractDataQuality.R")
extractDataQuality(con, currentDirectory)


## Basic fact sheets are extracted from SEMPR by using MysQL selection  without additional processing
## Extract Basic fact sheets using variables defined above for
#    projects listed in "str_unit" 
#    output  filename and path
#
#source("defect_log_fact_sheet.R")

source("time_log_fact_sheet.R")
source("defect_fact_table.R")
source("size_log_fact_sheet.R")
source("task_fact_sheet.R")
}
# extract Project and Fidelity FactSheets
source("extractProjectFact.R")
extractProjectFact(con, currentDirectory)

