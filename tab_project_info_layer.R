tab_project_info_layer<-dbGetQuery(con,
  "
     select project.project_key, 
	        quote(project_name) as project_name, 
			parent_project_key, 
			project_pattern 
	from project 
	     left join project_layer on project.project_key = project_layer.project_key
  "
   )
