-- validation cndt name unique

DECLARE
   v_cnt number;

BEGIN
    SELECT count(*)
    into   v_cnt
    FROM   CANDIDATES
    WHERE  lower(trim(CNDT_FIRST_NAME)) =  lower(trim(:P301_CNDT_FIRST_NAME))
    AND    lower(trim(CNDT_LAST_NAME))  =  lower(trim(:P301_CNDT_LAST_NAME))
    ;

    if v_cnt > 0
        then return false;
        else return true;
    end if;

END;
