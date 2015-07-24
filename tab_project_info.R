tab_project_info<-dbGetQuery(con,paste("
 SELECT project.project_key, 
	    quote(project_name)
FROM project 
WHERE project_key IN (", str_unit, ")
", seq=""))
