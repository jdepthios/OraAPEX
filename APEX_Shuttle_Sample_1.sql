---------------------------------------------------------------------------------------
-- SOURCE https://explorer.uk.com/accessing-values-from-the-left-hand-side-of-an-apex-shuttle/
---------------------------------------------------------------------------------------


-- 1) items für Shuttle erstellen P516_SINT_INTW_SHUTTLE
-- Type : shuttle
-- List of values type: Shared Component, LOV in Shared Component muss vorher erstellt werden (LOV_INTERVIEWERS_INT)
-- Source Type null

--2) ein Prozess erstellen Type PL/SQL, Point: After Header
DECLARE
    lv_right VARCHAR2 (32767) DEFAULT NULL;
    lv_left VARCHAR2 (32767) DEFAULT NULL;
    v_count number;

BEGIN
    select count (*)
    into   v_count
    from   SCREENING_INTERVIEWERS
    where  sint_scrn_id = :P516_SCRN_ID;

    IF v_count < 1 THEN
        NULL;
    ELSE

    -- get the shuttle Right hand Side
    SELECT LISTAGG(SINT_INTW_ID, ':') WITHIN GROUP (ORDER BY SINT_INTW_ID) disp
    INTO   :P516_SINT_INTW_SHUTTLE
    FROM SCREENING_INTERVIEWERS
    WHERE SINT_SCRN_ID = :P516_SCRN_ID
    GROUP BY SINT_SCRN_ID ;

    lv_right := :P516_SINT_INTW_SHUTTLE;

    -- get the shuttle left hand side
    SELECT RTRIM (xmlagg(xmlelement (c, option_value ||':')).extract ('//text()'),':') AS left_side
    INTO   lv_left
    FROM   (SELECT extractvalue(column_value,'option/@value') as option_value
            FROM TABLE (xmlsequence(extract(xmltype(apex_item.select_list_from_lov(1, NULL, 'LOV_INTERVIEWERS_INT')),'/select/option')))f1
           MINUS
            SELECT token
            FROM (SELECT TRIM (substr (txt,
                                       instr(txt, ':', 1, LEVEL) + 1,
                                       instr(txt, ':', 1, LEVEL + 1) -
                                       instr(txt, ':', 1, LEVEL) - 1)) AS token
                               FROM (SELECT ':' || lv_right || ':' txt FROM DUAL)
                               CONNECT BY LEVEL <= length (lv_right) -
                                        length (REPLACE (lv_right, ':', '')) +1))
                               WHERE option_value <>'%null%';

     END IF;
END;

-- to save
DECLARE
  l_multiple_intw             apex_application_global.vc_arr2;

BEGIN
  l_multiple_intw := apex_util.string_to_table (:P516_SINT_INTW_SHUTTLE);

        For i in 1..l_multiple_intw.count loop
          insert into SCREENING_INTERVIEWER_ASSIGNED (SINT_INTW_ID , SINT_SCRN_ID )
          values ( l_multiple_intw(i), l_scrn_id);

        end loop;
END;
