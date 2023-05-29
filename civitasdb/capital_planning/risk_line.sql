CREATE VIEW risk_line AS
	SELECT 
	feature_base.id as feature_id,
	feature_geometry.geom_line,
	feature_base.system_id,
	system.name as system_name,
	community.id as community_id,
	community.name as community_name,
	feature_base.class_id as class_id,
	asset_class.name as class_name,
	asset_class.description as class_description,
	feature_base.sub_class_id as sub_class_id,
	asset_sub_class.name as sub_class_name,
	feature_base.type_id as type_id,
	asset_type.name as type_name,
	feature_base.description,
	feature_pof.pof as pof_id,
	pof.name as pof_name,
	feature_base.cof as cof_id,
	cof.name as cof_name,
	feature_risk.risk_value,
	feature_risk.risk_level
FROM
	feature_base
LEFT JOIN feature_geometry
	ON feature_geometry.feature_id = feature_base.id
LEFT JOIN system
	ON feature_base.system_id = system.id
LEFT JOIN community
	ON system.community_id = community.id
LEFT JOIN asset_class
	ON asset_class.id = feature_base.class_id
LEFT JOIN asset_sub_class
	ON asset_sub_class.id = feature_base.sub_class_id
LEFT JOIN asset_type
	ON asset_type.id = feature_base.type_id
LEFT JOIN feature_pof
	ON feature_pof.feature_id = feature_base.id
LEFT JOIN pof
	ON feature_pof.pof = pof.id
LEFT JOIN cof
	ON feature_base.cof = cof.id
LEFT JOIN feature_risk
	ON feature_risk.feature_id = feature_base.id
LEFT JOIN user_community
	ON system.community_id = user_community.community_id
WHERE 
	feature_geometry.geom_line IS NOT NULL AND 
	(user_community.user_name = CURRENT_USER OR CURRENT_USER = 'doadmin'::name OR CURRENT_USER = 'technician'::name);

GRANT SELECT ON TABLE public.risk_line TO technician;
