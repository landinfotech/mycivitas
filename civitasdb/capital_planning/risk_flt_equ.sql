CREATE OR REPLACE VIEW public.risk_flt_equ
 AS
 SELECT feature_base.id AS feature_id,
    feature_base.system_id,
    system.name AS system_name,
    community.id AS community_id,
    community.name AS community_name,
    feature_base.class_id,
    asset_class.name AS class_name,
    asset_class.description AS class_description,
    feature_base.sub_class_id,
    asset_sub_class.name AS sub_class_name,
    feature_base.type_id,
    asset_type.name AS type_name,
    feature_base.description,
    feature_projection.remaining_years,
    feature_pof.pof AS pof_id,
    pof.name AS pof_name,
    feature_base.cof AS cof_id,
    cof.name AS cof_name,
    feature_risk.risk_value,
    feature_risk.risk_level,
    feature_calculation.renewal_cost,
    feature_calculation.age
   FROM feature_base
     LEFT JOIN feature_projection ON feature_projection.feature_id = feature_base.id
     LEFT JOIN system ON feature_base.system_id = system.id
     LEFT JOIN community ON system.community_id = community.id
     LEFT JOIN asset_class ON asset_class.id = feature_base.class_id
     LEFT JOIN asset_sub_class ON asset_sub_class.id = feature_base.sub_class_id
     LEFT JOIN asset_type ON asset_type.id = feature_base.type_id
     LEFT JOIN feature_pof ON feature_pof.feature_id = feature_base.id
     LEFT JOIN pof ON feature_pof.pof = pof.id
     LEFT JOIN cof ON feature_base.cof = cof.id
     LEFT JOIN feature_calculation ON feature_calculation.feature_id = feature_base.id
     LEFT JOIN feature_risk ON feature_risk.feature_id = feature_base.id
     LEFT JOIN user_community ON system.community_id = user_community.community_id
  WHERE (feature_base.class_id = 6 OR feature_base.class_id = 8) AND (user_community.user_name = CURRENT_USER OR CURRENT_USER = 'doadmin'::name OR CURRENT_USER = 'technician'::name);

ALTER TABLE public.risk_flt_equ
    OWNER TO doadmin;

GRANT ALL ON TABLE public.risk_flt_equ TO doadmin;
GRANT SELECT ON TABLE public.risk_flt_equ TO technician;
