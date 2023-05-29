-- START AMENITY PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.amenity_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_material_property_id INTEGER;
	_username TEXT;
	
BEGIN
--assign property ids
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);
--capture brand
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _brand_property_id,
    NEW.brand,
	(SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id)
    );

--capture model
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _model_property_id,
    NEW.model,
	_username
    );

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text		,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
	
--capture material
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _material_property_id,
    NEW.material,
	_username
    );
	
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.amenity_property_inserter()
    OWNER TO doadmin;
-- END AMENITY PROPERTY INSERTER

-- START AMENITY PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.amenity_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_material_property_id INTEGER;
	_username TEXT;
	
BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--update brand
UPDATE feature_property
	SET value_text = NEW.brand
	WHERE feature_id = _feature_id AND property_id = _brand_property_id;

--update model
UPDATE feature_property
	SET value_text = NEW.model
	WHERE feature_id = _feature_id AND property_id = _model_property_id;

--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update material
UPDATE feature_property
	SET value_text = NEW.material
	WHERE feature_id = _feature_id AND property_id = _material_property_id;

--update username for all entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;
	
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.amenity_property_updater()
    OWNER TO doadmin;
-- END AMENITY PROPERTY UPDATER


-- START BARRIER OR FENCE PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.barrier_or_fence_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_material_property_id INTEGER;
	_length_property_id INTEGER;
	_length_value NUMERIC;
	_username TEXT;
	
BEGIN
--assign property ids
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_length_property_id = (SELECT id FROM property WHERE name = 'length');
	_length_value = (SELECT ST_Length(feature_geometry.geom_line::geography) FROM feature_geometry WHERE feature_id = (SELECT currval('feature_base_id_seq')))::NUMERIC(11,2);
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);
--capture brand
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _brand_property_id,
    NEW.brand,
	(SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id)
    );

--capture model
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _model_property_id,
    NEW.model,
	_username
    );

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text		,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
	
--capture material
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _material_property_id,
    NEW.material,
	_username
    );
	
--capture length
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _length_property_id,
    _length_value::TEXT,
	_username
    );

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.barrier_or_fence_property_inserter()
    OWNER TO doadmin;
-- END BARRIER OR FENCE PROPERTY INSERTER

-- START BARRIER OR FENCE PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.barrier_or_fence_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_material_property_id INTEGER;
	_length_property_id INTEGER;
	_length_value NUMERIC;
	_username TEXT;
	
BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_length_property_id = (SELECT id FROM property WHERE name = 'length');
	_length_value = ((SELECT ST_Length(feature_geometry.geom_line::geography) FROM feature_geometry WHERE feature_id = _feature_id)::NUMERIC(11,2));
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--update brand
UPDATE feature_property
	SET value_text = NEW.brand
	WHERE feature_id = _feature_id AND property_id = _brand_property_id;

--update model
UPDATE feature_property
	SET value_text = NEW.model
	WHERE feature_id = _feature_id AND property_id = _model_property_id;

--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update material
UPDATE feature_property
	SET value_text = NEW.material
	WHERE feature_id = _feature_id AND property_id = _material_property_id;

--update length
UPDATE feature_property
	SET value_text = _length_value::TEXT
	WHERE feature_id = _feature_id AND property_id = _length_property_id;

--update username for all entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;
	
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.barrier_or_fence_property_updater()
    OWNER TO doadmin;
-- END BARRIER OR FENCE PROPERTY UPDATER

-- START BASE PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.base_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_contractor_property_id INTEGER;
	_material_property_id INTEGER;
	_length_property_id INTEGER;
	_length_value NUMERIC;
	_width_property_id INTEGER;
	_area_property_id INTEGER;
	_username TEXT;
	
BEGIN
--assign property ids
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_length_property_id = (SELECT id FROM property WHERE name = 'length');
	_length_value = (SELECT ST_Length(feature_geometry.geom_line::geography) FROM feature_geometry WHERE feature_id = (SELECT currval('feature_base_id_seq')))::NUMERIC(11,2);
	_width_property_id = (SELECT id FROM property WHERE name = 'width');
	_area_property_id = (SELECT id FROM property WHERE name = 'area');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
	
--capture material
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _material_property_id,
    NEW.material,
	_username
    );
	
--capture length
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _length_property_id,
    _length_value::TEXT,
	_username
    );

--capture width
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _width_property_id,
    NEW.width,
	_username
    );

--capture area
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _area_property_id,
    (_length_value * NEW.width::NUMERIC(11,2))::NUMERIC(11,2)::TEXT,
	_username
    );

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.base_property_inserter()
    OWNER TO doadmin;
-- END BASE PROPERTY INSERTER

-- START BASE PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.base_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_contractor_property_id INTEGER;
	_material_property_id INTEGER;
	_length_property_id INTEGER;
	_length_value NUMERIC;
	_width_property_id INTEGER;
	_area_property_id INTEGER;
	_username TEXT;

BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_length_property_id = (SELECT id FROM property WHERE name = 'length');
	_length_value = (SELECT ST_Length(feature_geometry.geom_line::geography) FROM feature_geometry WHERE feature_id = _feature_id)::NUMERIC(11,2);
	_width_property_id = (SELECT id FROM property WHERE name = 'width');
	_area_property_id = (SELECT id FROM property WHERE name = 'area');
	_username = _username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update material
UPDATE feature_property
	SET value_text = NEW.material
	WHERE feature_id = _feature_id AND property_id = _material_property_id;

--update length
UPDATE feature_property
	SET value_text = _length_value::TEXT
	WHERE feature_id = _feature_id AND property_id = _length_property_id;
	
--update width
UPDATE feature_property
	SET value_text = NEW.width
	WHERE feature_id = _feature_id AND property_id = _width_property_id;
	
--update area
UPDATE feature_property
	SET value_text = (_length_value * NEW.width::NUMERIC(11,2))::NUMERIC(11,2)::TEXT
	WHERE feature_id = _feature_id AND property_id = _area_property_id;

--update username for entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;
	
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.base_property_updater()
    OWNER TO doadmin;
-- END BASE PROPERTY UPDATER

-- START BOX PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.box_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_material_property_id INTEGER;
	_username TEXT;
BEGIN
--assign property ids
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--capture brand 
INSERT INTO feature_property (
    id            		,
	feature_id  		,
    property_id 		,
	value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
    (SELECT currval('feature_base_id_seq')),
    _brand_property_id 	,
    NEW.brand,
	_username
    );

--capture model
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _model_property_id,
    NEW.model,
	_username
    );

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
	
--capture material
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _material_property_id,
    NEW.material,
	_username
    );
	
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.box_property_inserter()
    OWNER TO doadmin;
-- END BOX PROPERTY INSERTER

-- START BOX PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.box_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_material_property_id INTEGER;
	_username TEXT;
	
BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--update brand
UPDATE feature_property
	SET value_text = NEW.brand
	WHERE feature_id = _feature_id AND property_id = _brand_property_id;
	
--update model
UPDATE feature_property
	SET value_text = NEW.model
	WHERE feature_id = _feature_id AND property_id = _model_property_id;
	
--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update material
UPDATE feature_property
	SET value_text = NEW.material
	WHERE feature_id = _feature_id AND property_id = _material_property_id;

--update username for all entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.box_property_updater()
    OWNER TO doadmin;
-- END BOX PROPERTY UPDATER

-- START BRIDGE PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.bridge_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_contractor_property_id INTEGER;
	_length_property_id INTEGER;
	_length_value NUMERIC;
	_width_property_id INTEGER;
	_area_property_id INTEGER;
	_username TEXT;
	
BEGIN
--assign property ids
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_length_property_id = (SELECT id FROM property WHERE name = 'length');
	_length_value = (SELECT ST_Length(feature_geometry.geom_line::geography) FROM feature_geometry WHERE feature_id = (SELECT currval('feature_base_id_seq')))::NUMERIC(11,2);
	_width_property_id = (SELECT id FROM property WHERE name = 'width');
	_area_property_id = (SELECT id FROM property WHERE name = 'area');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
	
--capture length
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _length_property_id,
    _length_value::TEXT,
	_username
    );

--capture width
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _width_property_id,
    NEW.width,
	_username
    );

--capture area
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _area_property_id,
    (_length_value * NEW.width::NUMERIC(11,2))::NUMERIC(11,2)::TEXT,
	_username
    );

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.bridge_property_inserter()
    OWNER TO doadmin;
-- END BRIDGE PROPERTY INSERTER

-- START BRIDGE PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.bridge_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_contractor_property_id INTEGER;
	_length_property_id INTEGER;
	_length_value NUMERIC;
	_width_property_id INTEGER;
	_area_property_id INTEGER;
	_username TEXT;

BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_length_property_id = (SELECT id FROM property WHERE name = 'length');
	_length_value = (SELECT ST_Length(feature_geometry.geom_line::geography) FROM feature_geometry WHERE feature_id = _feature_id)::NUMERIC(11,2);
	_width_property_id = (SELECT id FROM property WHERE name = 'width');
	_area_property_id = (SELECT id FROM property WHERE name = 'area');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update length
UPDATE feature_property
	SET value_text = _length_value::TEXT
	WHERE feature_id = _feature_id AND property_id = _length_property_id;
	
--update width
UPDATE feature_property
	SET value_text = NEW.width
	WHERE feature_id = _feature_id AND property_id = _width_property_id;
	
--update area
UPDATE feature_property
	SET value_text = (_length_value * NEW.width::NUMERIC(11,2))::NUMERIC(11,2)::TEXT
	WHERE feature_id = _feature_id AND property_id = _area_property_id;

-- update username for entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;
	
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.bridge_property_updater()
    OWNER TO doadmin;
-- END BRIDGE PROPERTY UPDATER

-- START BUILDING PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.building_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_contractor_property_id INTEGER;
	_footprint_property_id INTEGER;
	_area_property_id INTEGER;
	_area_value NUMERIC;
	_floor_area_property_id INTEGER;
	_height_property_id INTEGER;
	_username TEXT;
	
BEGIN
--assign property ids
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_footprint_property_id = (SELECT id FROM property WHERE name = 'footprint');
	_area_property_id = (SELECT id FROM property WHERE name = 'area');
	_area_value = (SELECT ST_Area(feature_geometry.geom_polygon::geography) FROM feature_geometry WHERE feature_id = (SELECT currval('feature_base_id_seq')))::NUMERIC(11,2);
	_floor_area_property_id = (SELECT id FROM property WHERE name = 'floor_area');
	_height_property_id = (SELECT id FROM property WHERE name = 'height');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
	
--capture footprint
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _footprint_property_id,
    NEW.footprint,
	_username
    );
	
-- capture area
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _area_property_id,
    _area_value::TEXT,
	_username
    );


--capture floor_area
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _floor_area_property_id,
    NEW.floor_area,
	_username
    );
	
--capture height
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _height_property_id,
    NEW.height,
	_username
    );

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.building_property_inserter()
    OWNER TO doadmin;
-- END BUILDING PROPERTY INSERTER

-- START BUILDING PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.building_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_contractor_property_id INTEGER;
	_footprint_property_id INTEGER;
	_area_property_id INTEGER;
	_area_value NUMERIC;
	_floor_area_property_id INTEGER;
	_height_property_id INTEGER;
	_username TEXT;

BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_footprint_property_id = (SELECT id FROM property WHERE name = 'footprint');
	_area_property_id = (SELECT id FROM property WHERE name = 'area');
	_area_value = (SELECT ST_Area(feature_geometry.geom_polygon::geography) FROM feature_geometry WHERE feature_id = _feature_id)::NUMERIC(11,2);
	_floor_area_property_id = (SELECT id FROM property WHERE name = 'floor_area');
	_height_property_id = (SELECT id FROM property WHERE name = 'height');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update footprint
UPDATE feature_property
	SET value_text = NEW.footprint
	WHERE feature_id = _feature_id AND property_id = _footprint_property_id;
	
--update area
UPDATE feature_property
	SET value_text = _area_value::TEXT
	WHERE feature_id = _feature_id AND property_id = _area_property_id;

--update floor_area
UPDATE feature_property
	SET value_text = NEW.floor_area
	WHERE feature_id = _feature_id AND property_id = _floor_area_property_id;
	
--update height
UPDATE feature_property
	SET value_text = NEW.height
	WHERE feature_id = _feature_id AND property_id = _height_property_id;

--update username for entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.building_property_updater()
    OWNER TO doadmin;
-- END BUILDING PROPERTY UPDATER

-- START CATCH BASIN PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.catch_basin_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_material_property_id INTEGER;
	_username TEXT;
	
BEGIN
--assign property ids
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--capture brand 
INSERT INTO feature_property (
    id            		,
	feature_id  		,
    property_id 		,
	value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
    (SELECT currval('feature_base_id_seq')),
    _brand_property_id 	,
    NEW.brand,
	_username
    );

--capture model
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _model_property_id,
    NEW.model,
	_username
    );

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
	
--capture material
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _material_property_id,
    NEW.material,
	_username
    );
	

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.catch_basin_property_inserter()
    OWNER TO doadmin;
-- END CATCH BASIN PROPERTY INSERTER

-- START CATCH BASIN PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.catch_basin_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_material_property_id INTEGER;
	_username TEXT;

BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--update brand
UPDATE feature_property
	SET value_text = NEW.brand
	WHERE feature_id = _feature_id AND property_id = _brand_property_id;
	
--update model
UPDATE feature_property
	SET value_text = NEW.model
	WHERE feature_id = _feature_id AND property_id = _model_property_id;
	
--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update material
UPDATE feature_property
	SET value_text = NEW.material
	WHERE feature_id = _feature_id AND property_id = _material_property_id;

--update username for entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.catch_basin_property_updater()
    OWNER TO doadmin;
-- END CATCH BASIN PROPERTY UPDATER

-- START CHANNEL PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.channel_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_material_property_id INTEGER;
	_length_property_id INTEGER;
	_length_value NUMERIC;
	_username TEXT;
	
BEGIN
--assign property ids
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_length_property_id = (SELECT id FROM property WHERE name = 'length');
	_length_value = (SELECT ST_Length(feature_geometry.geom_line::geography) FROM feature_geometry WHERE feature_id = (SELECT currval('feature_base_id_seq')))::NUMERIC(11,2);
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--capture brand 
INSERT INTO feature_property (
    id            		,
	feature_id  		,
    property_id 		,
	value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
    (SELECT currval('feature_base_id_seq')),
    _brand_property_id 	,
    NEW.brand,
	_username
    );

--capture model
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _model_property_id,
    NEW.model,
	_username
    );

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
	
--capture material
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _material_property_id,
    NEW.material,
	_username
    );
	
	
--capture length
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _length_property_id,
    _length_value::TEXT,
	_username
    );

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.channel_property_inserter()
    OWNER TO doadmin;
-- END CHANNEL PROPERTY INSERTER

-- START CHANGE TO CHANNEL PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.channel_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_material_property_id INTEGER;
	_length_property_id INTEGER;
	_length_value NUMERIC;
	_username TEXT;

BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_length_property_id = (SELECT id FROM property WHERE name = 'length');
	_length_value = (SELECT ST_Length(feature_geometry.geom_line::geography) FROM feature_geometry WHERE feature_id = _feature_id)::NUMERIC(11,2);
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);
	
--update brand
UPDATE feature_property
	SET value_text = NEW.brand
	WHERE feature_id = _feature_id AND property_id = _brand_property_id;
	
--update model
UPDATE feature_property
	SET value_text = NEW.model
	WHERE feature_id = _feature_id AND property_id = _model_property_id;
	
--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update material
UPDATE feature_property
	SET value_text = NEW.material
	WHERE feature_id = _feature_id AND property_id = _material_property_id;

--update length
UPDATE feature_property
	SET value_text = _length_value::TEXT
	WHERE feature_id = _feature_id AND property_id = _length_property_id;

--update username for entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.channel_property_updater()
    OWNER TO doadmin;
-- END CHANGE TO CHANNEL PROPERTY UPDATER

-- START CLEANOUT PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.cleanout_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_material_property_id INTEGER;
	_size_property_id INTEGER;
	_load_rating_property_id INTEGER;
	_username TEXT;
	
BEGIN
--assign property ids
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_size_property_id = (SELECT id FROM property WHERE name = 'size');
	_load_rating_property_id = (SELECT id FROM property WHERE name = 'load_rating');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--capture brand 
INSERT INTO feature_property (
    id            		,
	feature_id  		,
    property_id 		,
	value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
    (SELECT currval('feature_base_id_seq')),
    _brand_property_id 	,
    NEW.brand,
	_username
    );

--capture model
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _model_property_id,
    NEW.model,
	_username
    );

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
	
--capture material
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _material_property_id,
    NEW.material,
	_username
    );
	
--capture size
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _size_property_id,
    NEW.size,
	_username
    );

--capture load rating
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _load_rating_property_id,
    NEW.load_rating,
	_username
    );

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.cleanout_property_inserter()
    OWNER TO doadmin;
-- END CLEANOUT PROPERTY INSERTER

-- START CLEANOUT PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.cleanout_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_material_property_id INTEGER;
	_size_property_id INTEGER;
	_load_rating_property_id INTEGER;
	_username TEXT;

BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_size_property_id = (SELECT id FROM property WHERE name = 'size');
	_load_rating_property_id = (SELECT id FROM property WHERE name = 'load_rating');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);
	
--update brand
UPDATE feature_property
	SET value_text = NEW.brand
	WHERE feature_id = _feature_id AND property_id = _brand_property_id;
	
--update model
UPDATE feature_property
	SET value_text = NEW.model
	WHERE feature_id = _feature_id AND property_id = _model_property_id;
	
--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update material
UPDATE feature_property
	SET value_text = NEW.material
	WHERE feature_id = _feature_id AND property_id = _material_property_id;
	
--update size
UPDATE feature_property
	SET value_text = NEW.size
	WHERE feature_id = _feature_id AND property_id = _size_property_id;
	
--update load rating
UPDATE feature_property
	SET value_text = NEW.load_rating
	WHERE feature_id = _feature_id AND property_id = _load_rating_property_id;

UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.cleanout_property_updater()
    OWNER TO doadmin;
-- END CLEANOUT PROPERTY UPDATER

-- START CONTROL PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.control_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_username TEXT;
	
BEGIN
--assign property ids
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--capture brand 
INSERT INTO feature_property (
    id            		,
	feature_id  		,
    property_id 		,
	value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
    (SELECT currval('feature_base_id_seq')),
    _brand_property_id 	,
    NEW.brand,
	_username
    );

--capture model
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _model_property_id,
    NEW.model,
	_username
    );

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.control_property_inserter()
    OWNER TO doadmin;
-- END CONTROL PROPERTY INSERTER

-- START CONTROL PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.control_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_username TEXT;

BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--update brand
UPDATE feature_property
	SET value_text = NEW.brand
	WHERE feature_id = _feature_id AND property_id = _brand_property_id;
	
--update model
UPDATE feature_property
	SET value_text = NEW.model
	WHERE feature_id = _feature_id AND property_id = _model_property_id;
	
--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update username for entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;
	
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.control_property_updater()
    OWNER TO doadmin;
-- END CONTROL PROPERTY UPDATER

-- START ENGINEERED LAND PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.engineered_land_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_contractor_property_id INTEGER;
	_area_property_id INTEGER;
	_area_value NUMERIC;
	_username TEXT;
	
BEGIN
--assign property ids
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_area_property_id = (SELECT id FROM property WHERE name = 'area');
	_area_value = (SELECT ST_Area(feature_geometry.geom_polygon::geography) FROM feature_geometry WHERE feature_id = (SELECT currval('feature_base_id_seq')))::NUMERIC(11,2);
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
	
--capture area
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _area_property_id,
    _area_value::TEXT,
	_username
    );
	
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.engineered_land_property_inserter()
    OWNER TO doadmin;
-- END ENGINEERED LAND PROPERTY INSERTER

-- START ENGINEERED LAND PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.engineered_land_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_contractor_property_id INTEGER;
	_area_property_id INTEGER;
	_area_value NUMERIC;
	_username TEXT;

BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_area_property_id = (SELECT id FROM property WHERE name = 'area');
	_area_value = (SELECT ST_Area(feature_geometry.geom_polygon::geography) FROM feature_geometry WHERE feature_id = _feature_id)::NUMERIC(11,2);
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);
	
--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update area
UPDATE feature_property
	SET value_text = _area_value::TEXT
	WHERE feature_id = _feature_id AND property_id = _area_property_id;

--update username for entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.engineered_land_property_updater()
    OWNER TO doadmin;
-- END ENGINEERED LAND PROPERTY UPDATER

-- START EQUIPMENT PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.equipment_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_username TEXT;
	
BEGIN
--assign property ids
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);
	
--capture brand 
INSERT INTO feature_property (
    id            		,
	feature_id  		,
    property_id 		,
	value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
    (SELECT currval('feature_base_id_seq')),
    _brand_property_id 	,
    NEW.brand,
	_username
    );

--capture model
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _model_property_id,
    NEW.model,
	_username
    );

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.equipment_property_inserter()
    OWNER TO doadmin;
-- END EQUIPMENT PROPERTY INSERTER

-- CREATE EQUIPMPENT PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.equipment_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_username TEXT;

BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--update brand
UPDATE feature_property
	SET value_text = NEW.brand
	WHERE feature_id = _feature_id AND property_id = _brand_property_id;
	
--update model
UPDATE feature_property
	SET value_text = NEW.model
	WHERE feature_id = _feature_id AND property_id = _model_property_id;
	
--update username for entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.equipment_property_updater()
    OWNER TO doadmin;
-- END EQUIPMENT PROPERTY UPDATER

-- START FEATURE BASE INSERTER
CREATE OR REPLACE FUNCTION public.feature_base_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_asset_class_id INTEGER = TG_ARGV[0];
	_asset_sub_class_id INTEGER = TG_ARGV[1];
	_view_name TEXT = TG_ARGV[2];

BEGIN

--insert feature base values
	INSERT INTO feature_base (
		install_date,
    	description,
    	class_id, --preset value
    	sub_class_id, --preset value
    	type_id,
    	system_id,
    	cof,
    	condition_id,
		inspection_date,
    	renewal_cost,
    	maintenance_cost,
		id,
		file_reference,
		view_name, --preset value
		lifespan,
		display_label,
		user_name
    	)
	VALUES (
		NEW.install_date,
    	NEW.description,
    	_asset_class_id,
    	_asset_sub_class_id,
    	NEW.type_id,
    	NEW.system_id,
    	NEW.cof,
    	NEW.condition_id,
		NEW.inspection_date,
    	NEW.renewal_cost,
    	NEW.maintenance_cost,
		(SELECT nextval('feature_base_id_seq')),
		NEW.file_reference,
		_view_name,
		NEW.lifespan,
		NEW.display_label,
		(SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id)
	);
		
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.feature_base_inserter()
    OWNER TO doadmin;

COMMENT ON FUNCTION public.feature_base_inserter()
    IS 'pass in arguements of (''asset_class_name'', ''asset_sub_class_name'', ''view_name'')';
-- END FEATURE BASE INSERTER

-- START FEATURE BASE INSERTER NATURAL
CREATE OR REPLACE FUNCTION public.feature_base_inserter_natural()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_asset_class_id INTEGER = TG_ARGV[0];
	_asset_sub_class_id INTEGER = TG_ARGV[1];
	_view_name TEXT = TG_ARGV[2];

BEGIN

--insert feature base values
	INSERT INTO feature_base (
    	description,
    	class_id, --preset value
    	sub_class_id, --preset value
    	type_id,
    	system_id,
    	cof,
	id,
	file_reference,
	view_name, --preset value
	display_label,
	user_name
    	)
	VALUES (
    	NEW.description,
    	_asset_class_id,
    	_asset_sub_class_id,
    	NEW.type_id,
    	NEW.system_id,
    	NEW.cof,
	(SELECT nextval('feature_base_id_seq')),
	NEW.file_reference,
	_view_name,
	NEW.display_label,
	(SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id)
	);
		
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.feature_base_inserter_natural()
    OWNER TO doadmin;

COMMENT ON FUNCTION public.feature_base_inserter_natural()
    IS 'pass in arguements of (''asset_class_name'', ''asset_sub_class_name'', ''view_name'')';
-- END FEATURE BASE INSERTER NATURAL

-- START FEATURE INSERTER EQUIPMENT
CREATE OR REPLACE FUNCTION public.feature_base_inserter_equipment()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_asset_class_id INTEGER = TG_ARGV[0];
	_view_name TEXT = TG_ARGV[1];

BEGIN

--insert feature base values
	INSERT INTO feature_base (
		install_date,
    	description,
    	class_id, --preset value
    	sub_class_id,
    	type_id,
    	system_id,
    	cof,
    	condition_id,
		inspection_date,
    	renewal_cost,
    	maintenance_cost,
		id,
		file_reference,
		view_name, --preset value
		lifespan,
		parent_feature_id,
		display_label,
		user_name
    	)
	VALUES (
		NEW.install_date,
    	NEW.description,
    	_asset_class_id,
    	NEW.sub_class_id,
    	NEW.type_id,
    	NEW.system_id,
    	NEW.cof,
    	NEW.condition_id,
		NEW.inspection_date,
    	NEW.renewal_cost,
    	NEW.maintenance_cost,
		(SELECT nextval('feature_base_id_seq')),
		NEW.file_reference,
		_view_name,
		NEW.lifespan,
		NEW.parent_feature_id,
		NEW.display_label,
		(SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id)
	);
		
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.feature_base_inserter_equipment()
    OWNER TO doadmin;
-- END FEATURE BASE INSERTER EQUIPMENT

-- START FEATURE BASE INSERTER NOSUBCLASS
CREATE OR REPLACE FUNCTION public.feature_base_inserter_nosubclass()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_asset_class_id INTEGER = TG_ARGV[0];
	_view_name TEXT = TG_ARGV[1];

BEGIN

--insert feature base values
	INSERT INTO feature_base (
		install_date,
    	description,
    	class_id, --preset value
    	sub_class_id,
    	type_id,
    	system_id,
    	cof,
    	condition_id,
		inspection_date,
    	renewal_cost,
    	maintenance_cost,
		id,
		file_reference,
		view_name, --preset value
		lifespan,
		display_label,
		user_name
    	)
	VALUES (
		NEW.install_date,
    	NEW.description,
    	_asset_class_id,
    	NEW.sub_class_id,
    	NEW.type_id,
    	NEW.system_id,
    	NEW.cof,
    	NEW.condition_id,
		NEW.inspection_date,
    	NEW.renewal_cost,
    	NEW.maintenance_cost,
		(SELECT nextval('feature_base_id_seq')),
		NEW.file_reference,
		_view_name,
		NEW.lifespan,
		NEW.display_label,
		(SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id)
	);
		
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.feature_base_inserter_nosubclass()
    OWNER TO doadmin;
-- END FEATURE BASE INSERTER NOSUBCLASS

-- START FEATURE BASE UPDATER
CREATE OR REPLACE FUNCTION public.feature_base_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;

BEGIN
--set variables
	_feature_id = OLD.feature_id;

--update feature base table attributes
UPDATE feature_base
	SET 
		install_date = NEW.install_date,
		description = NEW.description,
		class_id = NEW.class_id,
		sub_class_id = NEW.sub_class_id,
		type_id = NEW.type_id,
		system_id = NEW.system_id,
		cof = NEW.cof,
		condition_id = NEW.condition_id,
		inspection_date = NEW.inspection_date,
		renewal_cost = NEW.renewal_cost,
		maintenance_cost = NEW.maintenance_cost,
		file_reference = NEW.file_reference,
		view_name = NEW.view_name,
		lifespan = NEW.lifespan,
		display_label = NEW.display_label,
		user_name = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id)
	WHERE id = _feature_id;

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.feature_base_updater()
    OWNER TO doadmin;
-- END FEATURE BASE UPDATER

-- START FEATURE BASE UPDATER EQUIPMENT
CREATE OR REPLACE FUNCTION public.feature_base_updater_equipment()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;

BEGIN
--set variables
	_feature_id = OLD.feature_id;

--update feature base table attributes
UPDATE feature_base
	SET 
		install_date = NEW.install_date,
		description = NEW.description,
		class_id = NEW.class_id,
		sub_class_id = NEW.sub_class_id,
		type_id = NEW.type_id,
		system_id = NEW.system_id,
		cof = NEW.cof,
		condition_id = NEW.condition_id,
		inspection_date = NEW.inspection_date,
		renewal_cost = NEW.renewal_cost,
		maintenance_cost = NEW.maintenance_cost,
		file_reference = NEW.file_reference,
		view_name = NEW.view_name,
		lifespan = NEW.lifespan,
		parent_feature_id = NEW.parent_feature_id,
		display_label = NEW.display_label,
		user_name = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id)
	WHERE id = _feature_id;

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.feature_base_updater_equipment()
    OWNER TO doadmin;
-- END FEATURE BASE UPDATER EQUIPMENT

-- START FEATURE BASE UPDATER NATURAL
CREATE OR REPLACE FUNCTION public.feature_base_updater_natural()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;

BEGIN
--set variables
	_feature_id = OLD.feature_id;

--update feature base table attributes
UPDATE feature_base
	SET 
		description = NEW.description,
		class_id = NEW.class_id,
		sub_class_id = NEW.sub_class_id,
		type_id = NEW.type_id,
		system_id = NEW.system_id,
		cof = NEW.cof,
		file_reference = NEW.file_reference,
		view_name = NEW.view_name,
		display_label = NEW.display_label,
		user_name = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id)
	WHERE id = _feature_id;

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.feature_base_updater_natural()
    OWNER TO doadmin;
-- END FEATURE BASE UPDATER

-- START FEATURE DELETER
CREATE OR REPLACE FUNCTION public.feature_deleter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
		_feature_id INTEGER;
	BEGIN
		_feature_id = OLD.feature_id;
	
		--delete row from feature_base
		DELETE FROM feature_base WHERE feature_base.id = _feature_id;
				
		--delete row from feature_geometry
		DELETE FROM feature_geometry WHERE feature_geometry.feature_id = _feature_id;
		
		--delete all properties from feature_property
		DELETE FROM feature_property WHERE feature_property.feature_id = _feature_id;
		
		RETURN OLD;
	
	END;
$BODY$;

ALTER FUNCTION public.feature_deleter()
    OWNER TO doadmin;
-- END FEATURE DELETER

--START FEATURE DELETER NOGEOM
CREATE OR REPLACE FUNCTION public.feature_deleter_nogeom()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
		_feature_id INTEGER;
	BEGIN
		_feature_id = OLD.feature_id;
	
		--delete row from feature_base
		DELETE FROM feature_base WHERE feature_base.id = _feature_id;
				
		
		--delete all properties from feature_property
		DELETE FROM feature_property WHERE feature_property.feature_id = _feature_id;
		
		RETURN OLD;
	
	END;
$BODY$;

ALTER FUNCTION public.feature_deleter_nogeom()
    OWNER TO doadmin;
-- END FEATURE DELETER NOGEOM

-- START FEATURE GEOMETRY LINE INSERTER
CREATE OR REPLACE FUNCTION public.feature_geometry_line_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE

BEGIN

INSERT INTO feature_geometry(
	id,
	geom_line,
	feature_id,
	user_name)
VALUES (
	(SELECT nextval('feature_geometry_id_seq')),
	NEW.geom_line,
	(SELECT currval('feature_base_id_seq')),
	(SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id)
);
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.feature_geometry_line_inserter()
    OWNER TO doadmin;
-- END FEATURE GEOMETRY LINE INSERTER

-- START FEATURE GEOMETRY LINE UPDATER
CREATE OR REPLACE FUNCTION public.feature_geometry_line_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_feature_line_id INTEGER;
	_username TEXT;
BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);
	
UPDATE feature_geometry
	SET 
		geom_line = NEW.geom_line,
		user_name = _username
	
	WHERE feature_id = _feature_id;
	

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.feature_geometry_line_updater()
    OWNER TO doadmin;
-- END FEATURE GEOMETRY LINE UPDATER

-- START FEATURE GEOMETRY POINT INSERTER
CREATE OR REPLACE FUNCTION public.feature_geometry_point_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE

BEGIN

INSERT INTO feature_geometry(
	id,
	geom_point,
	feature_id,
	user_name)
VALUES (
	(SELECT nextval('feature_geometry_id_seq')),
	NEW.geom_point,
	(SELECT currval('feature_base_id_seq')),
	(SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id)
);
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.feature_geometry_point_inserter()
    OWNER TO doadmin;
-- END FEATURE GEOMETRY POINT INSERTER

-- START FEATURE GEOMETRY POINT UPDATER
CREATE OR REPLACE FUNCTION public.feature_geometry_point_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_feature_line_id INTEGER;
	
BEGIN
--set variables
	_feature_id = OLD.feature_id;
	
UPDATE feature_geometry
	SET 
		geom_point = NEW.geom_point,
		user_name = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id)
	WHERE feature_id = _feature_id;

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.feature_geometry_point_updater()
    OWNER TO doadmin;
-- END FEATURE GEOMETRY POINT UPDATER

-- START FEATURE GEOMETRY POLYGON INSERTER
CREATE OR REPLACE FUNCTION public.feature_geometry_polygon_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE

BEGIN

INSERT INTO feature_geometry(
	id,
	geom_polygon,
	feature_id,
	user_name)
VALUES (
	(SELECT nextval('feature_geometry_id_seq')),
	NEW.geom_polygon,
	(SELECT currval('feature_base_id_seq')),
	(SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id)
);
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.feature_geometry_polygon_inserter()
    OWNER TO doadmin;
-- END FEATURE GEOMETRY POLYGON INSERTER

-- START FEATURE GEOMETRY POLYGON UPDATER
CREATE OR REPLACE FUNCTION public.feature_geometry_polygon_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_feature_line_id INTEGER;
	
BEGIN
--set variables
	_feature_id = OLD.feature_id;
	
UPDATE feature_geometry
	SET 
		geom_polygon = NEW.geom_polygon,
		user_name = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id)
	WHERE feature_id = _feature_id
;

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.feature_geometry_polygon_updater()
    OWNER TO doadmin;
-- END FEATURE GEOMETRY POLYGON UPDATER

-- START FLEET PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.fleet_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_username TEXT;
	
BEGIN
--assign property ids
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--capture brand 
INSERT INTO feature_property (
    id            		,
	feature_id  		,
    property_id 		,
	value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
    (SELECT currval('feature_base_id_seq')),
    _brand_property_id 	,
    NEW.brand,
	_username
    );

--capture model
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _model_property_id,
    NEW.model,
	_username
    );

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.fleet_property_inserter()
    OWNER TO doadmin;
-- END FLEET PROPERTY INSERTER

-- START FLEET PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.fleet_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_username TEXT;

BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--update brand
UPDATE feature_property
	SET value_text = NEW.brand
	WHERE feature_id = _feature_id AND property_id = _brand_property_id;
	
--update model
UPDATE feature_property
	SET value_text = NEW.model
	WHERE feature_id = _feature_id AND property_id = _model_property_id;
	
--update username for entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;
	
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.fleet_property_updater()
    OWNER TO doadmin;
-- END FLEET PROPERTY UPDATER

-- START GRATE PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.grate_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_material_property_id INTEGER;
	_username TEXT;
	
BEGIN
--assign property ids
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--capture brand 
INSERT INTO feature_property (
    id            		,
	feature_id  		,
    property_id 		,
	value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
    (SELECT currval('feature_base_id_seq')),
    _brand_property_id 	,
    NEW.brand,
	_username
    );

--capture model
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _model_property_id,
    NEW.model,
	_username
    );

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
	
--capture material
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _material_property_id,
    NEW.material,
	_username
    );
	

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.grate_property_inserter()
    OWNER TO doadmin;
-- END GRATE PROPERTY INSERTER

-- START GRATE PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.grate_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_material_property_id INTEGER;
	_username TEXT;

BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--update brand
UPDATE feature_property
	SET value_text = NEW.brand
	WHERE feature_id = _feature_id AND property_id = _brand_property_id;
	
--update model
UPDATE feature_property
	SET value_text = NEW.model
	WHERE feature_id = _feature_id AND property_id = _model_property_id;
	
--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update material
UPDATE feature_property
	SET value_text = NEW.material
	WHERE feature_id = _feature_id AND property_id = _material_property_id;

--update username for entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.grate_property_updater()
    OWNER TO doadmin;
-- END GRATE PROPERTY UPDATER

-- START HYDRANT PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.hydrant_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_username TEXT;
	
BEGIN
--assign property ids
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--capture brand 
INSERT INTO feature_property (
    id            		,
	feature_id  		,
    property_id 		,
	value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
    (SELECT currval('feature_base_id_seq')),
    _brand_property_id 	,
    NEW.brand,
	_username
    );

--capture model
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _model_property_id,
    NEW.model,
	_username
    );

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
	
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.hydrant_property_inserter()
    OWNER TO doadmin;
-- END HYDRANT PROPERTY INSERTER

-- START HYDRANT PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.hydrant_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_username TEXT;

BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--update brand
UPDATE feature_property
	SET value_text = NEW.brand
	WHERE feature_id = _feature_id AND property_id = _brand_property_id;
	
--update model
UPDATE feature_property
	SET value_text = NEW.model
	WHERE feature_id = _feature_id AND property_id = _model_property_id;
	
--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;

--update username for entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.hydrant_property_updater()
    OWNER TO doadmin;
-- END HYDRANT PROPERTY UPDATER

-- START LIGHT PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.light_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_username TEXT;
	
BEGIN
--assign property ids
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--capture brand 
INSERT INTO feature_property (
    id            		,
	feature_id  		,
    property_id 		,
	value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
    (SELECT currval('feature_base_id_seq')),
    _brand_property_id 	,
    NEW.brand,
	_username
    );

--capture model
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _model_property_id,
    NEW.model,
	_username
    );

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
	
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.light_property_inserter()
    OWNER TO doadmin;
-- END LIGHT PROPERTY INSERTER

-- START LIGHT PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.light_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_username TEXT;

BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--update brand
UPDATE feature_property
	SET value_text = NEW.brand
	WHERE feature_id = _feature_id AND property_id = _brand_property_id;
	
--update model
UPDATE feature_property
	SET value_text = NEW.model
	WHERE feature_id = _feature_id AND property_id = _model_property_id;
	
--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update username for entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;
	
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.light_property_updater()
    OWNER TO doadmin;
-- END LIGHT PROPERTY UPDATER

-- START MANHOLE COVER PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.manhole_cover_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_material_property_id INTEGER;
	_size_property_id INTEGER;
	_load_rating_property_id INTEGER;
	_username TEXT;
	
BEGIN
--assign property ids
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_size_property_id = (SELECT id FROM property WHERE name = 'size');
	_load_rating_property_id = (SELECT id FROM property WHERE name = 'load_rating');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--capture brand 
INSERT INTO feature_property (
    id            		,
	feature_id  		,
    property_id 		,
	value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
    (SELECT currval('feature_base_id_seq')),
    _brand_property_id 	,
    NEW.brand,
	_username
    );

--capture model
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _model_property_id,
    NEW.model,
	_username
    );

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
	
--capture material
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _material_property_id,
    NEW.material,
	_username
    );
	
--capture size
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _size_property_id,
    NEW.size,
	_username
    );

--capture load rating
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _load_rating_property_id,
    NEW.load_rating,
	_username
    );

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.manhole_cover_property_inserter()
    OWNER TO doadmin;
-- END MANHOLE COVER PROPERTY INSERTER

-- START MANHOLE COVER PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.manhole_cover_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_material_property_id INTEGER;
	_size_property_id INTEGER;
	_load_rating_property_id INTEGER;
	_username TEXT;

BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_size_property_id = (SELECT id FROM property WHERE name = 'size');
	_load_rating_property_id = (SELECT id FROM property WHERE name = 'load_rating');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);
	
--update brand
UPDATE feature_property
	SET value_text = NEW.brand
	WHERE feature_id = _feature_id AND property_id = _brand_property_id;
	
--update model
UPDATE feature_property
	SET value_text = NEW.model
	WHERE feature_id = _feature_id AND property_id = _model_property_id;
	
--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update material
UPDATE feature_property
	SET value_text = NEW.material
	WHERE feature_id = _feature_id AND property_id = _material_property_id;
	
--update size
UPDATE feature_property
	SET value_text = NEW.size
	WHERE feature_id = _feature_id AND property_id = _size_property_id;
	
--update load rating
UPDATE feature_property
	SET value_text = NEW.load_rating
	WHERE feature_id = _feature_id AND property_id = _load_rating_property_id;

UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.manhole_cover_property_updater()
    OWNER TO doadmin;
-- END MANHOLE COVER PROPERTY UPDATER

-- START MANHOLE TRUNK PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.manhole_trunk_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_material_property_id INTEGER;
	_username TEXT;
	
BEGIN
--assign property ids
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);
	
--capture brand 
INSERT INTO feature_property (
    id            		,
	feature_id  		,
    property_id 		,
	value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
    (SELECT currval('feature_base_id_seq')),
    _brand_property_id 	,
    NEW.brand,
	_username
    );

--capture model
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _model_property_id,
    NEW.model,
	_username
    );

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
	
--capture material
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _material_property_id,
    NEW.material,
	_username
    );
	

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.manhole_trunk_property_inserter()
    OWNER TO doadmin;
-- END MANHOLE TRUNK PROPERTY INSERTER

-- START MANHOLE TRUNK PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.manhole_trunk_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_material_property_id INTEGER;
	_username TEXT;

BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);
	
--update brand
UPDATE feature_property
	SET value_text = NEW.brand
	WHERE feature_id = _feature_id AND property_id = _brand_property_id;
	
--update model
UPDATE feature_property
	SET value_text = NEW.model
	WHERE feature_id = _feature_id AND property_id = _model_property_id;
	
--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update material
UPDATE feature_property
	SET value_text = NEW.material
	WHERE feature_id = _feature_id AND property_id = _material_property_id;

--update username for entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.manhole_trunk_property_updater()
    OWNER TO doadmin;
-- END MANHOLE TRUNK PROPERTY UPDATER

-- START METER PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.meter_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_username TEXT;
	
BEGIN
--assign property ids
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);
	

--capture brand 
INSERT INTO feature_property (
    id            		,
	feature_id  		,
    property_id 		,
	value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
    (SELECT currval('feature_base_id_seq')),
    _brand_property_id 	,
    NEW.brand,
	_username
    );

--capture model
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _model_property_id,
    NEW.model,
	_username
    );

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
		

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.meter_property_inserter()
    OWNER TO doadmin;
-- END METER PROPERTY INSERTER

-- START METER PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.meter_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_username TEXT;

BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);
	
--update brand
UPDATE feature_property
	SET value_text = NEW.brand
	WHERE feature_id = _feature_id AND property_id = _brand_property_id;
	
--update model
UPDATE feature_property
	SET value_text = NEW.model
	WHERE feature_id = _feature_id AND property_id = _model_property_id;
	
--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update username for entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.meter_property_updater()
    OWNER TO doadmin;
-- END METER PROPERTY UPDATER

-- START MONUMENT PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.monument_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_contractor_property_id INTEGER;
	_username TEXT;
BEGIN
--assign property ids
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.monument_property_inserter()
    OWNER TO doadmin;
-- END MONUMENT PROPERTY INSERTER

-- START MONUMENT PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.monument_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_contractor_property_id INTEGER;
	_username TEXT;

BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);
	
--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;

--update username for entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.monument_property_updater()
    OWNER TO doadmin;
-- END MONUMENT PROPERTY UPDATER

-- START MOTOR PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.motor_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_power_output_property_id INTEGER;
	_username TEXT;
	
BEGIN
--assign property ids
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_power_output_property_id = (SELECT id FROM property WHERE name = 'power_output');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--capture brand 
INSERT INTO feature_property (
    id            		,
	feature_id  		,
    property_id 		,
	value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
    (SELECT currval('feature_base_id_seq')),
    _brand_property_id 	,
    NEW.brand,
	_username
    );

--capture model
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _model_property_id,
    NEW.model,
	_username
    );

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
	
--capture power_output
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _power_output_property_id,
    NEW.power_output,
	_username
    );
	

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.motor_property_inserter()
    OWNER TO doadmin;
-- END MOTOR PROPERTY INSERTER

-- START MOTOR PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.motor_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_power_output_property_id INTEGER;
	_username TEXT;
	
BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_power_output_property_id = (SELECT id FROM property WHERE name = 'power_output');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--update brand
UPDATE feature_property
	SET value_text = NEW.brand
	WHERE feature_id = _feature_id AND property_id = _brand_property_id;
	
--update model
UPDATE feature_property
	SET value_text = NEW.model
	WHERE feature_id = _feature_id AND property_id = _model_property_id;
	
--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update power output
UPDATE feature_property
	SET value_text = NEW.power_output
	WHERE feature_id = _feature_id AND property_id = _power_output_property_id;

--update username entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.motor_property_updater()
    OWNER TO doadmin;
-- END MOTOR PROPERTY UPDATER

-- START PART PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.part_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_material_property_id INTEGER;
	_diameter_property_id INTEGER;
	_username TEXT;
	
	
BEGIN
--assign property ids
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_diameter_property_id = (SELECT id FROM property WHERE name = 'diameter');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);
	
--capture brand 
INSERT INTO feature_property (
    id            		,
	feature_id  		,
    property_id 		,
	value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
    (SELECT currval('feature_base_id_seq')),
    _brand_property_id 	,
    NEW.brand,
	_username
    );

--capture model
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _model_property_id,
    NEW.model,
	_username
    );

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
	
--capture material
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _material_property_id,
    NEW.material,
	_username
    );
	

	--capture diameter
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _diameter_property_id,
    NEW.diameter,
	_username
    );

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.part_property_inserter()
    OWNER TO doadmin;
-- END PART PROPERTY INSERTER

-- START PART PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.part_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_material_property_id INTEGER;
	_diameter_property_id INTEGER;
	_username TEXT;
	
BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_diameter_property_id = (SELECT id FROM property WHERE name = 'diameter');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);
	
--update brand
UPDATE feature_property
	SET value_text = NEW.brand
	WHERE feature_id = _feature_id AND property_id = _brand_property_id;
	
--update model
UPDATE feature_property
	SET value_text = NEW.model
	WHERE feature_id = _feature_id AND property_id = _model_property_id;
	
--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update material
UPDATE feature_property
	SET value_text = NEW.material
	WHERE feature_id = _feature_id AND property_id = _material_property_id;
	
--update diameter
UPDATE feature_property
	SET value_text = NEW.diameter
	WHERE feature_id = _feature_id AND property_id = _diameter_property_id;

--update username for entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.part_property_updater()
    OWNER TO doadmin;
-- END PART PROPERTY UPDATER

-- START PEDESTRIAN WALKWAY PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.pedestrian_walkway_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_contractor_property_id INTEGER;
	_material_property_id INTEGER;
	_length_property_id INTEGER;
	_length_value NUMERIC;
	_width_property_id INTEGER;
	_area_property_id INTEGER;
	_username TEXT;
	
BEGIN
--assign property ids
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_length_property_id = (SELECT id FROM property WHERE name = 'length');
	_length_value = (SELECT ST_Length(feature_geometry.geom_line::geography) FROM feature_geometry WHERE feature_id = (SELECT currval('feature_base_id_seq')))::NUMERIC(11,2);
	_width_property_id = (SELECT id FROM property WHERE name = 'width');
	_area_property_id = (SELECT id FROM property WHERE name = 'area');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
	
--capture material
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _material_property_id,
    NEW.material,
	_username
    );
	
--capture length
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _length_property_id,
    _length_value::TEXT,
	_username
    );

--capture width
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _width_property_id,
    NEW.width,
	_username
    );

--capture area
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _area_property_id,
    (_length_value * NEW.width::NUMERIC(11,2))::NUMERIC(11,2)::TEXT,
	_username
    );

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.pedestrian_walkway_property_inserter()
    OWNER TO doadmin;
-- END PEDESTRIAN WALKWAY PROPERTY INSERTER

-- START PEDESTRIAN WALKWAY PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.pedestrian_walkway_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_contractor_property_id INTEGER;
	_material_property_id INTEGER;
	_length_property_id INTEGER;
	_length_value NUMERIC;
	_width_property_id INTEGER;
	_area_property_id INTEGER;
	_username TEXT;

BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_length_property_id = (SELECT id FROM property WHERE name = 'length');
	_length_value = (SELECT ST_Length(feature_geometry.geom_line::geography) FROM feature_geometry WHERE feature_id = _feature_id)::NUMERIC(11,2);
	_width_property_id = (SELECT id FROM property WHERE name = 'width');
	_area_property_id = (SELECT id FROM property WHERE name = 'area');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update material
UPDATE feature_property
	SET value_text = NEW.material
	WHERE feature_id = _feature_id AND property_id = _material_property_id;

--update length
UPDATE feature_property
	SET value_text = _length_value::TEXT
	WHERE feature_id = _feature_id AND property_id = _length_property_id;
	
--update width
UPDATE feature_property
	SET value_text = NEW.width
	WHERE feature_id = _feature_id AND property_id = _width_property_id;
	
--update area
UPDATE feature_property
	SET value_text = (_length_value * NEW.width::NUMERIC(11,2))::NUMERIC(11,2)::TEXT
	WHERE feature_id = _feature_id AND property_id = _area_property_id;

--update username for entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.pedestrian_walkway_property_updater()
    OWNER TO doadmin;
-- END PEDESTRIAN WALKWAY PROPERTY UPDATED

-- -- START PIPE PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.pipe_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_diameter_property_id INTEGER;
	_material_property_id INTEGER;
	_length_property_id INTEGER;
	_length_value NUMERIC;
	_username TEXT;
	
BEGIN
--assign property ids
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_diameter_property_id = (SELECT id FROM property WHERE name = 'diameter');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_length_property_id = (SELECT id FROM property WHERE name = 'length');
	_length_value = (SELECT ST_Length(feature_geometry.geom_line::geography) FROM feature_geometry WHERE feature_id = (SELECT currval('feature_base_id_seq')))::NUMERIC(11,2);
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--capture brand 
INSERT INTO feature_property (
    id            		,
	feature_id  		,
    property_id 		,
	value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
    (SELECT currval('feature_base_id_seq')),
    _brand_property_id 	,
    NEW.brand,
	_username
    );

--capture model
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _model_property_id,
    NEW.model,
	_username
    );

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
	
--capture material
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _material_property_id,
    NEW.material,
	_username
    );
	
--capture diameter
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _diameter_property_id,
    NEW.diameter,
	_username
    );
	
--capture length
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _length_property_id,
    _length_value::TEXT,
	_username
    );

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.pipe_property_inserter()
    OWNER TO doadmin;
	
-- -- END PIPE PROPERTY INSERTER

-- -- START PIPE PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.pipe_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_diameter_property_id INTEGER;
	_material_property_id INTEGER;
	_length_property_id INTEGER;
	_length_value NUMERIC;
	_username TEXT;

BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_diameter_property_id = (SELECT id FROM property WHERE name = 'diameter');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_length_property_id = (SELECT id FROM property WHERE name = 'length');
	_length_value = (SELECT ST_Length(feature_geometry.geom_line::geography) FROM feature_geometry WHERE feature_id = _feature_id)::NUMERIC(11,2);
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--update brand
UPDATE feature_property
	SET value_text = NEW.brand
	WHERE feature_id = _feature_id AND property_id = _brand_property_id;
	
--update model
UPDATE feature_property
	SET value_text = NEW.model
	WHERE feature_id = _feature_id AND property_id = _model_property_id;
	
--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update material
UPDATE feature_property
	SET value_text = NEW.material
	WHERE feature_id = _feature_id AND property_id = _material_property_id;

--update diameter
UPDATE feature_property
	SET value_text = NEW.diameter
	WHERE feature_id = _feature_id AND property_id = _diameter_property_id;

--update length
UPDATE feature_property
	SET value_text = _length_value::TEXT
	WHERE feature_id = _feature_id AND property_id = _length_property_id;

--update username for entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.pipe_property_updater()
    OWNER TO doadmin;
-- -- END PIPE PROPERTY UPDATER

-- START POLE PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.pole_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_username TEXT;
	
BEGIN
--assign property ids
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--capture brand 
INSERT INTO feature_property (
    id            		,
	feature_id  		,
    property_id 		,
	value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
    (SELECT currval('feature_base_id_seq')),
    _brand_property_id 	,
    NEW.brand,
	_username
    );

--capture model
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _model_property_id,
    NEW.model,
	_username
    );

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
	
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.pole_property_inserter()
    OWNER TO doadmin;
-- END POLE PROPERTY INSERTER

-- START POLE PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.pole_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_username TEXT;

BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--update brand
UPDATE feature_property
	SET value_text = NEW.brand
	WHERE feature_id = _feature_id AND property_id = _brand_property_id;
	
--update model
UPDATE feature_property
	SET value_text = NEW.model
	WHERE feature_id = _feature_id AND property_id = _model_property_id;
	
--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update username for entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;
	
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.pole_property_updater()
    OWNER TO doadmin;
-- END POLE PROPERTY UPDATER

-- START PUMP PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.pump_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_username TEXT;
	
BEGIN
--assign property ids
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--capture brand 
INSERT INTO feature_property (
    id            		,
	feature_id  		,
    property_id 		,
	value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
    (SELECT currval('feature_base_id_seq')),
    _brand_property_id 	,
    NEW.brand,
	_username
    );

--capture model
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _model_property_id,
    NEW.model,
	_username
    );

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
	
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.pump_property_inserter()
    OWNER TO doadmin;
-- END PROPERTY INSERTER

-- START PUMP PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.pump_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_username TEXT;

BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--update brand
UPDATE feature_property
	SET value_text = NEW.brand
	WHERE feature_id = _feature_id AND property_id = _brand_property_id;
	
--update model
UPDATE feature_property
	SET value_text = NEW.model
	WHERE feature_id = _feature_id AND property_id = _model_property_id;
	
--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update username for entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.pump_property_updater()
    OWNER TO doadmin;
-- END PUMP PROPERTY UPDATER

-- START RECREATIONAL STRUCTURE PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.recreational_structure_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_footprint_property_id INTEGER;
	_area_property_id INTEGER;
	_username TEXT;
	_area_value NUMERIC;
BEGIN
--assign property ids
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_footprint_property_id = (SELECT id FROM property WHERE name = 'footprint');
	_area_property_id = (SELECT id FROM property WHERE name = 'area');
	_area_value = (SELECT ST_Area(feature_geometry.geom_polygon::geography) FROM feature_geometry WHERE feature_id = (SELECT currval('feature_base_id_seq')))::NUMERIC(11,2);
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--capture brand 
INSERT INTO feature_property (
    id            		,
	feature_id  		,
    property_id 		,
	value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
    (SELECT currval('feature_base_id_seq')),
    _brand_property_id 	,
    NEW.brand,
	_username
    );

--capture model
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _model_property_id,
    NEW.model,
	_username
    );

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );

--capture area
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _area_property_id,
    _area_value::TEXT,
	_username
    );

--capture footprint
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _footprint_property_id,
    NEW.footprint,
	_username
    );
	

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.recreational_structure_property_inserter()
    OWNER TO doadmin;
-- END RECREATIONAL STRUCTURE PROPERTY INSERTER

-- START RECREATIONAL STRUCTURE PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.recreational_structure_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_area_property_id INTEGER;
	_area_value NUMERIC;
	_footprint_property_id INTEGER;
	_username TEXT;

BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_area_property_id = (SELECT id FROM property WHERE name = 'area');
	_area_value = (SELECT ST_Area(feature_geometry.geom_polygon::geography) FROM feature_geometry WHERE feature_id = _feature_id)::NUMERIC(11,2);
	_footprint_property_id = (SELECT id FROM property WHERE name = 'footprint');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--update brand
UPDATE feature_property
	SET value_text = NEW.brand
	WHERE feature_id = _feature_id AND property_id = _brand_property_id;
	
--update model
UPDATE feature_property
	SET value_text = NEW.model
	WHERE feature_id = _feature_id AND property_id = _model_property_id;
	
--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
-- update area
UPDATE feature_property
	SET value_text = _area_value::TEXT
	WHERE feature_id = _feature_id AND property_id = _area_property_id;
	
--update footprint
UPDATE feature_property
	SET value_text = NEW.footprint
	WHERE feature_id = _feature_id AND property_id = _footprint_property_id;

--update username for entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.recreational_structure_property_updater()
    OWNER TO doadmin;
-- END RECREATIONAL STRUCTURE PROPERTY UPDATER

-- START RESERVOIR PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.reservoir_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_capacity_property_id INTEGER;
	_username TEXT;
	
BEGIN
--assign property ids
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_capacity_property_id = (SELECT id FROM property WHERE name = 'capacity');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--capture brand 
INSERT INTO feature_property (
    id            		,
	feature_id  		,
    property_id 		,
	value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
    (SELECT currval('feature_base_id_seq')),
    _brand_property_id 	,
    NEW.brand,
	_username
    );

--capture model
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _model_property_id,
    NEW.model,
	_username
    );

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
	
--capture capacity
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _capacity_property_id,
    NEW.capacity,
	_username
    );
	

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.reservoir_property_inserter()
    OWNER TO doadmin;
-- END RESERVOIR PROPERTY INSERTER

-- START RESERVOIR PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.reservoir_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_capacity_property_id INTEGER;
	_username TEXT;

BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_capacity_property_id = (SELECT id FROM property WHERE name = 'capacity');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--update brand
UPDATE feature_property
	SET value_text = NEW.brand
	WHERE feature_id = _feature_id AND property_id = _brand_property_id;
	
--update model
UPDATE feature_property
	SET value_text = NEW.model
	WHERE feature_id = _feature_id AND property_id = _model_property_id;
	
--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update capacity
UPDATE feature_property
	SET value_text = NEW.capacity
	WHERE feature_id = _feature_id AND property_id = _capacity_property_id;

--update username for entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;
	
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.reservoir_property_updater()
    OWNER TO doadmin;
-- END RESERVOIR PROPERTY UPDATER

-- START ROAD OVERLAY PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.road_overlay_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_contractor_property_id INTEGER;
	_material_property_id INTEGER;
	_length_property_id INTEGER;
	_length_value NUMERIC;
	_width_property_id INTEGER;
	_area_property_id INTEGER;
	_username TEXT;
	
BEGIN
--assign property ids
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_length_property_id = (SELECT id FROM property WHERE name = 'length');
	_length_value = (SELECT ST_Length(feature_geometry.geom_line::geography) FROM feature_geometry WHERE feature_id = (SELECT currval('feature_base_id_seq')))::NUMERIC(11,2);
	_width_property_id = (SELECT id FROM property WHERE name = 'width');
	_area_property_id = (SELECT id FROM property WHERE name = 'area');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
	
--capture material
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _material_property_id,
    NEW.material,
	_username
    );
	
--capture length
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _length_property_id,
    _length_value::TEXT,
	_username
    );

--capture width
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _width_property_id,
    NEW.width,
	_username
    );

--capture area
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _area_property_id,
    (_length_value * NEW.width::NUMERIC(11,2))::NUMERIC(11,2)::TEXT,
	_username
    );
	

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.road_overlay_property_inserter()
    OWNER TO doadmin;
-- END ROAD OVERLAY PROPERTY INSERTER

-- START ROAD OVERLAY PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.road_overlay_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_contractor_property_id INTEGER;
	_material_property_id INTEGER;
	_length_property_id INTEGER;
	_length_value NUMERIC;
	_width_property_id INTEGER;
	_area_property_id INTEGER;
	_username TEXT;
	
BEGIN
--set variablesp
	_feature_id = OLD.feature_id;
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_material_property_id = (SELECT id FROM property WHERE name = 'material');
	_length_property_id = (SELECT id FROM property WHERE name = 'length');
	_length_value = (SELECT ST_Length(feature_geometry.geom_line::geography) FROM feature_geometry WHERE feature_id = _feature_id)::NUMERIC(11,2);
	_width_property_id = (SELECT id FROM property WHERE name = 'width');
	_area_property_id = (SELECT id FROM property WHERE name = 'area');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);
	
--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update material
UPDATE feature_property
	SET value_text = NEW.material
	WHERE feature_id = _feature_id AND property_id = _material_property_id;

--update length
UPDATE feature_property
	SET value_text = _length_value::TEXT
	WHERE feature_id = _feature_id AND property_id = _length_property_id;
	
--update width
UPDATE feature_property
	SET value_text = NEW.width
	WHERE feature_id = _feature_id AND property_id = _width_property_id;
	
--update area
UPDATE feature_property
	SET value_text = (_length_value * NEW.width::NUMERIC(11,2))::NUMERIC(11,2)::TEXT
	WHERE feature_id = _feature_id AND property_id = _area_property_id;

--update username for entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.road_overlay_property_updater()
    OWNER TO doadmin;
-- END ROAD OVERLAY PROPERTY UPDATER

-- START TANK PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.tank_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_capacity_property_id INTEGER;
	_username TEXT;
	
BEGIN
--assign property ids
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_capacity_property_id = (SELECT id FROM property WHERE name = 'capacity');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--capture brand 
INSERT INTO feature_property (
    id            		,
	feature_id  		,
    property_id 		,
	value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
    (SELECT currval('feature_base_id_seq')),
    _brand_property_id 	,
    NEW.brand,
	_username
    );

--capture model
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _model_property_id,
    NEW.model,
	_username
    );

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
	
--capture capacity
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _capacity_property_id,
    NEW.capacity,
	_username
    );
	

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.tank_property_inserter()
    OWNER TO doadmin;
-- END TANK PROPERTY INSERTER

-- START TANK PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.tank_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_capacity_property_id INTEGER;
	_username TEXT;

BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_capacity_property_id = (SELECT id FROM property WHERE name = 'capacity');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--update brand
UPDATE feature_property
	SET value_text = NEW.brand
	WHERE feature_id = _feature_id AND property_id = _brand_property_id;
	
--update model
UPDATE feature_property
	SET value_text = NEW.model
	WHERE feature_id = _feature_id AND property_id = _model_property_id;
	
--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update capacity
UPDATE feature_property
	SET value_text = NEW.capacity
	WHERE feature_id = _feature_id AND property_id = _capacity_property_id;

--update username for entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;
	
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.tank_property_updater()
    OWNER TO doadmin;
-- END TANK PROPERTY UPDATER

-- START TRAFFIC SIGN OR SIGNAL PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.traffic_sign_or_signal_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_username TEXT;
	
BEGIN
--assign property ids
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--capture brand 
INSERT INTO feature_property (
    id            		,
	feature_id  		,
    property_id 		,
	value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
    (SELECT currval('feature_base_id_seq')),
    _brand_property_id 	,
    NEW.brand,
	_username
    );

--capture model
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _model_property_id,
    NEW.model,
	_username
    );

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
	
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.traffic_sign_or_signal_property_inserter()
    OWNER TO doadmin;
-- END TRAFFIC SIGN OR SIGNAL PROPERTY INSERTER

-- START TRAFFIC SIGN OR SIGNAL UPDATER
CREATE OR REPLACE FUNCTION public.traffic_sign_or_signal_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_username TEXT;

BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--update brand
UPDATE feature_property
	SET value_text = NEW.brand
	WHERE feature_id = _feature_id AND property_id = _brand_property_id;
	
--update model
UPDATE feature_property
	SET value_text = NEW.model
	WHERE feature_id = _feature_id AND property_id = _model_property_id;
	
--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update username for entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;
	
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.traffic_sign_or_signal_property_updater()
    OWNER TO doadmin;
-- END TRAFFIC SIGN OR SIGNAL PROPERTY UPDATER

-- START TREATMENT PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.treatment_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_username TEXT;
	
BEGIN
--assign property ids
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--capture brand 
INSERT INTO feature_property (
    id            		,
	feature_id  		,
    property_id 		,
	value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
    (SELECT currval('feature_base_id_seq')),
    _brand_property_id 	,
    NEW.brand,
	_username
    );

--capture model
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _model_property_id,
    NEW.model,
	_username
    );

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
	
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.treatment_property_inserter()
    OWNER TO doadmin;
-- END TREATMENT PROPERTY INSERTER

-- START TREATMENT PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.treatment_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_username TEXT;
	
BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--update brand
UPDATE feature_property
	SET value_text = NEW.brand
	WHERE feature_id = _feature_id AND property_id = _brand_property_id;
	
--update model
UPDATE feature_property
	SET value_text = NEW.model
	WHERE feature_id = _feature_id AND property_id = _model_property_id;
	
--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update username for entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;
	
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.treatment_property_updater()
    OWNER TO doadmin;
-- END TREATMENT PROPERTY UPDATER

-- START VALVE PROPERTY INSERTER
CREATE OR REPLACE FUNCTION public.valve_property_inserter()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_diameter_property_id INTEGER;
	_username TEXT;
	
BEGIN
--assign property ids
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_diameter_property_id = (SELECT id FROM property WHERE name = 'diameter');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--capture brand 
INSERT INTO feature_property (
    id            		,
	feature_id  		,
    property_id 		,
	value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
    (SELECT currval('feature_base_id_seq')),
    _brand_property_id 	,
    NEW.brand,
	_username
    );

--capture model
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _model_property_id,
    NEW.model,
	_username
    );

--capture contractor
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _contractor_property_id,
    NEW.contractor,
	_username
    );
	
--capture diameter
INSERT INTO feature_property (
	id            		,
    feature_id  		,
    property_id 		,
    value_text			,
	user_name
    )
    VALUES (
    (SELECT nextval('feature_property_id_seq')),
	(SELECT currval('feature_base_id_seq')),
    _diameter_property_id,
    NEW.diameter,
	_username
    );
	

RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.valve_property_inserter()
    OWNER TO doadmin;
-- END VALVE PROPERTY INSERTER

-- START VALVE PROPERTY UPDATER
CREATE OR REPLACE FUNCTION public.valve_property_updater()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
	_feature_id INTEGER;
	_brand_property_id INTEGER;
	_model_property_id INTEGER;
	_contractor_property_id INTEGER;
	_diameter_property_id INTEGER;
	_username TEXT;

BEGIN
--set variables
	_feature_id = OLD.feature_id;
	_brand_property_id = (SELECT id FROM property WHERE name = 'brand');
	_model_property_id = (SELECT id FROM property WHERE name = 'model');
	_contractor_property_id = (SELECT id FROM property WHERE name = 'contractor');
	_diameter_property_id = (SELECT id FROM property WHERE name = 'diameter');
	_username = (SELECT user_community.user_name FROM user_community, system WHERE NEW.system_id = system.id AND system.community_id = user_community.community_id);

--update brand
UPDATE feature_property
	SET value_text = NEW.brand
	WHERE feature_id = _feature_id AND property_id = _brand_property_id;
	
--update model
UPDATE feature_property
	SET value_text = NEW.model
	WHERE feature_id = _feature_id AND property_id = _model_property_id;
	
--update contractor
UPDATE feature_property
	SET value_text = NEW.contractor
	WHERE feature_id = _feature_id AND property_id = _contractor_property_id;
	
--update diameter
UPDATE feature_property
	SET value_text = NEW.diameter
	WHERE feature_id = _feature_id AND property_id = _diameter_property_id;

--update username for entries
UPDATE feature_property
	SET user_name = _username
	WHERE feature_id = _feature_id;
	
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.valve_property_updater()
    OWNER TO doadmin;
-- END VALVE PROPERTY UPDATER

-- capital_project community assigner
CREATE or replace FUNCTION public.capital_project_community_assigner()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
BEGIN
		NEW.community_id := (SELECT community_id FROM user_community WHERE user_name = current_user);

RETURN NEW;

END;
$BODY$;

ALTER FUNCTION public.capital_project_community_assigner()
    OWNER TO doadmin;
	
-- capital_project_feature_combination community assigner
CREATE or replace FUNCTION public.capital_project_feature_combination_community_assigner()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
BEGIN
		NEW.community_id := (SELECT community_id FROM user_community WHERE user_name = current_user);

RETURN NEW;

END;
$BODY$;

ALTER FUNCTION public.capital_project_feature_combination_community_assigner()
    OWNER TO doadmin;