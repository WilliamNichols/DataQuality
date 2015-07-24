#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Master file for the integration tool which extract data from SEMPRE
# 2014/7/17
# Yasutaka Shirai
# Updated: 2014/9/14, Yasutaka Shirai
# Update MySQL command for extracting basic fact sheet
# Updated: 2015/3/5, Yasutaka Shirai
# Update MySQL command for extracting fact sheets for specific projects
# Updated: 2015/4/11, Yasutaka Shirai
# Modify SQL command for extracting basic fact sheets by adding "row_current_flag = 1"
#wrn: added control file to optionally reset default directory
#wrn reformatted sql commands for readability
#wrn added test to prevent

require(data.table)
require(chron)
require(DBI)
require(RMySQL)
require(knitr)
library(lattice)
#library(xlsx)

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
setwd("C:/doc/experiment")
myDirectory <- setwd("C:/doc/experiment")

#GEt current directory path
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
                     #
## Read the configuration file
#
source("config.txt")

## Connect and authenticate to a MySQL database
con<-dbConnect(m,user=MyName,password=MyPass,host='localhost',dbname=MydbName)

                                        #
# Select Projects for processing. List should be in a configuration file
#
# Check the existnece of select_projects.txt and Create projects list for extracting fact sheets
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

str_unit <- paste(unit,collapse=",")

#
# Extract Project fact sheet and Project process fidelity sheet

#
source("extractProjectFact.R")
#source("extractProjectFact_ys_2015.05.29.R")
extractProjectFact(con, currentDirectory)

## Execute verifying Data Quality


## Extract Basic fact sheets
# Basic fact sheets are extracted from SEMPR by using MysQL command direcly
# Extract Time fact sheet

dbGetQuery(con, paste("
   SELECT 'time_log_fact_key',       'project_key',                    'person_key',                       'team_key',
           'wbs_element_key',        'plan_item_key',                  'time_log_start_date',              'time_log_end_date',
           'time_log_delta_minutes', 'time_log_interrupt_minutes',      'phase_key',                       'phase_short_name',
           'phase.process_key',      'process_name',                    'row_current_flag'
   UNION (
   SELECT time_log_fact_key,         project_key,                       person_key,                         team_key,
           wbs_element_key,          time_log_fact_hist.plan_item_key,  time_log_start_date,                time_log_end_date,
           time_log_delta_minutes,   time_log_interrupt_minutes,        plan_item_hist.phase_key,           phase_short_name,
           phase.process_key,         process_name,                     time_log_fact_hist.row_current_flag
    FROM         time_log_fact_hist
      LEFT JOIN  data_block     ON time_log_fact_hist.data_block_key = data_block.data_block_key
      LEFT JOIN  plan_item_hist ON time_log_fact_hist.plan_item_key  = plan_item_hist.plan_item_key
      LEFT JOIN  phase          ON plan_item_hist.phase_key          = phase.phase_key
      LEFT JOIN  process        ON phase.process_key                 = process.process_key
    WHERE   project_key IN (", str_unit, ")
      AND   time_log_fact_hist.row_current_flag  = 1
      AND   plan_item_hist.row_current_flag      = 1
    ORDER BY time_log_fact_key, project_key
    INTO OUTFILE \"",   fnameTime, "\""  , "
    FIELDS TERMINATED BY ','
   )# end union
                    " , sep=""
                      )
           )


# Extract defect fact sheet

dbGetQuery( con,
            paste
            ("
          SELECT  'defect_log_fact_key',       'project_key',                      'person_key',               'team_key',
                  'wbs_element_key',           'plan_item_key',                    'defect_fix_count',         'defect_fix_time_minutes',
                  'defect_found_date',         'defect_type_key',                  'defect_removed_phase_key', 'removed_phase.phase_short_name',
                  'defect_injected_phase_key', 'injected_phase.phase_short_name',  'defect_found_date_key',    'removed_phase.process_key',
                  'process_name',              'row_current_flag'
          UNION    (
          SELECT   defect_log_fact_key,         project_key,                        person_key,                  team_key,
                   wbs_element_key,             defect_log_fact_hist.plan_item_key, defect_fix_count,            defect_fix_time_minutes,
                   defect_found_date,           defect_type_key,                    defect_removed_phase_key,    removed_phase.phase_short_name,
                   defect_injected_phase_key,   injected_phase.phase_short_name,    defect_found_date_key,       removed_phase.process_key,
                   process_name,                defect_log_fact_hist.row_current_flag
          FROM     defect_log_fact_hist
                   LEFT JOIN data_block              ON defect_log_fact_hist.data_block_key            = data_block.data_block_key
                   LEFT JOIN plan_item_hist          ON defect_log_fact_hist.plan_item_key             = plan_item_hist.plan_item_key
                   LEFT JOIN phase AS injected_phase ON defect_log_fact_hist.defect_injected_phase_key = injected_phase.phase_key
                   LEFT JOIN phase AS removed_phase  ON defect_log_fact_hist.defect_removed_phase_key  = removed_phase.phase_key
                   LEFT JOIN process                 ON removed_phase.process_key                      = process.process_key
             WHERE project_key IN (", str_unit ,")
               AND defect_log_fact_hist.row_current_flag = 1
               AND plan_item_hist.row_current_flag       = 1
          ORDER BY defect_log_fact_key, project_key
          INTO OUTFILE \"",   fnameDefect, "\""   , "
          FIELDS TERMINATED by ','
                   ) # end Union
          " , sep=""
          ) #end paste
 )
#          INTO OUTFILE \"basic_defect_fact_sheet_", presentDate,".csv\"

# Extract size fact sheet
dbGetQuery( con ,
            paste
            (
                "SELECT 'size_fact_key',    'project_key',                       'person_key',              'team_key',
                         'wbs_element_key',  'plan_item_key',                     'size_added_and_modified', 'size_added',
                         'size_base',        'size_deleted',                      'size_modified',           'size_reused',
                         'size_total',       'measurement_type_key',              'measurement_type_name',   'size_metric_key',
                         'size_metric_name', 'size_metric_short_name',            'phase_key',               'phase_short_name',
                         'process_key',      'process_name',                      'row_current_flag'
                  UNION
                  (
                  SELECT  size_fact_key,      project_key,                         person_key,                team_key,
                          wbs_element_key,    size_fact_hist.plan_item_key,        size_added_and_modified,   size_added,
                          size_base,          size_deleted,                        size_modified,             size_reused,
                          size_total,         size_fact_hist.measurement_type_key, measurement_type_name,     size_fact_hist.size_metric_key,
                          size_metric_name,   size_metric_short_name,              plan_item_hist.phase_key,  phase_short_name,
                          phase.process_key,  process_name, size_fact_hist.row_current_flag
                  FROM         size_fact_hist
                    LEFT JOIN  data_block      ON size_fact_hist.data_block_key       = data_block.data_block_key
                    LEFT JOIN  plan_item_hist  ON size_fact_hist.plan_item_key        = plan_item_hist.plan_item_key
                    LEFT JOIN  phase           ON plan_item_hist.phase_key            = phase.phase_key
                    LEFT JOIN  process          ON phase.process_key                   = process.process_key
                    LEFT JOIN  measurement_type ON size_fact_hist.measurement_type_key = measurement_type.measurement_type_key
                    LEFT JOIN  size_metric      ON size_fact_hist.size_metric_key      = size_metric.size_metric_key
                    WHERE    project_key IN (", str_unit, ")
                      AND    size_fact_hist.row_current_flag = 1
                      AND    plan_item_hist.row_current_flag = 1
                  ORDER BY  size_fact_key, project_key
          INTO OUTFILE \"",   fnameSize, "\""   , "
          FIELDS TERMINATED by ','
                  ) # end UNION
           " , sep=""
            ) # end paste
           )
#                  INTO OUTFILE \"basic_size_fact_sheet_", presentDate,".csv\"
#                  FIELDS TERMINATED by ','

# Extract task fact sheet
 dbGetQuery(con,
            paste
             (
              "SELECT 'task_status_fact_key',          'project_key',                   'person_key',
                      'team_key',                      'wbs_element_key',               'plan_item_key',
                      'task_actual_start_date',        'task_actual_complete_date',     'task_actual_time_minutes',
                      'task_plan_time_minutes',        'task_plan_date_key',            'task_actual_start_date_key',
                      'task_actual_complete_date_key', 'phase_key',                     'phase_short_name',
                      'process_key',                   'process_name'
               UNION
               (
                SELECT task_status_fact_key,             project_key,                     person_key,
                       team_key,                         wbs_element_key,                 task_status_fact_hist.plan_item_key AS plan_item_key,
                       task_actual_start_date,           task_actual_complete_date,       task_actual_time_minutes,
                       task_plan_time_minutes,           task_date_fact_hist.task_date_key AS task_plan_date_key, task_actual_start_date_key,
                       task_actual_complete_date_key,    plan_item.phase_key,             phase_short_name,
                       phase.process_key AS process_key, process_name
                FROM        task_status_fact_hist
                  LEFT JOIN task_date_fact_hist ON (    task_status_fact_hist.plan_item_key  = task_date_fact_hist.plan_item_key
                                                  AND task_status_fact_hist.data_block_key = task_date_fact_hist.data_block_key
                                                  )
                  LEFT JOIN plan_item  ON task_status_fact_hist.plan_item_key     = plan_item.plan_item_key
                  LEFT JOIN data_block ON task_status_fact_hist.data_block_key    = data_block.data_block_key
                  LEFT JOIN phase      ON plan_item.phase_key                     = phase.phase_key
                  LEFT JOIN process    ON  phase.process_key                      = process.process_key
                  WHERE   measurement_type_key = 1
                    AND task_status_fact_hist.row_current_flag = 1
                    AND task_date_fact_hist.row_current_flag   = 1
                    AND plan_item.plan_item_deleted_flag       = 0
                    AND project_key IN (", str_unit, ")
                ORDER BY task_status_fact_key
                INTO OUTFILE \"",   fnameTask, "\""  , "
                FIELDS TERMINATED by ','
               )   # end union
               " , sep=""
             ) # end paste
            )  #end query

#                INTO OUTFILE \"basic_task_fact_sheet_", presentDate, ".csv\" fields terminated by ','
#                  INTO OUTFILE \"basic_size_fact_sheet_", presentDate,".csv\"

# Extract Component fact sheet and Component process fidelity sheet
#source("extractComponentFact.R")
##extractComponentFact(con, currentDirectory)

## Generate data quality report
##  source("extractDataQuality.R")
##  extractDataQuality(con, currentDirectory)
#knitr::knit("data_quality_report.Rmd")
#rmd_analysis_dq <- knit("data_quality_report.Rmd")
#pandoc(rmd_analysis_dq, format='docx')

## Extract digits evaluation sheet
## source("examineDigitsEvaluation.R")
# #examineDigitsEvaluation(con, currentDirectory)

## Generate production rate report
#knitr::knit("examineFitDist-of-ProductionRate.Rmd")

## Generate docx report
#rmd_analysis_all <- knit("examineStatAnalysis-of-AllWorkItem_DLD-UT.Rmd")
#pandoc(rmd_analysis_all, format='docx')

#rmd_analysis_PR_pj <- knit("examineFitDist-of-ProductionRate-byPj_DLD-UT.Rmd")
#pandoc(rmd_analysis_PR_pj, format='docx')

#rmd_analysis_PR_ind <- knit("examineFitDist-of-ProductionRate-byInd_DLD-UT.Rmd")
#pandoc(rmd_analysis_PR_ind, format='docx')

#rmd_analysis_DIR_pj <- knit("examineFitDist-of-DefectInjectionRate-byPj_DLD-UT.Rmd")
#pandoc(rmd_analysis_DIR_pj, format='docx')

#rmd_analysis_DIR_ind <- knit("examineFitDist-of-DefectInjectionRate-byInd_DLD-UT.Rmd")
#pandoc(rmd_analysis_DIR_ind, format='docx')

#rmd_analysis_DRR_pj <- knit("examineFitDist-of-DefectRemovalRate-byPj_DLD-UT.Rmd")
#pandoc(rmd_analysis_DRR_pj, format='docx')

#rmd_analysis_DRR_ind <- knit("examineFitDist-of-DefectRemovalRate-byInd_DLD-UT.Rmd")
#pandoc(rmd_analysis_DRR_ind, format='docx')

#rmd_analysis_all <- knit("examineProjectCharacteristics.Rmd")
#pandoc(rmd_analysis_all, format='docx')

#rmd_analysis_benford <- knit("examineDigitsEvaluation.Rmd")
#pandoc(rmd_analysis_benford, format='docx')

#rmd_analysis_PY <- knit("examinePhaseYield_DLD-UT_PJ.Rmd")
#pandoc(rmd_analysis_PY, format='docx')

#rmd_analysis_BN <- knit("executeBayesianNetwork.Rmd")
#pandoc(rmd_analysis_BN, format='docx')

#rmd_analysis_MC <- knit("execMCSimulation.Rmd")
#pandoc(rmd_analysis_MC, format='docx')

