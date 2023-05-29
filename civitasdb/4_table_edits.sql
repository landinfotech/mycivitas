-- Misc table edits. This might be useful is an older version of the DB is used.

-- TABLE COMMUNITY RLS POLICY UPDATE
DROP POLICY IF EXISTS community_rls_technician ON community;
CREATE POLICY community_rls_technician ON community
 	FOR SELECT
	USING ((community.id = (SELECT user_community.community_id FROM user_community WHERE current_user = user_name)) 
		   OR (current_user = 'reader'));
		   
ALTER TABLE system ENABLE ROW LEVEL SECURITY;	

-- TABLE SYSTEM RLS POLICY UPDATE
CREATE POLICY community_rls_technician ON community
 	FOR SELECT
	USING ((community.id = (SELECT user_community.community_id FROM user_community WHERE current_user = user_name)) 
		   OR (current_user = 'reader'));
		   
ALTER TABLE system ENABLE ROW LEVEL SECURITY;

-- TABLE FEATURE BASE UPDATE
ALTER TABLE feature_base ADD COLUMN inspection_date DATE;
ALTER TABLE feature_base RENAME COLUMN structure_id TO parent_feature_id;

-- Add polic to capital_plan TABLE
CREATE POLICY capital_project_rls
    ON public.capital_project
    AS PERMISSIVE
    FOR ALL
    TO public
    USING (community_id = ( SELECT user_community.community_id
   FROM user_community
  WHERE (CURRENT_USER = user_community.user_name)))
  
-- Add trigger to capital_plan TABLE
CREATE TRIGGER capital_project_insert
    BEFORE INSERT
    ON public.capital_project
    FOR EACH ROW
    EXECUTE FUNCTION public.capital_project_community_assigner();
 
 -- Add trigger to capital_project_feature_combination TABLE
 CREATE TRIGGER capital_project_feature_combination_insert
    BEFORE INSERT
    ON public.capital_project_feature_combination
    FOR EACH ROW
    EXECUTE FUNCTION public.capital_project_feature_combination_community_assigner();

-- RLS for capital_project_feature_combination
CREATE POLICY capital_project_feature_combination_rls
	ON public.capital_project_feature_combination
	FOR ALL
	USING (community_id = ( SELECT user_community.community_id
   FROM user_community
  WHERE (CURRENT_USER = user_community.user_name)))