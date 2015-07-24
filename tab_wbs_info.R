tab_wbs_info<-dbGetQuery(con, paste("
  SELECT plan_item.wbs_element_key,
       plan_item.project_key,
       wbs_element.wbs_element_name
  FROM plan_item ,
       wbs_element
    WHERE plan_item.plan_item_leaf_element_flag=1
       AND plan_item.wbs_element_key = wbs_element.wbs_element_key
       AND project_key IN (", str_unit, ")
	   " ,  seq="" ))