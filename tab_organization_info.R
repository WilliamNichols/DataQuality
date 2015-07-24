tab_organization_info<-dbGetQuery(con, paste("
  SELECT    project_key,
            org_mapping.organization_key,
            Quote(organization_name) AS organization_name
  FROM      organization
  LEFT JOIN org_mapping
         ON        organization.organization_key = org_mapping.organization_key
      WHERE     project_key IN (", str_unit, ")
", seq=""))
