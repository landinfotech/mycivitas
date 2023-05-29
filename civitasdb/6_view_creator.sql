-- -- CREATE VIEWS -- --
CREATE MATERIALIZED VIEW feature_quantity AS

	SELECT
		feature_base.id AS feature_id,
		1 as count,
		length.value_text::numeric(10,2) AS length,
	 	area.value_text::numeric(10,2) AS area
		
	FROM feature_base
	
	LEFT JOIN feature_property AS length
		ON (length.property_id = 6 AND length.feature_id = feature_base.id)
	LEFT JOIN feature_property AS area
		ON (area.property_id = 8 AND area.feature_id = feature_base.id)
;
	
ALTER TABLE feature_quantity
	OWNER TO doadmin
;

CREATE MATERIALIZED VIEW feature_unit AS

	SELECT 
		feature_base.id AS feature_id,
		asset_sub_class.unit_id
		
	FROM feature_base, asset_sub_class
	
	WHERE feature_base.sub_class_id = asset_sub_class.id
;

ALTER TABLE feature_unit
    OWNER TO doadmin
;

CREATE MATERIALIZED VIEW feature_calculation_lookup AS

SELECT
	feature_base.id AS feature_id,
		
	CASE
		WHEN feature_unit.unit_id = 1
		THEN feature_quantity.count
		
		WHEN feature_unit.unit_id = 2
		THEN feature_quantity.length
		
		WHEN feature_unit.unit_id = 3
		THEN feature_quantity.area
	END AS quantity,
	
	CASE
		WHEN feature_base.renewal_cost IS NULL
		THEN 'lookup'
		
		WHEN feature_base.renewal_cost IS NOT NULL
		THEN 'input'
	END AS renewal_cost_method,
	
	CASE 
		WHEN feature_base.maintenance_cost IS NULL
		THEN 'lookup'
		
		WHEN feature_base.maintenance_cost IS NOT NULL
		THEN 'input'
	END AS maintenance_cost_method,
	
	CASE 
		WHEN feature_base.lifespan IS NULL
		THEN 'lookup'
		
		WHEN feature_base.lifespan IS NOT NULL
		THEN 'input'
	END AS lifespan_method,
	
	CASE
		WHEN feature_base.condition_id IS NOT NULL
		THEN 'condition based'
		
		WHEN (feature_base.condition_id IS NULL AND feature_base.install_date IS NOT NULL)
		THEN 'age based'
		
		WHEN (feature_base.condition_id IS NULL AND feature_base.install_date IS NULL)
		THEN 'none available'
	END AS remaining_years_method,
	
	deterioration.name AS deterioration_name,
	deterioration.id AS deterioration_id
	
	FROM feature_base, feature_unit, feature_quantity, deterioration, asset_sub_class
	
	WHERE 	
		feature_base.id = feature_unit.feature_id AND
		feature_base.id = feature_quantity.feature_id AND
		feature_base.sub_class_id = asset_sub_class.id AND
		asset_sub_class.deterioration_id = deterioration.id
;


ALTER TABLE feature_calculation_lookup
	OWNER TO doadmin
;

CREATE MATERIALIZED VIEW feature_calculation AS
	SELECT 
		feature_base.id AS feature_id,
		
		CASE
			WHEN feature_calculation_lookup.renewal_cost_method = 'lookup'
			THEN feature_calculation_lookup.quantity * asset_type.unit_renewal_cost
			
			WHEN feature_calculation_lookup.renewal_cost_method = 'input'
			THEN feature_base.renewal_cost
		END ::numeric(11,2) AS renewal_cost,
		

		CASE
			WHEN feature_calculation_lookup.maintenance_cost_method = 'lookup'
			THEN feature_calculation_lookup.quantity * asset_type.unit_maintenance_cost
			
			WHEN feature_calculation_lookup.renewal_cost_method = 'input'
			THEN feature_base.maintenance_cost
		END ::numeric(11,2) AS maintenance_cost,
		
		CASE
			WHEN feature_calculation_lookup.lifespan_method = 'lookup'
			THEN asset_type.lifespan
			
			WHEN feature_calculation_lookup.lifespan_method = 'input'
			THEN feature_base.lifespan
		END ::integer as lifespan,
		
		CASE
			WHEN feature_base.install_date IS NOT NULL
			THEN date_part('year'::text, CURRENT_DATE)::integer - date_part('year'::text, feature_base.install_date)
			
			WHEN feature_base.install_date IS NULL
			THEN NULL
		END ::integer AS age
	
	FROM feature_base, feature_calculation_lookup, asset_type
	
	WHERE 	
		feature_base.id = feature_calculation_lookup.feature_id AND
		feature_base.type_id = asset_type.id
;

ALTER TABLE feature_calculation
	OWNER TO doadmin
;

CREATE MATERIALIZED VIEW feature_projection AS
	SELECT 
	feature_base.id AS feature_id,
	function_remaining_years(
		feature_base.condition_id, 
		feature_calculation_lookup.deterioration_id, 
		feature_calculation.age, 
		feature_calculation.lifespan, 
		feature_calculation_lookup.remaining_years_method,
		feature_base.inspection_date)
	AS remaining_years,
	((feature_calculation.renewal_cost/feature_calculation.lifespan))::numeric(11,2) as annual_reserve
	
	
	FROM feature_base, feature_calculation_lookup, feature_calculation

	WHERE feature_base.id = feature_calculation_lookup.feature_id AND feature_base.id = feature_calculation.feature_id
;

ALTER TABLE feature_projection
	OWNER TO doadmin
;
	
CREATE MATERIALIZED VIEW feature_pof AS 
	SELECT
		feature_base.id AS feature_id,
		function_remaining_years_to_pof(feature_projection.remaining_years) AS pof
	FROM feature_base, feature_projection
	WHERE feature_base.id = feature_projection.feature_id
;

ALTER TABLE feature_pof
	OWNER TO doadmin
;

CREATE MATERIALIZED VIEW public.feature_risk AS
	SELECT 
		feature_base.id AS feature_id,
		risk_lookup.risk_value,
		risk_lookup.risk_level
	FROM feature_base, risk_lookup, feature_pof
	WHERE (feature_base.id = feature_pof.feature_id) AND 
	(risk_lookup.pof_value = feature_pof.pof) AND 
	(risk_lookup.cof_value = feature_base.cof)
;

ALTER TABLE public.feature_risk
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.feature_risk TO reader;
GRANT ALL ON TABLE public.feature_risk TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.feature_risk TO technician;

CREATE MATERIALIZED VIEW public.reporter_data
 AS
 SELECT province.id AS province_id,
    province.name AS province_name,
    region.id AS region_id,
    region.name AS region_name,
    community.id AS community_id,
    community.name AS community_name,
    system.id AS system_id,
    system.name AS system_name,
    feature_base.id AS feature_id,
    feature_quantity.length,
    feature_quantity.area,
    feature_calculation_lookup.quantity,
    feature_calculation_lookup.renewal_cost_method,
    feature_calculation_lookup.maintenance_cost_method,
    feature_calculation_lookup.lifespan_method,
    feature_calculation_lookup.remaining_years_method,
    feature_calculation_lookup.deterioration_name,
    feature_calculation.renewal_cost,
    feature_calculation.maintenance_cost,
    feature_calculation.lifespan,
    feature_calculation.age,
    feature_projection.remaining_years,
    feature_projection.annual_reserve,
    feature_pof.pof AS pof_id,
    pof.name AS pof_name,
    feature_base.cof AS cof_id,
    cof.name AS cof_name,
    feature_risk.risk_value,
    feature_risk.risk_level,
    feature_base.condition_id,
    condition.name AS condition_name,
    feature_base.class_id,
    asset_class.name AS class_name,
    asset_class.description AS class_description,
    feature_base.sub_class_id,
    asset_sub_class.name AS sub_class_name,
    asset_sub_class.description AS sub_class_description,
    asset_sub_class.deterioration_id AS sub_class_deterioration_id,
    asset_sub_class.unit_id AS sub_class_unit_id,
    unit.name AS sub_class_unit_name,
    unit.description AS sub_class_unit_description,
    feature_base.type_id,
    asset_type.name AS asset_type_name,
    asset_type.description AS asset_type_description
   FROM ((((((((((((((((((feature_base
     LEFT JOIN system ON ((feature_base.system_id = system.id)))
     LEFT JOIN community ON ((system.community_id = community.id)))
     LEFT JOIN region ON ((community.region_id = region.id)))
     LEFT JOIN province ON ((region.province_id = province.id)))
     LEFT JOIN condition ON ((feature_base.condition_id = condition.id)))
     LEFT JOIN asset_class ON ((feature_base.class_id = asset_class.id)))
     LEFT JOIN asset_sub_class ON ((feature_base.sub_class_id = asset_sub_class.id)))
     LEFT JOIN asset_type ON ((feature_base.type_id = asset_type.id)))
     LEFT JOIN unit ON ((asset_sub_class.unit_id = unit.id)))
     LEFT JOIN deterioration ON ((asset_sub_class.deterioration_id = deterioration.id)))
     LEFT JOIN feature_quantity ON ((feature_base.id = feature_quantity.feature_id)))
     LEFT JOIN feature_calculation_lookup ON ((feature_base.id = feature_calculation_lookup.feature_id)))
     LEFT JOIN feature_calculation ON ((feature_base.id = feature_calculation.feature_id)))
     LEFT JOIN feature_projection ON ((feature_base.id = feature_projection.feature_id)))
     LEFT JOIN feature_pof ON ((feature_base.id = feature_pof.feature_id)))
     LEFT JOIN feature_risk ON ((feature_base.id = feature_risk.feature_id)))
     LEFT JOIN pof ON ((feature_pof.pof = pof.id)))
     LEFT JOIN cof ON ((feature_base.cof = cof.id)));

ALTER TABLE public.reporter_data
    OWNER TO doadmin;

GRANT ALL ON TABLE public.reporter_data TO doadmin;
GRANT SELECT ON TABLE public.reporter_data TO reporter;

-- WATER --
-- water valve --

--create qgis layer
CREATE OR REPLACE VIEW public.water_valve
 AS
 SELECT 
	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id, 
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan,
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 5))) AS diameter,
	feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE (feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'water_valve'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER )OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name));

ALTER TABLE public.water_valve
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.water_valve TO reader;
GRANT ALL ON TABLE public.water_valve TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.water_valve TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.water_valve
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(1, 10, 'water_valve');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.water_valve
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.water_valve
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.water_valve
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.water_valve
    FOR EACH ROW
    EXECUTE PROCEDURE public.valve_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.water_valve
    FOR EACH ROW
    EXECUTE PROCEDURE public.valve_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.water_valve
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view --
CREATE MATERIALIZED VIEW public.web_water_valve
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
    parent.diameter,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM water_valve AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_water_valve
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_water_valve TO reader;
GRANT ALL ON TABLE public.web_water_valve TO doadmin;

CREATE UNIQUE INDEX ON web_water_valve (feature_id);
-- end water valve

-- water treatment --
-- create qgis layer
CREATE OR REPLACE VIEW public.water_treatment
 AS
 SELECT 
	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id, 
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan,
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'water_treatment'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.water_treatment
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.water_treatment TO reader;
GRANT ALL ON TABLE public.water_treatment TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.water_treatment TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.water_treatment
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(1, 9, 'water_treatment');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.water_treatment
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.water_treatment
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.water_treatment
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.water_treatment
    FOR EACH ROW
    EXECUTE PROCEDURE public.treatment_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.water_treatment
    FOR EACH ROW
    EXECUTE PROCEDURE public.treatment_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.water_treatment
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_water_treatment
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM water_treatment AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_water_treatment
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_water_treatment TO reader;
GRANT ALL ON TABLE public.web_water_treatment TO doadmin;

CREATE UNIQUE INDEX ON web_water_treatment (feature_id);
-- end water treatment

-- water tank --
-- create qgis layer
CREATE OR REPLACE VIEW public.water_tank
 AS
 SELECT 
	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id, 
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan,
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 11))) AS capacity,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'water_tank'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.water_tank
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.water_tank TO reader;
GRANT ALL ON TABLE public.water_tank TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.water_tank TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.water_tank
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(1, 8, 'water_tank');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.water_tank
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.water_tank
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.water_tank
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.water_tank
    FOR EACH ROW
    EXECUTE PROCEDURE public.tank_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.water_tank
    FOR EACH ROW
    EXECUTE PROCEDURE public.tank_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.water_tank
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();
	
-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_water_tank
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM water_tank AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_water_tank
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_water_tank TO reader;
GRANT ALL ON TABLE public.web_water_tank TO doadmin;

CREATE UNIQUE INDEX ON web_water_tank (feature_id);
-- end water tank

-- water reservoir --



-- create qgis layer
CREATE OR REPLACE VIEW public.water_reservoir
 AS
 SELECT 
	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan,
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 11))) AS capacity,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'water_reservoir'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.water_reservoir
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.water_reservoir TO reader;
GRANT ALL ON TABLE public.water_reservoir TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.water_reservoir TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.water_reservoir
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(1, 15, 'water_reservoir');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.water_reservoir
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.water_reservoir
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.water_reservoir
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.water_reservoir
    FOR EACH ROW
    EXECUTE PROCEDURE public.reservoir_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.water_reservoir
    FOR EACH ROW
    EXECUTE PROCEDURE public.reservoir_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.water_reservoir
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_water_reservoir
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	parent.capacity,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM water_reservoir AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_water_reservoir
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_water_reservoir TO reader;
GRANT ALL ON TABLE public.web_water_reservoir TO doadmin;

CREATE UNIQUE INDEX ON web_water_reservoir (feature_id);
-- end water_reservoir

-- water pump --



-- create qgis layer
CREATE OR REPLACE VIEW public.water_pump
 AS
 SELECT 
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan,
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'water_pump'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.water_pump
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.water_pump TO reader;
GRANT ALL ON TABLE public.water_pump TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.water_pump TO technician;

-- create trigger for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.water_pump
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(1, 7, 'water_pump');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.water_pump
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.water_pump
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.water_pump
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.water_pump
    FOR EACH ROW
    EXECUTE PROCEDURE public.pump_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.water_pump
    FOR EACH ROW
    EXECUTE PROCEDURE public.pump_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.water_pump
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();
	
-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_water_pump
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM water_pump AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_water_pump
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_water_pump TO reader;
GRANT ALL ON TABLE public.web_water_pump TO doadmin;

CREATE UNIQUE INDEX ON web_water_pump (feature_id);
-- end water pump	
	
-- water pipe --

-- create qgis layer
CREATE OR REPLACE VIEW public.water_pipe
 AS
 SELECT 
  	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan,
    feature_geometry.geom_line,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 4))) AS material,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 5))) AS diameter,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 6))) AS length,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'water_pipe'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.water_pipe
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.water_pipe TO reader;
GRANT ALL ON TABLE public.water_pipe TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.water_pipe TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.water_pipe
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(1, 6, 'water_pipe');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.water_pipe
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.water_pipe
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_line_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.water_pipe
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_line_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.water_pipe
    FOR EACH ROW
    EXECUTE PROCEDURE public.pipe_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.water_pipe
    FOR EACH ROW
    EXECUTE PROCEDURE public.pipe_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.water_pipe
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_water_pipe
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_line,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	parent.material,
	parent.diameter,
	parent.length,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM water_pipe AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_water_pipe
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_water_pipe TO reader;
GRANT ALL ON TABLE public.web_water_pipe TO doadmin;

CREATE UNIQUE INDEX ON web_water_pipe (feature_id);
-- end water pipe

-- water part --



CREATE OR REPLACE VIEW public.water_part
 AS
 SELECT 
	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan,
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 4))) AS material,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 5))) AS diameter,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'water_part'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.water_part
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.water_part TO reader;
GRANT ALL ON TABLE public.water_part TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.water_part TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.water_part
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(1, 5, 'water_part');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.water_part
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.water_part
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.water_part
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.water_part
    FOR EACH ROW
    EXECUTE PROCEDURE public.part_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.water_part
    FOR EACH ROW
    EXECUTE PROCEDURE public.part_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.water_part
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();


-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_water_part
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	parent.material,
	parent.diameter,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM water_part AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_water_part
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_water_part TO reader;
GRANT ALL ON TABLE public.web_water_part TO doadmin;

CREATE UNIQUE INDEX ON web_water_part (feature_id);
-- end water part

-- water motor --



-- create qgis layer
CREATE OR REPLACE VIEW public.water_motor
 AS
 SELECT 
	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
	feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 10))) AS power_output,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'water_motor'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.water_motor
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.water_motor TO reader;
GRANT ALL ON TABLE public.water_motor TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.water_motor TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.water_motor
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(1, 4, 'water_motor');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.water_motor
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.water_motor
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.water_motor
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.water_motor
    FOR EACH ROW
    EXECUTE PROCEDURE public.motor_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.water_motor
    FOR EACH ROW
    EXECUTE PROCEDURE public.motor_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.water_motor
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_water_motor
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	parent.power_output,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM water_motor AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_water_motor
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_water_motor TO reader;
GRANT ALL ON TABLE public.web_water_motor TO doadmin;

CREATE UNIQUE INDEX ON web_water_motor (feature_id);
-- end water motor

-- water meter --



CREATE OR REPLACE VIEW public.water_meter
 AS
 SELECT 
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'water_meter'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.water_meter
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.water_meter TO reader;
GRANT ALL ON TABLE public.water_meter TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.water_meter TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.water_meter
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(1, 3, 'water_meter');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.water_meter
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.water_meter
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.water_meter
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.water_meter
    FOR EACH ROW
    EXECUTE PROCEDURE public.meter_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.water_meter
    FOR EACH ROW
    EXECUTE PROCEDURE public.meter_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.water_meter
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_water_meter
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM water_meter AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_water_meter
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_water_meter TO reader;
GRANT ALL ON TABLE public.web_water_meter TO doadmin;

CREATE UNIQUE INDEX ON web_water_meter (feature_id);
-- end water meter

-- water manhole trunk
-- create qgis layer
CREATE OR REPLACE VIEW public.water_manhole_trunk
 AS
 SELECT 
  	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 4))) AS material,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'water_manhole_trunk'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.water_manhole_trunk
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.water_manhole_trunk TO reader;
GRANT ALL ON TABLE public.water_manhole_trunk TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.water_manhole_trunk TO technician;

-- create triggers
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.water_manhole_trunk
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(1, 14, 'water_manhole_trunk');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.water_manhole_trunk
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.water_manhole_trunk
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.water_manhole_trunk
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.water_manhole_trunk
    FOR EACH ROW
    EXECUTE PROCEDURE public.manhole_trunk_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.water_manhole_trunk
    FOR EACH ROW
    EXECUTE PROCEDURE public.manhole_trunk_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.water_manhole_trunk
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_water_manhole_trunk
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	parent.material,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM water_manhole_trunk AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_water_manhole_trunk
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_water_manhole_trunk TO reader;
GRANT ALL ON TABLE public.web_water_manhole_trunk TO doadmin;

CREATE UNIQUE INDEX ON web_water_manhole_trunk (feature_id);
-- end water manhole trunk

-- water manhole cover



CREATE OR REPLACE VIEW public.water_manhole_cover
 AS
 SELECT 
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 4))) AS material,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 12))) AS size,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 13))) AS load_rating,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'water_manhole_cover'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.water_manhole_cover
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.water_manhole_cover TO reader;
GRANT ALL ON TABLE public.water_manhole_cover TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.water_manhole_cover TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.water_manhole_cover
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(1, 13, 'water_manhole_cover');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.water_manhole_cover
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.water_manhole_cover
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.water_manhole_cover
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.water_manhole_cover
    FOR EACH ROW
    EXECUTE PROCEDURE public.manhole_cover_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.water_manhole_cover
    FOR EACH ROW
    EXECUTE PROCEDURE public.manhole_cover_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.water_manhole_cover
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_water_manhole_cover
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	parent.material,
	parent.size,
	parent.load_rating,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM water_manhole_cover AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_water_manhole_cover
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_water_manhole_cover TO reader;
GRANT ALL ON TABLE public.web_water_manhole_cover TO doadmin;

CREATE UNIQUE INDEX ON web_water_manhole_cover (feature_id);
-- end water manhole cover

-- water hydrant
-- create qgis layer
CREATE OR REPLACE VIEW public.water_hydrant
 AS
 SELECT 
  	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'water_hydrant'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.water_hydrant
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.water_hydrant TO reader;
GRANT ALL ON TABLE public.water_hydrant TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.water_hydrant TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.water_hydrant
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(1, 2, 'water_hydrant');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.water_hydrant
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.water_hydrant
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.water_hydrant
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.water_hydrant
    FOR EACH ROW
    EXECUTE PROCEDURE public.hydrant_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.water_hydrant
    FOR EACH ROW
    EXECUTE PROCEDURE public.hydrant_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.water_hydrant
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_water_hydrant
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM water_hydrant AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_water_hydrant
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_water_hydrant TO reader;
GRANT ALL ON TABLE public.web_water_hydrant TO doadmin;

CREATE UNIQUE INDEX ON web_water_hydrant (feature_id);
-- end water hydrant

-- water control
-- create qgis layer
CREATE OR REPLACE VIEW public.water_control
 AS
 SELECT 
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'water_control'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.water_control
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.water_control TO reader;
GRANT ALL ON TABLE public.water_control TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.water_control TO technician;

-- create trigger qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.water_control
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(1, 11, 'water_control');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.water_control
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.water_control
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.water_control
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.water_control
    FOR EACH ROW
    EXECUTE PROCEDURE public.control_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.water_control
    FOR EACH ROW
    EXECUTE PROCEDURE public.control_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.water_control
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_water_control
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM water_control AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_water_control
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_water_control TO reader;
GRANT ALL ON TABLE public.web_water_control TO doadmin;

CREATE UNIQUE INDEX ON web_water_control (feature_id);
-- end water control

-- water box
-- create qgis layer
CREATE OR REPLACE VIEW public.water_box
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 4))) AS material,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'water_box'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.water_box
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.water_box TO reader;
GRANT ALL ON TABLE public.water_box TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.water_box TO technician;

-- create trigger for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.water_box
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(1, 1, 'water_box');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.water_box
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.water_box
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.water_box
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.water_box
    FOR EACH ROW
    EXECUTE PROCEDURE public.box_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.water_box
    FOR EACH ROW
    EXECUTE PROCEDURE public.box_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.water_box
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_water_box
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	parent.material,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM water_box AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_water_box
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_water_box TO reader;
GRANT ALL ON TABLE public.web_water_box TO doadmin;

CREATE UNIQUE INDEX ON web_water_box (feature_id);
-- end water box

-- WASTEWATER --

-- wastewater valve
CREATE OR REPLACE VIEW public.wastewater_valve
 AS
 SELECT 
  	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 5))) AS diameter,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'wastewater_valve'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.wastewater_valve
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.wastewater_valve TO reader;
GRANT ALL ON TABLE public.wastewater_valve TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.wastewater_valve TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.wastewater_valve
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(2, 10, 'wastewater_valve');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.wastewater_valve
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.wastewater_valve
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.wastewater_valve
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.wastewater_valve
    FOR EACH ROW
    EXECUTE PROCEDURE public.valve_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.wastewater_valve
    FOR EACH ROW
    EXECUTE PROCEDURE public.valve_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.wastewater_valve
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_wastewater_valve
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	parent.diameter,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM wastewater_valve AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_wastewater_valve
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_wastewater_valve TO reader;
GRANT ALL ON TABLE public.web_wastewater_valve TO doadmin;

CREATE UNIQUE INDEX ON web_wastewater_valve (feature_id);
-- end wastewater valve

-- wastewater treatment
-- create qgis layer
CREATE OR REPLACE VIEW public.wastewater_treatment
 AS
 SELECT 
  	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'wastewater_treatment'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.wastewater_treatment
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.wastewater_treatment TO reader;
GRANT ALL ON TABLE public.wastewater_treatment TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.wastewater_treatment TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.wastewater_treatment
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(2, 9, 'wastewater_treatment');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.wastewater_treatment
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.wastewater_treatment
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.wastewater_treatment
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.wastewater_treatment
    FOR EACH ROW
    EXECUTE PROCEDURE public.treatment_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.wastewater_treatment
    FOR EACH ROW
    EXECUTE PROCEDURE public.treatment_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.wastewater_treatment
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_wastewater_treatment
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM wastewater_treatment AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_wastewater_treatment
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_wastewater_treatment TO reader;
GRANT ALL ON TABLE public.web_wastewater_treatment TO doadmin;

CREATE UNIQUE INDEX ON web_wastewater_treatment (feature_id);
-- end wastewater treatment

-- wastewater tank
-- create qgis layer
CREATE OR REPLACE VIEW public.wastewater_tank
 AS
 SELECT 
  	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 11))) AS capacity,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'wastewater_tank'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.wastewater_tank
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.wastewater_tank TO reader;
GRANT ALL ON TABLE public.wastewater_tank TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.wastewater_tank TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.wastewater_tank
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(2, 8, 'wastewater_tank');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.wastewater_tank
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.wastewater_tank
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.wastewater_tank
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.wastewater_tank
    FOR EACH ROW
    EXECUTE PROCEDURE public.tank_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.wastewater_tank
    FOR EACH ROW
    EXECUTE PROCEDURE public.tank_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.wastewater_tank
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_wastewater_tank
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	parent.capacity,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM wastewater_tank AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_wastewater_tank
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_wastewater_tank TO reader;
GRANT ALL ON TABLE public.web_wastewater_tank TO doadmin;

CREATE UNIQUE INDEX ON web_wastewater_tank (feature_id);
-- end wastewater tank

-- wastewater reservoir
-- create qgis layer
CREATE OR REPLACE VIEW public.wastewater_reservoir
 AS
 SELECT 
	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 11))) AS capacity,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'wastewater_reservoir'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.wastewater_reservoir
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.wastewater_reservoir TO reader;
GRANT ALL ON TABLE public.wastewater_reservoir TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.wastewater_reservoir TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.wastewater_reservoir
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(2, 15, 'wastewater_reservoir');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.wastewater_reservoir
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.wastewater_reservoir
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.wastewater_reservoir
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.wastewater_reservoir
    FOR EACH ROW
    EXECUTE PROCEDURE public.reservoir_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.wastewater_reservoir
    FOR EACH ROW
    EXECUTE PROCEDURE public.reservoir_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.wastewater_reservoir
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_wastewater_reservoir
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	parent.capacity,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM wastewater_reservoir AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_wastewater_reservoir
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_wastewater_reservoir TO reader;
GRANT ALL ON TABLE public.web_wastewater_reservoir TO doadmin;

CREATE UNIQUE INDEX ON web_wastewater_reservoir (feature_id);
-- end wastewater reservoir

-- wastewater pump
-- create qgis layer
CREATE OR REPLACE VIEW public.wastewater_pump
 AS
 SELECT
  	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'wastewater_pump'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.wastewater_pump
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.wastewater_pump TO reader;
GRANT ALL ON TABLE public.wastewater_pump TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.wastewater_pump TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.wastewater_pump
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(2, 7, 'wastewater_pump');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.wastewater_pump
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.wastewater_pump
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.wastewater_pump
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.wastewater_pump
    FOR EACH ROW
    EXECUTE PROCEDURE public.pump_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.wastewater_pump
    FOR EACH ROW
    EXECUTE PROCEDURE public.pump_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.wastewater_pump
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_wastewater_pump
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM wastewater_pump AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_wastewater_pump
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_wastewater_pump TO reader;
GRANT ALL ON TABLE public.web_wastewater_pump TO doadmin;

CREATE UNIQUE INDEX ON web_wastewater_pump (feature_id);
-- end wastewater pump


-- wastewater pipe
-- create qgis layer
CREATE OR REPLACE VIEW public.wastewater_pipe
 AS
 SELECT
  	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_line,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 4))) AS material,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 5))) AS diameter,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 6))) AS length,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'wastewater_pipe'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.wastewater_pipe
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.wastewater_pipe TO reader;
GRANT ALL ON TABLE public.wastewater_pipe TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.wastewater_pipe TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.wastewater_pipe
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(2, 6, 'wastewater_pipe');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.wastewater_pipe
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.wastewater_pipe
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_line_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.wastewater_pipe
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_line_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.wastewater_pipe
    FOR EACH ROW
    EXECUTE PROCEDURE public.pipe_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.wastewater_pipe
    FOR EACH ROW
    EXECUTE PROCEDURE public.pipe_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.wastewater_pipe
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();
	
-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_wastewater_pipe
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_line,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	parent.material,
	parent.diameter,
	parent.length,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM wastewater_pipe AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_wastewater_pipe
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_wastewater_pipe TO reader;
GRANT ALL ON TABLE public.web_wastewater_pipe TO doadmin;

CREATE UNIQUE INDEX ON web_wastewater_pipe (feature_id);
-- end wastewater pipe

-- wastewater_part
-- create qgis layer
CREATE OR REPLACE VIEW public.wastewater_part
 AS
 SELECT
  	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 4))) AS material,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 5))) AS diameter,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'wastewater_part'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.wastewater_part
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.wastewater_part TO reader;
GRANT ALL ON TABLE public.wastewater_part TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.wastewater_part TO technician;

-- create triggers qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.wastewater_part
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(2, 5, 'wastewater_part');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.wastewater_part
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.wastewater_part
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.wastewater_part
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.wastewater_part
    FOR EACH ROW
    EXECUTE PROCEDURE public.part_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.wastewater_part
    FOR EACH ROW
    EXECUTE PROCEDURE public.part_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.wastewater_part
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_wastewater_part
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	parent.material,
	parent.diameter,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM wastewater_part AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_wastewater_part
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_wastewater_part TO reader;
GRANT ALL ON TABLE public.web_wastewater_part TO doadmin;

CREATE UNIQUE INDEX ON web_wastewater_part (feature_id);
-- end wastewater part

-- wastewater motor
-- create qgis layer
CREATE OR REPLACE VIEW public.wastewater_motor
 AS
 SELECT
  	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 10))) AS power_output,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'wastewater_motor'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.wastewater_motor
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.wastewater_motor TO reader;
GRANT ALL ON TABLE public.wastewater_motor TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.wastewater_motor TO technician;


CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.wastewater_motor
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(2, 4, 'wastewater_motor');

-- create triggers for qgis layers
CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.wastewater_motor
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.wastewater_motor
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.wastewater_motor
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.wastewater_motor
    FOR EACH ROW
    EXECUTE PROCEDURE public.motor_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.wastewater_motor
    FOR EACH ROW
    EXECUTE PROCEDURE public.motor_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.wastewater_motor
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_wastewater_motor
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	parent.power_output,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM wastewater_motor AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_wastewater_motor
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_wastewater_motor TO reader;
GRANT ALL ON TABLE public.web_wastewater_motor TO doadmin;

CREATE UNIQUE INDEX ON web_wastewater_motor (feature_id);
-- end wastewater motor

-- wastewater meter
-- create qgis layer
CREATE OR REPLACE VIEW public.wastewater_meter
 AS
 SELECT
  	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'wastewater_meter'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.wastewater_meter
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.wastewater_meter TO reader;
GRANT ALL ON TABLE public.wastewater_meter TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.wastewater_meter TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.wastewater_meter
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(2, 3, 'wastewater_meter');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.wastewater_meter
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.wastewater_meter
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.wastewater_meter
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.wastewater_meter
    FOR EACH ROW
    EXECUTE PROCEDURE public.meter_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.wastewater_meter
    FOR EACH ROW
    EXECUTE PROCEDURE public.meter_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.wastewater_meter
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_wastewater_meter
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM wastewater_meter AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_wastewater_meter
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_wastewater_meter TO reader;
GRANT ALL ON TABLE public.web_wastewater_meter TO doadmin;

CREATE UNIQUE INDEX ON web_wastewater_meter (feature_id);
-- end wastewater meter

-- wastewater manhole trunk
-- create qgis layer
CREATE OR REPLACE VIEW public.wastewater_manhole_trunk
 AS
 SELECT
  	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 4))) AS material,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'wastewater_manhole_trunk'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.wastewater_manhole_trunk
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.wastewater_manhole_trunk TO reader;
GRANT ALL ON TABLE public.wastewater_manhole_trunk TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.wastewater_manhole_trunk TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.wastewater_manhole_trunk
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(2, 14, 'wastewater_manhole_trunk');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.wastewater_manhole_trunk
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.wastewater_manhole_trunk
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.wastewater_manhole_trunk
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.wastewater_manhole_trunk
    FOR EACH ROW
    EXECUTE PROCEDURE public.manhole_trunk_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.wastewater_manhole_trunk
    FOR EACH ROW
    EXECUTE PROCEDURE public.manhole_trunk_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.wastewater_manhole_trunk
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_wastewater_manhole_trunk
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	parent.material,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM wastewater_manhole_trunk AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_wastewater_manhole_trunk
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_wastewater_manhole_trunk TO reader;
GRANT ALL ON TABLE public.web_wastewater_manhole_trunk TO doadmin;

CREATE UNIQUE INDEX ON web_wastewater_manhole_trunk (feature_id);
-- end wastewater manhole trunk

-- wastewater manhole cover
-- create qgis layer
CREATE OR REPLACE VIEW public.wastewater_manhole_cover
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 4))) AS material,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 12))) AS size,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 13))) AS load_rating,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'wastewater_manhole_cover'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.wastewater_manhole_cover
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.wastewater_manhole_cover TO reader;
GRANT ALL ON TABLE public.wastewater_manhole_cover TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.wastewater_manhole_cover TO technician;

-- create triggers on qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.wastewater_manhole_cover
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(2, 13, 'wastewater_manhole_cover');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.wastewater_manhole_cover
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.wastewater_manhole_cover
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.wastewater_manhole_cover
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.wastewater_manhole_cover
    FOR EACH ROW
    EXECUTE PROCEDURE public.manhole_cover_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.wastewater_manhole_cover
    FOR EACH ROW
    EXECUTE PROCEDURE public.manhole_cover_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.wastewater_manhole_cover
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_wastewater_manhole_cover
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	parent.material,
	parent.size,
	parent.load_rating,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM wastewater_manhole_cover AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_wastewater_manhole_cover
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_wastewater_manhole_cover TO reader;
GRANT ALL ON TABLE public.web_wastewater_manhole_cover TO doadmin;

CREATE UNIQUE INDEX ON web_wastewater_manhole_cover (feature_id);
-- end wastewater manhole cover

-- wastewater control
-- create qgis layer
CREATE OR REPLACE VIEW public.wastewater_control
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'wastewater_control'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.wastewater_control
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.wastewater_control TO reader;
GRANT ALL ON TABLE public.wastewater_control TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.wastewater_control TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.wastewater_control
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(2, 11, 'wastewater_control');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.wastewater_control
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.wastewater_control
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.wastewater_control
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.wastewater_control
    FOR EACH ROW
    EXECUTE PROCEDURE public.control_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.wastewater_control
    FOR EACH ROW
    EXECUTE PROCEDURE public.control_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.wastewater_control
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_wastewater_control
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM wastewater_control AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_wastewater_control
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_wastewater_control TO reader;
GRANT ALL ON TABLE public.web_wastewater_control TO doadmin;

CREATE UNIQUE INDEX ON web_wastewater_control (feature_id);
-- end wastewater control

-- wastewater cleanout
-- create qgis layer
CREATE OR REPLACE VIEW public.wastewater_cleanout
 AS
 SELECT
  	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 4))) AS material,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 12))) AS size,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 13))) AS load_rating,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'wastewater_cleanout'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.wastewater_cleanout
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.wastewater_cleanout TO reader;
GRANT ALL ON TABLE public.wastewater_cleanout TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.wastewater_cleanout TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.wastewater_cleanout
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(2, 54, 'wastewater_cleanout');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.wastewater_cleanout
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.wastewater_cleanout
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.wastewater_cleanout
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.wastewater_cleanout
    FOR EACH ROW
    EXECUTE PROCEDURE public.cleanout_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.wastewater_cleanout
    FOR EACH ROW
    EXECUTE PROCEDURE public.cleanout_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.wastewater_cleanout
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_wastewater_cleanout
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	parent.material,
	parent.size,
	parent.load_rating,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM wastewater_cleanout AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_wastewater_cleanout
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_wastewater_cleanout TO reader;
GRANT ALL ON TABLE public.web_wastewater_cleanout TO doadmin;

CREATE UNIQUE INDEX ON web_wastewater_cleanout (feature_id);
-- end wastewater cleanout

-- wastewater box
-- create qgis layer
CREATE OR REPLACE VIEW public.wastewater_box
 AS
 SELECT
  	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 4))) AS material,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'wastewater_box'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.wastewater_box
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.wastewater_box TO reader;
GRANT ALL ON TABLE public.wastewater_box TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.wastewater_box TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.wastewater_box
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(2, 1, 'wastewater_box');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.wastewater_box
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.wastewater_box
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.wastewater_box
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.wastewater_box
    FOR EACH ROW
    EXECUTE PROCEDURE public.box_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.wastewater_box
    FOR EACH ROW
    EXECUTE PROCEDURE public.box_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.wastewater_box
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_wastewater_box
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	parent.material,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM wastewater_box AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_wastewater_box
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_wastewater_box TO reader;
GRANT ALL ON TABLE public.web_wastewater_box TO doadmin;

CREATE UNIQUE INDEX ON web_wastewater_box (feature_id);
-- end wastewater box

-- TRANSPORTATION --

-- traffic sign or signal
-- create qgis layer
CREATE OR REPLACE VIEW public.transportation_traffic_sign_or_signal
 AS
 SELECT
  	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'transportation_traffic_sign_or_signal'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.transportation_traffic_sign_or_signal
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.transportation_traffic_sign_or_signal TO reader;
GRANT ALL ON TABLE public.transportation_traffic_sign_or_signal TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.transportation_traffic_sign_or_signal TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.transportation_traffic_sign_or_signal
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(4, 22, 'transportation_traffic_sign_or_signal');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.transportation_traffic_sign_or_signal
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.transportation_traffic_sign_or_signal
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.transportation_traffic_sign_or_signal
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.transportation_traffic_sign_or_signal
    FOR EACH ROW
    EXECUTE PROCEDURE public.traffic_sign_or_signal_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.transportation_traffic_sign_or_signal
    FOR EACH ROW
    EXECUTE PROCEDURE public.traffic_sign_or_signal_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.transportation_traffic_sign_or_signal
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_transportation_traffic_sign_or_signal
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
    parent.model,
    parent.contractor,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM transportation_traffic_sign_or_signal AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_transportation_traffic_sign_or_signal
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_transportation_traffic_sign_or_signal TO reader;
GRANT ALL ON TABLE public.web_transportation_traffic_sign_or_signal TO doadmin;

CREATE UNIQUE INDEX ON web_transportation_traffic_sign_or_signal (feature_id);
-- end transportation sign or signal

-- road overlay
-- create qgis layer
CREATE OR REPLACE VIEW public.transportation_road_overlay
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_line,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 4))) AS material,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 6))) AS length,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 7))) AS width,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 8))) AS area,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'transportation_road_overlay'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.transportation_road_overlay
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.transportation_road_overlay TO reader;
GRANT ALL ON TABLE public.transportation_road_overlay TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.transportation_road_overlay TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.transportation_road_overlay
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(4, 19, 'transportation_road_overlay');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.transportation_road_overlay
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.transportation_road_overlay
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_line_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.transportation_road_overlay
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_line_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.transportation_road_overlay
    FOR EACH ROW
    EXECUTE PROCEDURE public.road_overlay_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.transportation_road_overlay
    FOR EACH ROW
    EXECUTE PROCEDURE public.road_overlay_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.transportation_road_overlay
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_transportation_road_overlay
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_line,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
    parent.contractor,
	parent.material,
	parent.length,
	parent.width,
	parent.area,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM transportation_road_overlay AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_transportation_road_overlay
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_transportation_road_overlay TO reader;
GRANT ALL ON TABLE public.web_transportation_road_overlay TO doadmin;

CREATE UNIQUE INDEX ON web_transportation_road_overlay (feature_id);
-- end transportation road overlay

-- pole
-- create qgis layer
CREATE OR REPLACE VIEW public.transportation_pole
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'transportation_pole'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.transportation_pole
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.transportation_pole TO reader;
GRANT ALL ON TABLE public.transportation_pole TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.transportation_pole TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.transportation_pole
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(4, 23, 'transportation_pole');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.transportation_pole
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.transportation_pole
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.transportation_pole
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.transportation_pole
    FOR EACH ROW
    EXECUTE PROCEDURE public.pole_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.transportation_pole
    FOR EACH ROW
    EXECUTE PROCEDURE public.pole_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.transportation_pole
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_transportation_pole
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
	parent.model,
    parent.contractor,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM transportation_pole AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_transportation_pole
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_transportation_pole TO reader;
GRANT ALL ON TABLE public.web_transportation_pole TO doadmin;

CREATE UNIQUE INDEX ON web_transportation_pole (feature_id);
-- end transportation pole

-- pedestrian walkway
-- create qgis layer
CREATE OR REPLACE VIEW public.transportation_pedestrian_walkway
 AS
 SELECT
  	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_line,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 4))) AS material,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 6))) AS length,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 7))) AS width,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 8))) AS area,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'transportation_pedestrian_walkway'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.transportation_pedestrian_walkway
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.transportation_pedestrian_walkway TO reader;
GRANT ALL ON TABLE public.transportation_pedestrian_walkway TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.transportation_pedestrian_walkway TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.transportation_pedestrian_walkway
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(4, 21, 'transportation_pedestrian_walkway');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.transportation_pedestrian_walkway
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.transportation_pedestrian_walkway
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_line_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.transportation_pedestrian_walkway
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_line_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.transportation_pedestrian_walkway
    FOR EACH ROW
    EXECUTE PROCEDURE public.pedestrian_walkway_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.transportation_pedestrian_walkway
    FOR EACH ROW
    EXECUTE PROCEDURE public.pedestrian_walkway_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.transportation_pedestrian_walkway
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_transportation_pedestrian_walkway
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_line,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
    parent.contractor,
	parent.material,
	parent.length,
	parent.width,
	parent.area,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM transportation_pedestrian_walkway AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_transportation_pedestrian_walkway
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_transportation_pedestrian_walkway TO reader;
GRANT ALL ON TABLE public.web_transportation_pedestrian_walkway TO doadmin;

CREATE UNIQUE INDEX ON web_transportation_pedestrian_walkway (feature_id);
-- end transportation pedestrian walkway

-- light
-- create qgis layer
CREATE OR REPLACE VIEW public.transportation_light
 AS
 SELECT
  	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'transportation_light'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.transportation_light
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.transportation_light TO reader;
GRANT ALL ON TABLE public.transportation_light TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.transportation_light TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.transportation_light
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(4, 52, 'transportation_light');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.transportation_light
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.transportation_light
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.transportation_light
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.transportation_light
    FOR EACH ROW
    EXECUTE PROCEDURE public.light_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.transportation_light
    FOR EACH ROW
    EXECUTE PROCEDURE public.light_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.transportation_light
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_transportation_light
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
	parent.model,
    parent.contractor,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM transportation_light AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_transportation_light
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_transportation_light TO reader;
GRANT ALL ON TABLE public.web_transportation_light TO doadmin;

CREATE UNIQUE INDEX ON web_transportation_light (feature_id);
-- end transportation light

-- base
-- create qgis layer
CREATE OR REPLACE VIEW public.transportation_base
 AS
 SELECT
  	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_line,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 4))) AS material,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 6))) AS length,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 7))) AS width,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 8))) AS area,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'transportation_base'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.transportation_base
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.transportation_base TO reader;
GRANT ALL ON TABLE public.transportation_base TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.transportation_base TO technician;


CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.transportation_base
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(4, 20, 'transportation_base');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.transportation_base
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.transportation_base
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_line_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.transportation_base
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_line_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.transportation_base
    FOR EACH ROW
    EXECUTE PROCEDURE public.base_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.transportation_base
    FOR EACH ROW
    EXECUTE PROCEDURE public.base_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.transportation_base
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_transportation_base
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_line,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
    parent.contractor,
	parent.material,
	parent.length,
	parent.width,
	parent.area,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM transportation_base AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_transportation_base
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_transportation_base TO reader;
GRANT ALL ON TABLE public.web_transportation_base TO doadmin;

CREATE UNIQUE INDEX ON web_transportation_base (feature_id);
-- end transportation base

-- barrier or fence
-- create qgis layer
CREATE OR REPLACE VIEW public.transportation_barrier_or_fence
 AS
 SELECT
  	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan,
    feature_geometry.geom_line,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 4))) AS material,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 6))) AS length,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'transportation_barrier_or_fence'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.transportation_barrier_or_fence
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.transportation_barrier_or_fence TO reader;
GRANT ALL ON TABLE public.transportation_barrier_or_fence TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.transportation_barrier_or_fence TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.transportation_barrier_or_fence
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(4, 25, 'transportation_barrier_or_fence');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.transportation_barrier_or_fence
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.transportation_barrier_or_fence
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_line_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.transportation_barrier_or_fence
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_line_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.transportation_barrier_or_fence
    FOR EACH ROW
    EXECUTE PROCEDURE public.barrier_or_fence_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.transportation_barrier_or_fence
    FOR EACH ROW
    EXECUTE PROCEDURE public.barrier_or_fence_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.transportation_barrier_or_fence
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_transportation_barrier_or_fence
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_line,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
	parent.model,
    parent.contractor,
	parent.material,
	parent.length,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM transportation_barrier_or_fence AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_transportation_barrier_or_fence
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_transportation_barrier_or_fence TO reader;
GRANT ALL ON TABLE public.web_transportation_barrier_or_fence TO doadmin;

CREATE UNIQUE INDEX ON web_transportation_barrier_or_fence (feature_id);
-- end transportation barrier or fence

-- STRUCTURE --

-- recreational
-- create qgis layer
CREATE OR REPLACE VIEW public.structure_recreational
 AS
 SELECT 
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_polygon,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 8))) AS area,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 15))) AS footprint,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'structure_recreational'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.structure_recreational
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.structure_recreational TO reader;
GRANT ALL ON TABLE public.structure_recreational TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.structure_recreational TO technician;

-- create triggers on qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.structure_recreational
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(5, 36, 'structure_recreational');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.structure_recreational
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.structure_recreational
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_polygon_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.structure_recreational
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_polygon_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.structure_recreational
    FOR EACH ROW
    EXECUTE PROCEDURE public.recreational_structure_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.structure_recreational
    FOR EACH ROW
    EXECUTE PROCEDURE public.recreational_structure_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.structure_recreational
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_structure_recreational
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_polygon,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
	parent.model,
    parent.contractor,
	parent.area,
	parent.footprint,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM structure_recreational AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_structure_recreational
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_structure_recreational TO reader;
GRANT ALL ON TABLE public.web_structure_recreational TO doadmin;

CREATE UNIQUE INDEX ON web_structure_recreational (feature_id);
-- end structure recreational

-- monument
-- create qgis layer
CREATE OR REPLACE VIEW public.structure_monument
 AS
 SELECT
  	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'structure_monument'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.structure_monument
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.structure_monument TO reader;
GRANT ALL ON TABLE public.structure_monument TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.structure_monument TO technician;

-- create triggers on qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.structure_monument
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(5, 37, 'structure_monument');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.structure_monument
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.structure_monument
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.structure_monument
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.structure_monument
    FOR EACH ROW
    EXECUTE PROCEDURE public.monument_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.structure_monument
    FOR EACH ROW
    EXECUTE PROCEDURE public.monument_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.structure_monument
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_structure_monument
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
    parent.contractor,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM structure_monument AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_structure_monument
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_structure_monument TO reader;
GRANT ALL ON TABLE public.web_structure_monument TO doadmin;

CREATE UNIQUE INDEX ON web_structure_monument (feature_id);
-- end structure monument

-- engineered land
-- create qgis layer
CREATE OR REPLACE VIEW public.structure_engineered_land
 AS
 SELECT
  	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_polygon,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 8))) AS area,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'structure_engineered_land'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.structure_engineered_land
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.structure_engineered_land TO reader;
GRANT ALL ON TABLE public.structure_engineered_land TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.structure_engineered_land TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.structure_engineered_land
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(5, 38, 'structure_engineered_land');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.structure_engineered_land
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.structure_engineered_land
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_polygon_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.structure_engineered_land
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_polygon_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.structure_engineered_land
    FOR EACH ROW
    EXECUTE PROCEDURE public.engineered_land_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.structure_engineered_land
    FOR EACH ROW
    EXECUTE PROCEDURE public.engineered_land_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.structure_engineered_land
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_structure_engineered_land
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_polygon,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
    parent.contractor,
	parent.area,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM structure_engineered_land AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_structure_engineered_land
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_structure_engineered_land TO reader;
GRANT ALL ON TABLE public.web_structure_engineered_land TO doadmin;

CREATE UNIQUE INDEX ON web_structure_engineered_land (feature_id);
-- end structure_engineered_land

-- building
-- create qgis layer
CREATE OR REPLACE VIEW public.structure_building
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_polygon,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 15))) AS footprint,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 16))) AS floor_area,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 17))) AS height,
	( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 8))) AS area,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'structure_building'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.structure_building
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.structure_building TO reader;
GRANT ALL ON TABLE public.structure_building TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.structure_building TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.structure_building
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(5, 34, 'structure_building');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.structure_building
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.structure_building
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_polygon_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.structure_building
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_polygon_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.structure_building
    FOR EACH ROW
    EXECUTE PROCEDURE public.building_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.structure_building
    FOR EACH ROW
    EXECUTE PROCEDURE public.building_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.structure_building
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_structure_building
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_polygon,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
    parent.contractor,
	parent.footprint,
	parent.floor_area,
	parent.height,
	parent.area,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM structure_building AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_structure_building
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_structure_building TO reader;
GRANT ALL ON TABLE public.web_structure_building TO doadmin;

CREATE UNIQUE INDEX ON web_structure_building (feature_id);
-- end structure building

-- bridge
-- create qgis layer
CREATE OR REPLACE VIEW public.structure_bridge
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_line,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 6))) AS length,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 7))) AS width,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 8))) AS area,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'structure_bridge'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.structure_bridge
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.structure_bridge TO reader;
GRANT ALL ON TABLE public.structure_bridge TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.structure_bridge TO technician;

-- create triggers on qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.structure_bridge
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(5, 35, 'structure_bridge');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.structure_bridge
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.structure_bridge
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_line_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.structure_bridge
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_line_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.structure_bridge
    FOR EACH ROW
    EXECUTE PROCEDURE public.bridge_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.structure_bridge
    FOR EACH ROW
    EXECUTE PROCEDURE public.bridge_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.structure_bridge
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();
	
-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_structure_bridge
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_line,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
    parent.contractor,
	parent.length,
	parent.width,
	parent.area,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM structure_bridge AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_structure_bridge
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_structure_bridge TO reader;
GRANT ALL ON TABLE public.web_structure_bridge TO doadmin;

CREATE UNIQUE INDEX ON web_structure_bridge (feature_id);
-- end structure bridge

-- barrier or fence
-- create qgis layer
CREATE OR REPLACE VIEW public.structure_barrier_or_fence
 AS
 SELECT
  	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan,
    feature_geometry.geom_line,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 4))) AS material,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 6))) AS length,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'structure_barrier_or_fence'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.structure_barrier_or_fence
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.structure_barrier_or_fence TO reader;
GRANT ALL ON TABLE public.structure_barrier_or_fence TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.structure_barrier_or_fence TO technician;


CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.structure_barrier_or_fence
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(5, 25, 'structure_barrier_or_fence');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.structure_barrier_or_fence
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.structure_barrier_or_fence
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_line_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.structure_barrier_or_fence
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_line_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.structure_barrier_or_fence
    FOR EACH ROW
    EXECUTE PROCEDURE public.barrier_or_fence_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.structure_barrier_or_fence
    FOR EACH ROW
    EXECUTE PROCEDURE public.barrier_or_fence_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.structure_barrier_or_fence
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_structure_barrier_or_fence
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_line,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
	parent.model,
    parent.contractor,
	parent.length,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM structure_barrier_or_fence AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_structure_barrier_or_fence
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_structure_barrier_or_fence TO reader;
GRANT ALL ON TABLE public.web_structure_barrier_or_fence TO doadmin;

CREATE UNIQUE INDEX ON web_structure_barrier_or_fence (feature_id);
-- end structure barrier or fence

--NEW ONE
-- amenity
-- create qgis layer
CREATE OR REPLACE VIEW public.structure_amenity
 AS
 SELECT
  	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id,
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 4))) AS material,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'structure_amenity'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.structure_amenity
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.structure_amenity TO reader;
GRANT ALL ON TABLE public.structure_amenity TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.structure_amenity TO technician;

-- create triggers on qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.structure_amenity
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(5, 55, 'structure_amenity');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.structure_amenity
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.structure_amenity
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.structure_amenity
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.structure_amenity
    FOR EACH ROW
    EXECUTE PROCEDURE public.amenity_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.structure_amenity
    FOR EACH ROW
    EXECUTE PROCEDURE public.amenity_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.structure_amenity
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_structure_amenity
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
	parent.model,
    parent.contractor,
	parent.material,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM structure_amenity AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_structure_amenity
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_structure_amenity TO reader;
GRANT ALL ON TABLE public.web_structure_amenity TO doadmin;

CREATE UNIQUE INDEX ON web_structure_amenity (feature_id);
-- end structure amenity

-- END HERE

-- -- STORMWATER -- --
-- valve
-- create qgis layer
CREATE OR REPLACE VIEW public.stormwater_valve
 AS
 SELECT 
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id, 
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan,
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 5))) AS diameter,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'stormwater_valve'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.stormwater_valve
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.stormwater_valve TO reader;
GRANT ALL ON TABLE public.stormwater_valve TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.stormwater_valve TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.stormwater_valve
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(3, 10, 'stormwater_valve');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.stormwater_valve
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.stormwater_valve
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.stormwater_valve
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.stormwater_valve
    FOR EACH ROW
    EXECUTE PROCEDURE public.valve_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.stormwater_valve
    FOR EACH ROW
    EXECUTE PROCEDURE public.valve_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.stormwater_valve
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();
	
-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_stormwater_valve
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
	parent.model,
    parent.contractor,
	parent.diameter,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM stormwater_valve AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_stormwater_valve
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_stormwater_valve TO reader;
GRANT ALL ON TABLE public.web_stormwater_valve TO doadmin;

CREATE UNIQUE INDEX ON web_stormwater_valve (feature_id);
-- end stormwater valve

-- treatment
-- create qgis layer
CREATE OR REPLACE VIEW public.stormwater_treatment
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id, 
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan,
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'stormwater_treatment'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.stormwater_treatment
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.stormwater_treatment TO reader;
GRANT ALL ON TABLE public.stormwater_treatment TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.stormwater_treatment TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.stormwater_treatment
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(3, 9, 'stormwater_treatment');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.stormwater_treatment
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.stormwater_treatment
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.stormwater_treatment
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.stormwater_treatment
    FOR EACH ROW
    EXECUTE PROCEDURE public.treatment_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.stormwater_treatment
    FOR EACH ROW
    EXECUTE PROCEDURE public.treatment_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.stormwater_treatment
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_stormwater_treatment
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
	parent.model,
    parent.contractor,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM stormwater_treatment AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_stormwater_treatment
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_stormwater_treatment TO reader;
GRANT ALL ON TABLE public.web_stormwater_treatment TO doadmin;

CREATE UNIQUE INDEX ON web_stormwater_treatment (feature_id);
-- end stormwater treatment

-- tank
-- create qgis layer
CREATE OR REPLACE VIEW public.stormwater_tank
 AS
 SELECT
	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id, 
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan, 
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 11))) AS capacity,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'stormwater_tank'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.stormwater_tank
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.stormwater_tank TO reader;
GRANT ALL ON TABLE public.stormwater_tank TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.stormwater_tank TO technician;

-- create triggers on qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.stormwater_tank
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(3, 8, 'stormwater_tank');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.stormwater_tank
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.stormwater_tank
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.stormwater_tank
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.stormwater_tank
    FOR EACH ROW
    EXECUTE PROCEDURE public.tank_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.stormwater_tank
    FOR EACH ROW
    EXECUTE PROCEDURE public.tank_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.stormwater_tank
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_stormwater_tank
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
	parent.model,
    parent.contractor,
	parent.capacity,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM stormwater_tank AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_stormwater_tank
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_stormwater_tank TO reader;
GRANT ALL ON TABLE public.web_stormwater_tank TO doadmin;

CREATE UNIQUE INDEX ON web_stormwater_tank (feature_id);
-- end stormwater tank


-- reservoir
-- create qgis layer
CREATE OR REPLACE VIEW public.stormwater_reservoir
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id, 
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan,
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 11))) AS capacity,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'stormwater_reservoir'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.stormwater_reservoir
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.stormwater_reservoir TO reader;
GRANT ALL ON TABLE public.stormwater_reservoir TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.stormwater_reservoir TO technician;

-- create triggers on qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.stormwater_reservoir
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(3, 15, 'stormwater_reservoir');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.stormwater_reservoir
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.stormwater_reservoir
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.stormwater_reservoir
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.stormwater_reservoir
    FOR EACH ROW
    EXECUTE PROCEDURE public.reservoir_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.stormwater_reservoir
    FOR EACH ROW
    EXECUTE PROCEDURE public.reservoir_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.stormwater_reservoir
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_stormwater_reservoir
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
	parent.model,
    parent.contractor,
	parent.capacity,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM stormwater_reservoir AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_stormwater_reservoir
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_stormwater_reservoir TO reader;
GRANT ALL ON TABLE public.web_stormwater_reservoir TO doadmin;

CREATE UNIQUE INDEX ON web_stormwater_reservoir (feature_id);
-- end stormwater reservoir

-- pump
-- create qgis layer
CREATE OR REPLACE VIEW public.stormwater_pump
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id, 
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan,
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'stormwater_pump'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.stormwater_pump
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.stormwater_pump TO reader;
GRANT ALL ON TABLE public.stormwater_pump TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.stormwater_pump TO technician;

-- create triggers on qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.stormwater_pump
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(3, 7, 'stormwater_pump');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.stormwater_pump
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.stormwater_pump
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.stormwater_pump
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.stormwater_pump
    FOR EACH ROW
    EXECUTE PROCEDURE public.pump_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.stormwater_pump
    FOR EACH ROW
    EXECUTE PROCEDURE public.pump_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.stormwater_pump
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_stormwater_pump
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
	parent.model,
    parent.contractor,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM stormwater_pump AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_stormwater_pump
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_stormwater_pump TO reader;
GRANT ALL ON TABLE public.web_stormwater_pump TO doadmin;

CREATE UNIQUE INDEX ON web_stormwater_pump (feature_id);
-- end stormwater pump

-- pipe
-- create qgis layer
CREATE OR REPLACE VIEW public.stormwater_pipe
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id, 
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan,
    feature_geometry.geom_line,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 4))) AS material,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 5))) AS diameter,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 6))) AS length,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'stormwater_pipe'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.stormwater_pipe
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.stormwater_pipe TO reader;
GRANT ALL ON TABLE public.stormwater_pipe TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.stormwater_pipe TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.stormwater_pipe
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(3, 6, 'stormwater_pipe');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.stormwater_pipe
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.stormwater_pipe
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_line_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.stormwater_pipe
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_line_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.stormwater_pipe
    FOR EACH ROW
    EXECUTE PROCEDURE public.pipe_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.stormwater_pipe
    FOR EACH ROW
    EXECUTE PROCEDURE public.pipe_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.stormwater_pipe
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_stormwater_pipe
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_line,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
	parent.model,
    parent.contractor,
	parent.material,
	parent.length,
	parent.diameter,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM stormwater_pipe AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_stormwater_pipe
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_stormwater_pipe TO reader;
GRANT ALL ON TABLE public.web_stormwater_pipe TO doadmin;

CREATE UNIQUE INDEX ON web_stormwater_pipe (feature_id);
-- end stormwater pipe

-- part
-- create qgis layer
CREATE OR REPLACE VIEW public.stormwater_part
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id, 
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan,
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 4))) AS material,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 5))) AS diameter,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'stormwater_part'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.stormwater_part
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.stormwater_part TO reader;
GRANT ALL ON TABLE public.stormwater_part TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.stormwater_part TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.stormwater_part
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(3, 5, 'stormwater_part');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.stormwater_part
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.stormwater_part
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.stormwater_part
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.stormwater_part
    FOR EACH ROW
    EXECUTE PROCEDURE public.part_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.stormwater_part
    FOR EACH ROW
    EXECUTE PROCEDURE public.part_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.stormwater_part
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_stormwater_part
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
	parent.model,
    parent.contractor,
	parent.material,
	parent.diameter,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM stormwater_part AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_stormwater_part
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_stormwater_part TO reader;
GRANT ALL ON TABLE public.web_stormwater_part TO doadmin;

CREATE UNIQUE INDEX ON web_stormwater_part (feature_id);
-- end stormwater part

-- motor
-- create qgis layer
CREATE OR REPLACE VIEW public.stormwater_motor
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id, 
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan,
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 10))) AS power_output,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'stormwater_motor'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.stormwater_motor
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.stormwater_motor TO reader;
GRANT ALL ON TABLE public.stormwater_motor TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.stormwater_motor TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.stormwater_motor
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(3, 4, 'stormwater_motor');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.stormwater_motor
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.stormwater_motor
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.stormwater_motor
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.stormwater_motor
    FOR EACH ROW
    EXECUTE PROCEDURE public.motor_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.stormwater_motor
    FOR EACH ROW
    EXECUTE PROCEDURE public.motor_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.stormwater_motor
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_stormwater_motor
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
	parent.model,
    parent.contractor,
	parent.power_output,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM stormwater_motor AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_stormwater_motor
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_stormwater_motor TO reader;
GRANT ALL ON TABLE public.web_stormwater_motor TO doadmin;

CREATE UNIQUE INDEX ON web_stormwater_motor (feature_id);
-- end stormwater motor

-- meter
-- create qgis layer
CREATE OR REPLACE VIEW public.stormwater_meter
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id, 
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan,
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'stormwater_meter'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.stormwater_meter
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.stormwater_meter TO reader;
GRANT ALL ON TABLE public.stormwater_meter TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.stormwater_meter TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.stormwater_meter
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(3, 3, 'stormwater_meter');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.stormwater_meter
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.stormwater_meter
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.stormwater_meter
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.stormwater_meter
    FOR EACH ROW
    EXECUTE PROCEDURE public.meter_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.stormwater_meter
    FOR EACH ROW
    EXECUTE PROCEDURE public.meter_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.stormwater_meter
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_stormwater_meter
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
	parent.model,
    parent.contractor,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM stormwater_meter AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_stormwater_meter
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_stormwater_meter TO reader;
GRANT ALL ON TABLE public.web_stormwater_meter TO doadmin;

CREATE UNIQUE INDEX ON web_stormwater_meter (feature_id);
-- end stormwater meter

-- manhole_trunk
-- create stormwater manhole trunk
CREATE OR REPLACE VIEW public.stormwater_manhole_trunk
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id, 
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan,
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 4))) AS material,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'stormwater_manhole_trunk'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.stormwater_manhole_trunk
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.stormwater_manhole_trunk TO reader;
GRANT ALL ON TABLE public.stormwater_manhole_trunk TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.stormwater_manhole_trunk TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.stormwater_manhole_trunk
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(3, 14, 'stormwater_manhole_trunk');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.stormwater_manhole_trunk
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.stormwater_manhole_trunk
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.stormwater_manhole_trunk
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.stormwater_manhole_trunk
    FOR EACH ROW
    EXECUTE PROCEDURE public.manhole_trunk_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.stormwater_manhole_trunk
    FOR EACH ROW
    EXECUTE PROCEDURE public.manhole_trunk_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.stormwater_manhole_trunk
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_stormwater_manhole_trunk
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
	parent.model,
    parent.contractor,
	parent.material,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM stormwater_manhole_trunk AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_stormwater_manhole_trunk
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_stormwater_manhole_trunk TO reader;
GRANT ALL ON TABLE public.web_stormwater_manhole_trunk TO doadmin;

CREATE UNIQUE INDEX ON web_stormwater_manhole_trunk (feature_id);
-- end stormwater manhole trunk

-- manhole_cover
-- create qgis layer
CREATE OR REPLACE VIEW public.stormwater_manhole_cover
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id, 
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan,
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 4))) AS material,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 12))) AS size,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 13))) AS load_rating,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'stormwater_manhole_cover'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.stormwater_manhole_cover
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.stormwater_manhole_cover TO reader;
GRANT ALL ON TABLE public.stormwater_manhole_cover TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.stormwater_manhole_cover TO technician;

-- create triggers on qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.stormwater_manhole_cover
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(3, 13, 'stormwater_manhole_cover');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.stormwater_manhole_cover
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.stormwater_manhole_cover
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.stormwater_manhole_cover
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.stormwater_manhole_cover
    FOR EACH ROW
    EXECUTE PROCEDURE public.manhole_cover_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.stormwater_manhole_cover
    FOR EACH ROW
    EXECUTE PROCEDURE public.manhole_cover_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.stormwater_manhole_cover
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_stormwater_manhole_cover
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
	parent.model,
    parent.contractor,
	parent.material,
	parent.size,
	parent.load_rating,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM stormwater_manhole_cover AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_stormwater_manhole_cover
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_stormwater_manhole_cover TO reader;
GRANT ALL ON TABLE public.web_stormwater_manhole_cover TO doadmin;

CREATE UNIQUE INDEX ON web_stormwater_manhole_cover (feature_id);
-- end stormwater manhole cover

-- grate
-- create qgis layer
CREATE OR REPLACE VIEW public.stormwater_grate
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id, 
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan,
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 4))) AS material,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'stormwater_grate'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.stormwater_grate
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.stormwater_grate TO reader;
GRANT ALL ON TABLE public.stormwater_grate TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.stormwater_grate TO technician;

-- create triggers on qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.stormwater_grate
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(3, 18, 'stormwater_grate');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.stormwater_grate
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.stormwater_grate
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.stormwater_grate
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.stormwater_grate
    FOR EACH ROW
    EXECUTE PROCEDURE public.grate_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.stormwater_grate
    FOR EACH ROW
    EXECUTE PROCEDURE public.grate_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.stormwater_grate
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_stormwater_grate
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
	parent.model,
    parent.contractor,
	parent.material,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM stormwater_grate AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_stormwater_grate
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_stormwater_grate TO reader;
GRANT ALL ON TABLE public.web_stormwater_grate TO doadmin;

CREATE UNIQUE INDEX ON web_stormwater_grate (feature_id);
-- end stormwater grate

-- control
-- create qgis layer
CREATE OR REPLACE VIEW public.stormwater_control
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id, 
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan,
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'stormwater_control'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.stormwater_control
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.stormwater_control TO reader;
GRANT ALL ON TABLE public.stormwater_control TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.stormwater_control TO technician;

-- create triggers on qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.stormwater_control
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(3, 11, 'stormwater_control');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.stormwater_control
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.stormwater_control
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.stormwater_control
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.stormwater_control
    FOR EACH ROW
    EXECUTE PROCEDURE public.control_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.stormwater_control
    FOR EACH ROW
    EXECUTE PROCEDURE public.control_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.stormwater_control
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_stormwater_control
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
	parent.model,
    parent.contractor,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM stormwater_control AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_stormwater_control
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_stormwater_control TO reader;
GRANT ALL ON TABLE public.web_stormwater_control TO doadmin;

CREATE UNIQUE INDEX ON web_stormwater_control (feature_id);
-- end stormwater control

-- channel
-- create qgis layer
CREATE OR REPLACE VIEW public.stormwater_channel
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id, 
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan,
    feature_geometry.geom_line,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 4))) AS material,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 6))) AS length,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'stormwater_channel'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.stormwater_channel
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.stormwater_channel TO reader;
GRANT ALL ON TABLE public.stormwater_channel TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.stormwater_channel TO technician;

-- create triggers on qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.stormwater_channel
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(3, 16, 'stormwater_channel');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.stormwater_channel
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.stormwater_channel
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_line_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.stormwater_channel
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_line_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.stormwater_channel
    FOR EACH ROW
    EXECUTE PROCEDURE public.channel_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.stormwater_channel
    FOR EACH ROW
    EXECUTE PROCEDURE public.channel_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.stormwater_channel
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_stormwater_channel
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_line,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
	parent.model,
    parent.contractor,
	parent.material,
	parent.length,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM stormwater_channel AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_stormwater_channel
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_stormwater_channel TO reader;
GRANT ALL ON TABLE public.web_stormwater_channel TO doadmin;

CREATE UNIQUE INDEX ON web_stormwater_channel (feature_id);
-- end stormwater channel

-- catch_basin
-- create qgis layer
CREATE OR REPLACE VIEW public.stormwater_catch_basin
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id, 
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan,
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 4))) AS material,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'stormwater_catch_basin'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.stormwater_catch_basin
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.stormwater_catch_basin TO reader;
GRANT ALL ON TABLE public.stormwater_catch_basin TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.stormwater_catch_basin TO technician;

-- create triggers on qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.stormwater_catch_basin
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(3, 17, 'stormwater_catch_basin');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.stormwater_catch_basin
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.stormwater_catch_basin
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.stormwater_catch_basin
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.stormwater_catch_basin
    FOR EACH ROW
    EXECUTE PROCEDURE public.catch_basin_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.stormwater_catch_basin
    FOR EACH ROW
    EXECUTE PROCEDURE public.catch_basin_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.stormwater_catch_basin
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_stormwater_catch_basin
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
	parent.model,
    parent.contractor,
	parent.material,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM stormwater_catch_basin AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_stormwater_catch_basin
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_stormwater_catch_basin TO reader;
GRANT ALL ON TABLE public.web_stormwater_catch_basin TO doadmin;

CREATE UNIQUE INDEX ON web_stormwater_catch_basin (feature_id);
-- end stormwater catch basin

-- box
-- create qgis layer
CREATE OR REPLACE VIEW public.stormwater_box
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id, 
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan,
    feature_geometry.geom_point,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 3))) AS contractor,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 4))) AS material,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'stormwater_box'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.stormwater_box
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.stormwater_box TO reader;
GRANT ALL ON TABLE public.stormwater_box TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.stormwater_box TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.stormwater_box
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter(3, 1, 'stormwater_box');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.stormwater_box
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.stormwater_box
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.stormwater_box
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.stormwater_box
    FOR EACH ROW
    EXECUTE PROCEDURE public.box_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.stormwater_box
    FOR EACH ROW
    EXECUTE PROCEDURE public.box_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.stormwater_box
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_stormwater_box
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
	parent.model,
    parent.contractor,
	parent.material,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM stormwater_box AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_stormwater_box
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_stormwater_box TO reader;
GRANT ALL ON TABLE public.web_stormwater_box TO doadmin;

CREATE UNIQUE INDEX ON web_stormwater_box (feature_id);
-- end stormwater box

-- -- NATURAL -- --

-- wetland
-- create qgis layer
CREATE OR REPLACE VIEW public.natural_wetland
 AS
 SELECT
 	feature_base.id AS feature_id,
    	feature_base.class_id,
    	feature_base.sub_class_id,
   	feature_base.type_id,
    	feature_base.system_id, 
    	feature_base.description,
    	feature_base.cof,
    	feature_base.file_reference,
    	feature_base.view_name,
    	feature_geometry.geom_polygon,
    	feature_base.display_label
   FROM feature_base,
    	feature_geometry,
    	system,
    	user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'natural_wetland'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.natural_wetland
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.natural_wetland TO reader;
GRANT ALL ON TABLE public.natural_wetland TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.natural_wetland TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.natural_wetland
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter_natural(7, 26, 'natural_wetland');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.natural_wetland
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater_natural();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.natural_wetland
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_polygon_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.natural_wetland
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_polygon_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.natural_wetland
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_natural_wetland
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_polygon,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	-- condition and age properties
	-- financial properties
	-- prioritization properties
	cof.name as cof

FROM natural_wetland AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN cof ON parent.cof = cof.id

WITH DATA;

ALTER TABLE public.web_natural_wetland
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_natural_wetland TO reader;
GRANT ALL ON TABLE public.web_natural_wetland TO doadmin;

CREATE UNIQUE INDEX ON web_natural_wetland (feature_id);
-- end natural wetland

-- waterway
-- create qgis layer
CREATE OR REPLACE VIEW public.natural_waterway
 AS
 SELECT
 	feature_base.id AS feature_id,
    	feature_base.class_id,
    	feature_base.sub_class_id,
    	feature_base.type_id,
    	feature_base.system_id, 
    	feature_base.description,
    	feature_base.cof,
    	feature_base.file_reference,
    	feature_base.view_name,
    	feature_geometry.geom_line,
    	feature_base.display_label
   FROM feature_base,
    	feature_geometry,
    	system,
    	user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'natural_waterway'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.natural_waterway
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.natural_waterway TO reader;
GRANT ALL ON TABLE public.natural_waterway TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.natural_waterway TO technician;

-- create triggers on qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.natural_waterway
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter_natural(7, 30, 'natural_waterway');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.natural_waterway
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater_natural();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.natural_waterway
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_line_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.natural_waterway
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_line_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.natural_waterway
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_natural_waterway
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_line,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	-- condition and age properties
	-- financial properties
	-- prioritization properties
	cof.name as cof

FROM natural_waterway AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN cof ON parent.cof = cof.id

WITH DATA;

ALTER TABLE public.web_natural_waterway
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_natural_waterway TO reader;
GRANT ALL ON TABLE public.web_natural_waterway TO doadmin;

CREATE UNIQUE INDEX ON web_natural_waterway (feature_id);
-- end natural waterway

-- waterbody
-- create qgis layer
CREATE OR REPLACE VIEW public.natural_waterbody
 AS
 SELECT
 	feature_base.id AS feature_id,
    	feature_base.class_id,
    	feature_base.sub_class_id,
    	feature_base.type_id,
    	feature_base.system_id, 
    	feature_base.description,
    	feature_base.cof,
    	feature_base.file_reference,
    	feature_base.view_name,
    	feature_geometry.geom_polygon,
    	feature_base.display_label
   FROM feature_base,
    	feature_geometry,
    	system,
    	user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'natural_waterbody'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.natural_waterbody
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.natural_waterbody TO reader;
GRANT ALL ON TABLE public.natural_waterbody TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.natural_waterbody TO technician;

-- create triggers on qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.natural_waterbody
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter_natural(7, 31, 'natural_waterbody');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.natural_waterbody
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater_natural();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.natural_waterbody
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_polygon_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.natural_waterbody
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_polygon_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.natural_waterbody
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_natural_waterbody
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_polygon,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	-- condition and age properties
	-- financial properties
	-- prioritization properties
	cof.name as cof

FROM natural_waterbody AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN cof ON parent.cof = cof.id

WITH DATA;

ALTER TABLE public.web_natural_waterbody
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_natural_waterbody TO reader;
GRANT ALL ON TABLE public.web_natural_waterbody TO doadmin;

CREATE UNIQUE INDEX ON web_natural_waterbody (feature_id);
-- end natural waterbody

-- vegetation
-- create qgis layer
CREATE OR REPLACE VIEW public.natural_vegetation
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id, 
    feature_base.description,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_geometry.geom_point,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'natural_vegetation'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.natural_vegetation
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.natural_vegetation TO reader;
GRANT ALL ON TABLE public.natural_vegetation TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.natural_vegetation TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.natural_vegetation
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter_natural(7, 32, 'natural_vegetation');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.natural_vegetation
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater_natural();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.natural_vegetation
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.natural_vegetation
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.natural_vegetation
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_natural_vegetation
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	-- condition and age properties
	-- financial properties
	-- prioritization properties
	cof.name as cof

FROM natural_vegetation AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN cof ON parent.cof = cof.id

WITH DATA;

ALTER TABLE public.web_natural_vegetation
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_natural_vegetation TO reader;
GRANT ALL ON TABLE public.web_natural_vegetation TO doadmin;

CREATE UNIQUE INDEX ON web_natural_vegetation (feature_id);
-- end natural vegetation

-- grassland
-- create qgis layer
CREATE OR REPLACE VIEW public.natural_grassland
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id, 
    feature_base.description,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_geometry.geom_polygon,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'natural_grassland'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.natural_grassland
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.natural_grassland TO reader;
GRANT ALL ON TABLE public.natural_grassland TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.natural_grassland TO technician;

-- create triggers for qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.natural_grassland
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter_natural(7, 29, 'natural_grassland');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.natural_grassland
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater_natural();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.natural_grassland
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_polygon_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.natural_grassland
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_polygon_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.natural_grassland
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_natural_grassland
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_polygon,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	-- condition and age properties
	-- financial properties
	-- prioritization properties
	cof.name as cof

FROM natural_grassland AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN cof ON parent.cof = cof.id

WITH DATA;

ALTER TABLE public.web_natural_grassland
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_natural_grassland TO reader;
GRANT ALL ON TABLE public.web_natural_grassland TO doadmin;

CREATE UNIQUE INDEX ON web_natural_grassland (feature_id);
-- end natural grassland

-- forest
-- create qgis layer
CREATE OR REPLACE VIEW public.natural_forest
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id, 
    feature_base.description,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_geometry.geom_polygon,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'natural_forest'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.natural_forest
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.natural_forest TO reader;
GRANT ALL ON TABLE public.natural_forest TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.natural_forest TO technician;

-- create triggers on qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.natural_forest
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter_natural(7, 28, 'natural_forest');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.natural_forest
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater_natural();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.natural_forest
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_polygon_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.natural_forest
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_polygon_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.natural_forest
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_natural_forest
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_polygon,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	-- condition and age properties
	-- financial properties
	-- prioritization properties
	cof.name as cof

FROM natural_forest AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN cof ON parent.cof = cof.id

WITH DATA;

ALTER TABLE public.web_natural_forest
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_natural_forest TO reader;
GRANT ALL ON TABLE public.web_natural_forest TO doadmin;

CREATE UNIQUE INDEX ON web_natural_forest (feature_id);
-- end natural forest

-- aquifer
-- create qgis layer
CREATE OR REPLACE VIEW public.natural_aquifer
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id, 
    feature_base.description,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_geometry.geom_polygon,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'natural_aquifer'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.natural_aquifer
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.natural_aquifer TO reader;
GRANT ALL ON TABLE public.natural_aquifer TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.natural_aquifer TO technician;

-- create triggers on qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.natural_aquifer
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter_natural(7, 27, 'natural_aquifer');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.natural_aquifer
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater_natural();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.natural_aquifer
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_polygon_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.natural_aquifer
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_polygon_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.natural_aquifer
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_natural_aquifer
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_polygon,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	-- condition and age properties
	-- financial properties
	-- prioritization properties
	cof.name as cof

FROM natural_aquifer AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN cof ON parent.cof = cof.id

WITH DATA;

ALTER TABLE public.web_natural_aquifer
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_natural_aquifer TO reader;
GRANT ALL ON TABLE public.web_natural_aquifer TO doadmin;

CREATE UNIQUE INDEX ON web_natural_aquifer (feature_id);
-- end natural aquifer

-- animalia
-- create qgis layer
CREATE OR REPLACE VIEW public.natural_animalia
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id, 
    feature_base.description,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_geometry.geom_point,
    feature_base.display_label
   FROM feature_base,
    feature_geometry,
    system,
    user_community
  WHERE ((feature_base.id = feature_geometry.feature_id) AND (feature_base.view_name = 'natural_animalia'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.natural_animalia
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.natural_animalia TO reader;
GRANT ALL ON TABLE public.natural_animalia TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.natural_animalia TO technician;

-- create trigger on qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.natural_animalia
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter_natural(7, 33, 'natural_animalia');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.natural_animalia
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater_natural();


CREATE TRIGGER b_insert_geometry
    INSTEAD OF INSERT
    ON public.natural_animalia
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_inserter();


CREATE TRIGGER b_update_geometry
    INSTEAD OF UPDATE 
    ON public.natural_animalia
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_geometry_point_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.natural_animalia
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_natural_animalia
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    parent.geom_point,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	-- condition and age properties
	-- financial properties
	-- prioritization properties
	cof.name as cof

FROM natural_animalia AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN cof ON parent.cof = cof.id

WITH DATA;

ALTER TABLE public.web_natural_animalia
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_natural_animalia TO reader;
GRANT ALL ON TABLE public.web_natural_animalia TO doadmin;

CREATE UNIQUE INDEX ON web_natural_animalia (feature_id);
-- end natural animalia

-- -- FLEET -- --

-- fleet
-- create qgis layer
CREATE OR REPLACE VIEW public.fleet
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id, 
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    feature_base.display_label
   FROM feature_base,
    system,
    user_community
  WHERE ((feature_base.view_name = 'fleet'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.fleet
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.fleet TO reader;
GRANT ALL ON TABLE public.fleet TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.fleet TO technician;

-- create trigger on qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.fleet
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter_nosubclass(6, 'fleet');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.fleet
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.fleet
    FOR EACH ROW
    EXECUTE PROCEDURE public.fleet_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.fleet
    FOR EACH ROW
    EXECUTE PROCEDURE public.fleet_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.fleet
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter_nogeom();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_fleet
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
	parent.model,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level

FROM fleet AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_fleet
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_fleet TO reader;
GRANT ALL ON TABLE public.web_fleet TO doadmin;

CREATE UNIQUE INDEX ON web_fleet (feature_id);
-- end fleet

-- -- EQUIPMENT -- --

-- equipment
-- create qgis layer
CREATE OR REPLACE VIEW public.equipment
 AS
 SELECT
 	feature_base.id AS feature_id,
    feature_base.class_id,
    feature_base.sub_class_id,
    feature_base.type_id,
    feature_base.system_id, 
    feature_base.description,
    feature_base.install_date,
    feature_base.condition_id,
	feature_base.inspection_date,
    feature_base.renewal_cost,
    feature_base.maintenance_cost,
    feature_base.cof,
    feature_base.file_reference,
    feature_base.view_name,
    feature_base.lifespan,
    feature_base.parent_feature_id,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 1))) AS brand,
    ( SELECT feature_property.value_text
           FROM feature_property
          WHERE ((feature_property.feature_id = feature_base.id) AND (feature_property.property_id = 2))) AS model,
    feature_base.display_label
   FROM feature_base,
    system,
    user_community
  WHERE ((feature_base.view_name = 'equipment'::text) AND (feature_base.system_id = system.id) AND (system.community_id = user_community.community_id) AND ((user_community.user_name = CURRENT_USER) OR (CURRENT_USER = 'doadmin'::name) OR (CURRENT_USER = 'technician'::name)));

ALTER TABLE public.equipment
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.equipment TO reader;
GRANT ALL ON TABLE public.equipment TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.equipment TO technician;

-- create triggers on qgis layer
CREATE TRIGGER a_insert_base
    INSTEAD OF INSERT
    ON public.equipment
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_inserter_equipment(8, 'equipment');


CREATE TRIGGER a_update_base
    INSTEAD OF UPDATE 
    ON public.equipment
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_base_updater_equipment();


CREATE TRIGGER c_insert_property
    INSTEAD OF INSERT
    ON public.equipment
    FOR EACH ROW
    EXECUTE PROCEDURE public.equipment_property_inserter();


CREATE TRIGGER c_update_property
    INSTEAD OF UPDATE 
    ON public.equipment
    FOR EACH ROW
    EXECUTE PROCEDURE public.equipment_property_updater();


CREATE TRIGGER delete_feature
    INSTEAD OF DELETE
    ON public.equipment
    FOR EACH ROW
    EXECUTE PROCEDURE public.feature_deleter_nogeom();

-- create web map materialized view
CREATE MATERIALIZED VIEW public.web_equipment
TABLESPACE pg_default
AS
 SELECT
	-- general properties
	parent.feature_id,
    system.name AS system,
    community.name AS community,
    region.name AS region_name,
    province.name AS province_name,
    asset_class.description AS class,
    asset_sub_class.name AS sub_class,
    asset_type.name AS type,
    parent.description,
	parent.display_label AS label,
	-- specific properties
	parent.brand,
	parent.model,
	-- condition and age properties
	condition.name AS condition,
	parent.inspection_date,
    parent.install_date,
	feature_calculation.age,
	feature_calculation.lifespan,
	feature_projection.remaining_years,
	-- financial properties
	feature_calculation.renewal_cost,
	feature_calculation.maintenance_cost,
	feature_projection.annual_reserve,	
	-- prioritization properties
	pof.name as pof,
	cof.name as cof,
	feature_risk.risk_level,
	parent.parent_feature_id

FROM equipment AS parent
LEFT JOIN system ON parent.system_id = system.id
LEFT JOIN community ON system.community_id = community.id
LEFT JOIN region ON community.region_id = region.id
LEFT JOIN province ON region.province_id = province.id
LEFT JOIN asset_class ON parent.class_id = asset_class.id
LEFT JOIN asset_sub_class ON parent.sub_class_id = asset_sub_class.id
LEFT JOIN asset_type ON parent.type_id = asset_type.id
LEFT JOIN condition ON parent.condition_id = condition.id
LEFT JOIN feature_calculation ON parent.feature_id = feature_calculation.feature_id
LEFT JOIN feature_projection ON parent.feature_id = feature_projection.feature_id
LEFT JOIN feature_pof ON parent.feature_id = feature_pof.feature_id
LEFT JOIN pof ON feature_pof.pof = pof.id
LEFT JOIN cof ON parent.cof = cof.id
LEFT JOIN feature_risk ON parent.feature_id = feature_risk.feature_id
WITH DATA;

ALTER TABLE public.web_equipment
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.web_equipment TO reader;
GRANT ALL ON TABLE public.web_equipment TO doadmin;

CREATE UNIQUE INDEX ON web_equipment (feature_id);
-- end equipment

-- -- VALUE LISTS FOR QGIS -- --

-- region_community_system
CREATE OR REPLACE VIEW public.region_community_system
 AS
	SELECT 
		system.id AS system_id,
		(SELECT concat(community.name, ': ', system.name, ' (', region.code, ', ', province.code, ')') AS full_organization_name) AS full_organization_name
  
	FROM 
		system,
		community,
		region,
		province,
		user_community
	WHERE (
		(system.community_id = community.id) AND 
		(community.region_id = region.id) AND 
		(region.province_id = province.id) AND
		(user_community.community_id = community.id) AND
		(user_community.user_name = current_user OR current_user = 'doadmin')	
	);

ALTER TABLE public.region_community_system
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.region_community_system TO reader;
GRANT ALL ON TABLE public.region_community_system TO doadmin;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE public.region_community_system TO technician;

-- equipment_sub_class_list
CREATE OR REPLACE VIEW public.equipment_sub_class_list AS
	SELECT DISTINCT
		asset_sub_class.id,
		asset_sub_class.name
	FROM asset_sub_class, asset_classification_combination
	WHERE 
		asset_classification_combination.class_id = 8 AND
		asset_sub_class.id = asset_classification_combination.sub_class_id;
		
GRANT ALL ON TABLE public.equipment_sub_class_list TO doadmin;
GRANT SELECT ON TABLE public.equipment_sub_class_list TO technician;

-- equipment_type_list
CREATE OR REPLACE VIEW public.equipment_type_list AS
	SELECT DISTINCT
		asset_type.id AS type_id,
		asset_classification_combination.sub_class_id AS sub_class_id,
		asset_type.name AS type_name
	FROM asset_type, asset_classification_combination
	WHERE 
		asset_classification_combination.class_id = 8 AND
		asset_type.id = asset_classification_combination.type_id;
		
GRANT ALL ON TABLE public.equipment_type_list TO doadmin;
GRANT SELECT ON TABLE public.equipment_type_list TO technician;


-- capital planning qgis layers
-- risk line
CREATE OR REPLACE VIEW public.risk_line
 AS
 SELECT feature_base.id AS feature_id,
    feature_geometry.geom_line,
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
     LEFT JOIN feature_geometry ON feature_geometry.feature_id = feature_base.id
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
  WHERE feature_geometry.geom_line IS NOT NULL AND (user_community.user_name = CURRENT_USER OR CURRENT_USER = 'doadmin'::name OR CURRENT_USER = 'technician'::name);

ALTER TABLE public.risk_line
    OWNER TO doadmin;

GRANT ALL ON TABLE public.risk_line TO doadmin;
GRANT SELECT ON TABLE public.risk_line TO technician;

-- risk point
CREATE OR REPLACE VIEW public.risk_point
 AS
 SELECT feature_base.id AS feature_id,
    feature_geometry.geom_point,
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
     LEFT JOIN feature_geometry ON feature_geometry.feature_id = feature_base.id
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
  WHERE feature_geometry.geom_point IS NOT NULL AND (user_community.user_name = CURRENT_USER OR CURRENT_USER = 'doadmin'::name OR CURRENT_USER = 'technician'::name);

ALTER TABLE public.risk_point
    OWNER TO doadmin;

GRANT ALL ON TABLE public.risk_point TO doadmin;
GRANT SELECT ON TABLE public.risk_point TO technician;

--risk polygon
CREATE OR REPLACE VIEW public.risk_polygon
 AS
 SELECT feature_base.id AS feature_id,
    feature_geometry.geom_polygon,
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
     LEFT JOIN feature_geometry ON feature_geometry.feature_id = feature_base.id
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
  WHERE feature_geometry.geom_polygon IS NOT NULL AND (user_community.user_name = CURRENT_USER OR CURRENT_USER = 'doadmin'::name OR CURRENT_USER = 'technician'::name);

ALTER TABLE public.risk_polygon
    OWNER TO doadmin;

GRANT ALL ON TABLE public.risk_polygon TO doadmin;
GRANT SELECT ON TABLE public.risk_polygon TO technician;

-- risk fleet and equipment
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

-- view for projections
CREATE OR REPLACE VIEW public.long_term_projection
 AS
 SELECT feature_base.id AS feature_id,
    system.id AS system_id,
    system.name AS system_name,
    community.id AS community_id,
    community.name AS community_name,
    feature_calculation.renewal_cost,
    generate_series(
        CASE
            WHEN feature_projection.remaining_years < 0::numeric THEN date_part('year'::text, CURRENT_DATE)::integer::numeric
            ELSE feature_projection.remaining_years + date_part('year'::text, CURRENT_DATE)::integer::numeric
        END, (date_part('year'::text, CURRENT_DATE)::integer + 100)::numeric, feature_calculation.lifespan::numeric) AS renewal_year
   FROM feature_base
     LEFT JOIN system ON system.id = feature_base.system_id
     LEFT JOIN community ON system.community_id = community.id
     LEFT JOIN feature_projection ON feature_projection.feature_id = feature_base.id
     LEFT JOIN feature_calculation ON feature_calculation.feature_id = feature_base.id;

ALTER TABLE public.long_term_projection
    OWNER TO doadmin;

GRANT SELECT ON TABLE public.long_term_projection TO reader;
GRANT ALL ON TABLE public.long_term_projection TO doadmin;
GRANT SELECT ON TABLE public.long_term_projection TO reporter;

-- capital planning
CREATE OR REPLACE VIEW public.capital_planning
 AS
 WITH capital_cost_sum AS (
         SELECT a.capital_project_id,
            sum(a.renewal_cost) AS summed_renewal_cost
           FROM ( SELECT capital_project_feature_combination.capital_project_id,
                    capital_project_feature_combination.feature_id,
                    feature_calculation.renewal_cost
                   FROM capital_project_feature_combination
                     LEFT JOIN feature_calculation ON capital_project_feature_combination.feature_id = feature_calculation.feature_id) a
          GROUP BY a.capital_project_id
        )
 SELECT capital_project.capital_project_id,
    capital_project.name AS capital_project_name,
    capital_project.year,
    capital_project.description,
        CASE
            WHEN capital_project.proforma_cost IS NOT NULL THEN capital_project.proforma_cost
            ELSE capital_cost_sum.summed_renewal_cost::double precision
        END AS estimated_project_cost,
    capital_project.community_id
   FROM capital_project
     LEFT JOIN capital_cost_sum ON capital_project.capital_project_id = capital_cost_sum.capital_project_id
     
  WHERE capital_project.community_id = (( SELECT user_community.community_id
           FROM user_community
          WHERE user_community.user_name = CURRENT_USER)) OR CURRENT_USER = 'reporter'::name OR CURRENT_USER = 'doadmin'::name;

ALTER TABLE public.capital_planning
    OWNER TO doadmin;

GRANT ALL ON TABLE public.capital_planning TO doadmin;
GRANT SELECT ON TABLE public.capital_planning TO reporter;
GRANT SELECT ON TABLE public.capital_planning TO technician;

-- RISK for fleet and equipment
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
  WHERE 
  	(feature_base.class_id = 6 OR feature_base.class_id = 8)
AND (user_community.user_name = CURRENT_USER OR CURRENT_USER = 'doadmin'::name OR CURRENT_USER = 'technician'::name);

ALTER TABLE public.risk_flt_equ
    OWNER TO doadmin;

GRANT ALL ON TABLE public.risk_flt_equ TO doadmin;
GRANT SELECT ON TABLE public.risk_flt_equ TO technician;