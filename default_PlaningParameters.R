   default_Req_DIR   <- 0.25	 # only major defects
   default_ReqI_DRR  <- 0.50	 # only major defects
   default_HLD_DIR   <- 0.25     # only major defects
   default_HLDI_DRR  <- 0.50     # only major defects
   default_DLD_DIR   <- 0.75	 # only major defects
   default_DIDR_DRR  <- 1.5	     #     Only design defects
   default_DLDI_DRR	 <- 0.5	     #Only design defects
   default_Code_DIR	 <- 2.0	     #All defects
   default_CodeR_DRR <- 4.0	     #All defects in source LOC
   default_Commp_DIR <- 0.3	     #Any defects
   default_CodeI_DRR <- 1.0      #  All defects in source LOC
   default_UT_DIR    <- 0.067	 # Any defects
   
   
#Phase Yields		
   default_ReqI_Yield		<- 0.70#	Not counting editorial comments
   default_HLDR_Yield		<- 0.70#	Using state analysis, trace tables
   default_HLDI_Yield		<- 0.70#	Using state analysis, trace tables
   default_DLDR_Yield		<- 0.70#	Using state analysis, trace tables
   default_DLDI_Yield		<- 0.70#	Using state analysis, trace tables	   CodeR_Yield		<- 70#	Using personal checklists
   default_CodeI_Yield		<- 0.70#	Using personal checklists
   default_Compile_Yield	<- 0.50#	90+ # of syntax defects
   default_UT_Yield_Yield   <-  0.90    #- at 5 or less defects/KLOC	<- 90#	For high defects/KLOC - 50-75#
   default_BIT_Yield        <- 0.8      #at < 1.0 defects/KLOC	<- 80#	For high defects/KLOC - 30-65#
   default_ST_Yield         <- 0.8      #at < 1.0 defects/KLOC	<- 80#	For high defects/KLOC - 30-65#
   default_AT_Yield         <-   0.65   #at < 1.0 defects/KLOC	<- 65#	For high defects/KLOC - 30#

#   Before compile	>75#	Assuming sound design methods
#   Before unit test	> 85#	Assuming logic checks in reviews
#   Before integration test	> 97.5#	For small products, 1 defect max.
#   Before system test	> 99#	For small products, 1 defect max.

#   PLAN	2.00	0.00	0.00
#   REQ	2.00	0.25	0.00
#   STP	2.50	0.00	0.00
#   REQINSP	5.00	0.00	0.70
#   HLD	7.00	0.25	0.00
#   ITP	5.00	0.00	0.00
#   HLDINSP	3.00	0.00	0.70
#   DLD	11.50	0.75	0.00
#   LDR	5.00	0.00	0.70
#   TD	5.00	0.00	0.00
#   DLDINSP	10.00	0.00	0.70
#   CODE	15.00	2.00	0.00
#   CR	5.00	0.00	0.70
#   COMPILE	1.00	0.30	0.50
#   CODEINSP	9.00	0.00	0.70
#   UT	3.00	0.07	0.90
#   IT	3.00	0.00	0.80
#   ST	5.00	0.00	0.80
#   PM	1.00		0.65

