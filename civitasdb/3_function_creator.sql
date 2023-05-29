-- -- DROP FUNCTIONS -- --
DROP FUNCTION IF EXISTS public.function_remaining_years_to_pof;
DROP FUNCTION IF EXISTS public.function_remaining_years;
DROP FUNCTION IF EXISTS public.function_condition_to_life_fraction;

-- -- CREATE FUNCTIONS -- -- 
CREATE OR REPLACE FUNCTION public.function_condition_to_life_fraction (condition_value numeric, deterioration_id INTEGER)
	RETURNS NUMERIC (3,2)
	LANGUAGE PLPGSQL
	AS
	$$
	DECLARE
		evaluated NUMERIC (3,2);
	
	BEGIN
		IF deterioration_id = 1 THEN
			evaluated = ((-1.00 / 4.00) * condition_value) + (5.00 / 4.00);
		
		ELSEIF deterioration_id = 2 THEN
			evaluated = (1.00 - (1.00/16.0) * (condition_value - 1.00) ^ 2.00);
			
		ELSEIF deterioration_id = 3 THEN
			evaluated = (1.00 - (1.00/64.0) * (condition_value - 1.00) ^ 3.00);
			
		END IF;
	RETURN evaluated;
	END;
	$$;

ALTER FUNCTION public.function_condition_to_life_fraction(numeric, integer)
    OWNER TO doadmin
;

CREATE OR REPLACE FUNCTION public.function_remaining_years (condition_value numeric, deterioration_id INTEGER, age_value INTEGER, lifespan_value INTEGER, method_text TEXT, inspection_date DATE)
	RETURNS NUMERIC(3,0)
	LANGUAGE PLPGSQL
	AS
	$$
	DECLARE
		years_remaining NUMERIC;
		life_fraction NUMERIC := public.function_condition_to_life_fraction(condition_value, deterioration_id);
		
	BEGIN
		IF method_text = 'age based' THEN
		years_remaining = lifespan_value - age_value;
	
		ELSEIF method_text = 'condition based' THEN
		years_remaining = (life_fraction * lifespan_value) + DATE_PART('year', inspection_date) - DATE_PART('year', CURRENT_DATE);
		
		END IF;
	RETURN years_remaining::NUMERIC(7,0);
	END;
	$$;
	
ALTER FUNCTION public.function_remaining_years(numeric, integer, integer, integer, text, date)
    OWNER TO doadmin
;

CREATE OR REPLACE FUNCTION public.function_remaining_years_to_pof (years_remaining NUMERIC)
	RETURNS INTEGER
	LANGUAGE PLPGSQL
	AS
	$$
	DECLARE
		pof INTEGER;
		
	BEGIN
		IF years_remaining <= 0 THEN pof = 5;
		ELSEIF years_remaining > 0 AND years_remaining <= 5 THEN pof = 4;
		ELSEIF years_remaining > 5 AND years_remaining <= 15 THEN pof = 3;
		ELSEIF years_remaining > 15 AND years_remaining <= 30 THEN pof = 2;
		ELSEIF years_remaining > 30 THEN pof = 1;
		END IF;
	RETURN pof;
	END;
	$$;

ALTER FUNCTION public.function_remaining_years_to_pof (NUMERIC)
	OWNER TO doadmin
;

