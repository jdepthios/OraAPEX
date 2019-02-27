create or replace PACKAGE BODY PKG_CANDIDATE_RECRUITMENTS

AS

PROCEDURE PRC_CANDIDATE_SCREENINGS (
-- ----------------------------------------------------------------------------------------------
-- Description  : INSERT and UPDATE CANDIDATE_SCREENINGS (GENERAL, REJECTION,PASSED)
-- Last Modified: 28.01.2019
-- -----------------------------------------------------------------------------------------------
  P_SCRN_ID                     IN CANDIDATE_SCREENINGS.SCRN_ID%TYPE
, P_SCRN_CRES_ID                IN CANDIDATE_SCREENINGS.SCRN_CRES_ID%TYPE
, P_SCRN_STGS_ID                IN CANDIDATE_SCREENINGS.SCRN_STGS_ID%TYPE
, P_SCRN_DATE                   IN CANDIDATE_SCREENINGS.SCRN_DATE%TYPE
, P_SCRN_INTW_DATE              IN CANDIDATE_SCREENINGS.SCRN_INTW_DATE%TYPE
, P_SCRN_INTW_LOCATION          IN CANDIDATE_SCREENINGS.SCRN_INTW_LOCATION%TYPE
, P_SCRN_NOTES                  IN CANDIDATE_SCREENINGS.SCRN_NOTES%TYPE
, P_SCRN_FEEDBACK_DATE          IN CANDIDATE_SCREENINGS.SCRN_FEEDBACK_DATE%TYPE
, P_SCRN_FEEDBACK_NOTES         IN CANDIDATE_SCREENINGS.SCRN_FEEDBACK_NOTES%TYPE
, P_SCRN_CREATED_USER           IN CANDIDATE_SCREENINGS.SCRN_CREATED_USER%TYPE
, P_CREQ_ID                     IN CUSTOMER_REQUESTS.CREQ_ID%TYPE
, P_CRES_CNRL_ID                IN CANDIDATE_FOR_SCREENINGS.CRES_CNRL_ID%TYPE
, P_MULTI_INTW                  VARCHAR2

)
AS
    v_cnt_scrn                  number;
    l_scrn_id                   CANDIDATE_SCREENINGS.SCRN_ID%TYPE;
    l_schk_id                   CANDIDATE_SECURITY_CHECKS.SCHK_ID%TYPE;
    l_onbr_id                   CANDIDATE_ONBOARDINGS.ONBR_ID%TYPE;
    l_multiple_intw             apex_application_global.vc_arr2;
    l_intw_id                   number;
    l_creq_proc_id_cur          CUSTOMER_REQUESTS.CREQ_PROC_ID%TYPE;
BEGIN
    -- check record
    SELECT COUNT (*)
    INTO   v_cnt_scrn
    FROM   CANDIDATE_SCREENINGS
    WHERE  SCRN_ID = P_SCRN_ID;
    -- get current status of customer_requests
    SELECT creq_proc_id
    INTO   l_creq_proc_id_cur
    FROM   CUSTOMER_REQUESTS
    WHERE  CREQ_ID = P_CREQ_ID;

    IF v_cnt_scrn > 0 THEN -- PROCESS UPDATE LOGIC

        BEGIN
           -- BEGIN UPDATE
           UPDATE CANDIDATE_SCREENINGS SET
                  SCRN_DATE                = P_SCRN_DATE
                  , SCRN_INTW_DATE           = P_SCRN_INTW_DATE
                  , SCRN_INTW_LOCATION       = P_SCRN_INTW_LOCATION
                  , SCRN_NOTES               = P_SCRN_NOTES
                  , SCRN_FEEDBACK_DATE       = P_SCRN_FEEDBACK_DATE
                  , SCRN_FEEDBACK_NOTES      = P_SCRN_FEEDBACK_NOTES
                  , SCRN_LAST_MODIFIED_USER  = P_SCRN_CREATED_USER
                  , SCRN_LAST_MODIFIED_DATE  = SYSDATE
           WHERE SCRN_ID = P_SCRN_ID;

            -- CANDIDATE_INTERVIEWER ASSIGNED (SHUTTLE ITEM)
            -- delete what we have from this screening interview
            delete from SCREENING_INTERVIEWER_ASSIGNED where SINT_SCRN_ID = P_SCRN_ID;
            -- convert the shuttle values into a table
            l_multiple_intw := apex_util.string_to_table (P_MULTI_INTW);
            -- loop for every row in shuttle and determine if its a number from the LOV
            -- or a string from the previously filled right hand side of the shuttle
            FOR i in 1..l_multiple_intw.count loop
                BEGIN
                    -- try to convert to a number, throws error below for strings
                    l_intw_id := to_number(l_multiple_intw(i));
                    -- we catch the error specifically and resolve the name to an id
                    exception when VALUE_ERROR then
                           select SINT_INTW_ID
                           into   l_intw_id
                           from   V_SCREENING_INTERVW_ASSIGNED
                           where  INTW_FULLNAME = l_multiple_intw(i);
                           when others then raise;
                 END;
             -- insert new interviewers for screening
             insert into SCREENING_INTERVIEWER_ASSIGNED (SINT_INTW_ID , SINT_SCRN_ID )
             values ( l_multiple_intw(i), P_SCRN_ID);
             commit;
             --
             end loop;
            --
            EXCEPTION
            WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20101, 'ERROR UPDATE SCREENING'||SQLCODE||' -ERROR- '||SQLERRM);
            END; -- END UPDATE
            --
    ELSE -- PROCESS INSERT LOGIC

        BEGIN -- INSERT NEW SCRN_ID
            -- get new ID
            l_scrn_id := pkg_configuration.get_next_id('CANDIDATE_SCREENINGS');
            -- 1) Insert into candidate_screenings
            INSERT INTO CANDIDATE_SCREENINGS(
                  SCRN_ID
                , SCRN_CRES_ID
                , SCRN_STGS_ID
                , SCRN_DATE
                , SCRN_INTW_DATE
                , SCRN_INTW_LOCATION
                , SCRN_NOTES
                , SCRN_FEEDBACK_DATE
                , SCRN_FEEDBACK_NOTES
                , SCRN_CREATED_USER
                , SCRN_CREATED_DATE
                , SCRN_LAST_MODIFIED_USER
                , SCRN_LAST_MODIFIED_DATE)
                VALUES(
                  l_scrn_id
                , P_SCRN_CRES_ID
                , P_SCRN_STGS_ID
                , P_SCRN_DATE
                , P_SCRN_INTW_DATE
                , P_SCRN_INTW_LOCATION
                , P_SCRN_NOTES
                , P_SCRN_FEEDBACK_DATE
                , P_SCRN_FEEDBACK_NOTES
                , P_SCRN_CREATED_USER
                , SYSDATE
                , P_SCRN_CREATED_USER
                , SYSDATE);
            --set new id
            pkg_configuration.set_next_id('CANDIDATE_SCREENINGS');

            BEGIN -- INTERVIEWER
                IF P_MULTI_INTW is null then
                      NULL;
                ELSE
                    l_multiple_intw := apex_util.string_to_table (P_MULTI_INTW);
                    For i in 1..l_multiple_intw.count loop
                        insert into SCREENING_INTERVIEWER_ASSIGNED (SINT_INTW_ID , SINT_SCRN_ID )
                        values ( l_multiple_intw(i), l_scrn_id);
                    end loop;
                END IF;
                EXCEPTION
                WHEN OTHERS THEN
                raise_application_error(-20101,'ERROR IN INSERT SCREENING_INTERVIEWER_ASSIGNED - '||SQLCODE||' -ERROR- '||SQLERRM);
            END; -- INTERVIEWER

            -- SCREENINGS STAGES
            IF P_SCRN_STGS_ID IN (10,11,12) THEN

                BEGIN --ABSAGE
                    -- update CANDIDATE_FOR_SCREENING STATUS CRES_STGS_ID = 4 (Absage in SCRN)
                    UPDATE CANDIDATE_FOR_SCREENINGS SET
                       CRES_STGS_ID = 4	--Absage in Screening
                     , CRES_LAST_MODIFIED_USER = P_SCRN_CREATED_USER
                     , CRES_LAST_MODIFIED_DATE = SYSDATE
                    WHERE CRES_ID      = P_SCRN_CRES_ID
                    AND   CRES_CNRL_ID = P_CRES_CNRL_ID;
                    -- update CANDIDATE_ROLES, Status CNRL_CNST_ID = 5 (Rolle Abgesagt)
                    UPDATE CANDIDATE_ROLES SET
                           CNRL_CNST_ID = 5	--Abgesagt
                         , CNRL_LAST_MODIFIED_USER = P_SCRN_CREATED_USER
                         , CNRL_LAST_MODIFIED_DATE = SYSDATE
                    WHERE  CNRL_ID = P_CRES_CNRL_ID;
                EXCEPTION
                    WHEN OTHERS THEN
                    RAISE_APPLICATION_ERROR(-20102, 'ERROR SCREENING STAGES ABSAGE'||SQLCODE||' -ERROR- '||SQLERRM);
                END; -- ABSAGE
            --
            ELSIF P_SCRN_STGS_ID IN (13) THEN

                BEGIN -- Screening Bestanden --> SÜ
                    -- get new primary key for CANDIDATE_SECURITY_CHECKS
                    l_schk_id := pkg_configuration.get_next_id('CANDIDATE_SECURITY_CHECKS');
                    -- Insert into CANDIDATE_SECURITY_CHECKS
                    INSERT INTO CANDIDATE_SECURITY_CHECKS (
                        SCHK_ID
                      , SCHK_CRES_ID
                      , SCHK_DATE
                      , SCHK_STGS_ID
                      , SCHK_CREATED_USER
                      , SCHK_CREATED_DATE
                      , SCHK_LAST_MODIFIED_USER
                      , SCHK_LAST_MODIFIED_DATE )
                     VALUES(
                        l_schk_id
                      , P_SCRN_CRES_ID
                      , SYSDATE
                      , 1 -- Screening bestanden --> SÜ im Lauf
                      , P_SCRN_CREATED_USER
                      , SYSDATE
                      , P_SCRN_CREATED_USER
                      , SYSDATE);
                    -- set new CANDIDATE_SECURITY_CHECKS ID in sequence table
                    pkg_configuration.set_next_id('CANDIDATE_SECURITY_CHECKS');

                -- update CANDIDATE Recuritment status
                UPDATE CANDIDATE_FOR_SCREENINGS SET
                    CRES_STGS_ID = 3 -- Kandidat in Sicherheitsüberprüfung befindet
                  , CRES_LAST_MODIFIED_USER = P_SCRN_CREATED_USER
                  , CRES_LAST_MODIFIED_DATE = SYSDATE
                WHERE CRES_ID      = P_SCRN_CRES_ID
                AND   CRES_CNRL_ID = P_CRES_CNRL_ID;
                -- UPDATE CUSTOMER_REQUESTS
                IF l_creq_proc_id_cur in (1,2,3) then
                    UPDATE CUSTOMER_REQUESTS SET
                        CREQ_PROC_ID = 4 -- Sicherheitsüberprüfung im Lauf
                      , CREQ_LAST_MODIFIED_USER = P_SCRN_CREATED_USER
                      , CREQ_LAST_MODIFIED_DATE = SYSDATE
                    WHERE CREQ_ID = P_CREQ_ID;
                END IF;
            --
            EXCEPTION
                WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR(-20103, 'ERROR SCREENING STAGES SCREENING -> SÜ'||SQLCODE||' -ERROR- '||SQLERRM);
            END;-- Screening Bestanden --> SÜ
            --
            ELSIF P_SCRN_STGS_ID IN (14) THEN

                BEGIN-- Screening Bestanden --> Onboarding
                    -- get new primary key for CANDIDATE_ONBOARDINGS
                    l_onbr_id := pkg_configuration.get_next_id('CANDIDATE_ONBOARDINGS');
                    -- INSERT INTO CANDIDATE_ONBOARDINGS
                    INSERT INTO CANDIDATE_ONBOARDINGS (
                            ONBR_ID
                          , ONBR_DATE
                          , ONBR_CREATED_USER
                          , ONBR_CREATED_DATE
                          , ONBR_LAST_MODIFIED_USER
                          , ONBR_LAST_MODIFIED_DATE
                          , ONBR_STGS_ID
                          , ONBR_CRES_ID)
                        VALUES (
                            l_onbr_id
                          , SYSDATE
                          , P_SCRN_CREATED_USER
                          , SYSDATE
                          , P_SCRN_CREATED_USER
                          , SYSDATE
                          , 1 --Alle Prüfungen bestanden - Onboarding
                          , P_SCRN_CRES_ID
                          );
                    --SET new ID for CANDIDATE_ONBOARDINGS in sequence table
                    pkg_configuration.set_next_id('CANDIDATE_ONBOARDINGS');
                    --UPDATE STATUS CANDIDATE_FOR_SCREENINGS
                    UPDATE CANDIDATE_FOR_SCREENINGS SET
                        CRES_STGS_ID = 5 -- Akzeptiert (Onboarding)
                      , CRES_LAST_MODIFIED_USER = P_SCRN_CREATED_USER
                      , CRES_LAST_MODIFIED_DATE = SYSDATE
                    WHERE CRES_ID      = P_SCRN_CRES_ID
                    AND   CRES_CNRL_ID = P_CRES_CNRL_ID;
                    -- UPDATE STATUS CUSTOMER_REQUESTS
                    IF l_creq_proc_id_cur in (1,2,3,4) THEN
                        UPDATE CUSTOMER_REQUESTS SET
                            CREQ_PROC_ID = 5 -- Vertragsabschluss und Onboarding
                          , CREQ_LAST_MODIFIED_USER = P_SCRN_CREATED_USER
                          , CREQ_LAST_MODIFIED_DATE = SYSDATE
                        WHERE CREQ_ID = P_CREQ_ID;
                    END IF;
                    EXCEPTION
                        WHEN OTHERS THEN
                        RAISE_APPLICATION_ERROR(-20104, 'ERROR IN STAGES SCREENING -> ONBOARDING'||SQLCODE||' -ERROR- '||SQLERRM);
                END;-- Screening Bestanden --> Onboarding
            --
            ELSE
                BEGIN -- OTHER SCRN_STGS_ID (Internal and External Fortschritte)
                   -- update CANDIDATE_FOR_SCREENING STATUS
                    UPDATE CANDIDATE_FOR_SCREENINGS SET
                        CRES_STGS_ID            = 2	--Im Screeningsprozess
                      , CRES_LAST_MODIFIED_USER = P_SCRN_CREATED_USER
                      , CRES_LAST_MODIFIED_DATE = SYSDATE
                    WHERE CRES_ID      = P_SCRN_CRES_ID
                    AND   CRES_CNRL_ID = P_CRES_CNRL_ID;

                    IF l_creq_proc_id_cur in (1,2) THEN
                        UPDATE CUSTOMER_REQUESTS SET
                            CREQ_PROC_ID            = 3--	Kandidatenüberprüfung im Lauf
                          , CREQ_LAST_MODIFIED_DATE = SYSDATE
                          , CREQ_LAST_MODIFIED_USER = P_SCRN_CREATED_USER
                        WHERE CREQ_ID = P_CREQ_ID; -- Request ID
                    END IF;
                    EXCEPTION
                        WHEN OTHERS THEN
                        RAISE_APPLICATION_ERROR(-20105, 'ERROR SCREENING OTHER STAGES SCREENING'||SQLCODE||' -ERROR- '||SQLERRM);
                END; -- OTHER SCRN_STGS_ID (Internal and External Fortschritte)
            --
            END IF; -- END IF SCREENING STAGES

            EXCEPTION
            WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20106, 'ERROR INSERT SCREENING'||SQLCODE||' -ERROR- '||SQLERRM);

        END; -- END SCRN

    END IF; -- END FROM IF v_cnt_scrn > 0


EXCEPTION
WHEN OTHERS THEN
raise_application_error(-20107,'Fehler bei Speicherung der Screening Fortschritt - '||SQLCODE||' -ERROR- '||SQLERRM);

END; -- end of PRC_INSERT_CNDT_SCREENINGS

PROCEDURE PRC_INSERT_CNDT_FOR_SCREENINGS (
  P_CRES_CINQ_ID                IN CANDIDATE_FOR_SCREENINGS.CRES_CINQ_ID%TYPE
, P_CRES_CREQ_ID                IN CANDIDATE_FOR_SCREENINGS.CRES_CREQ_ID%TYPE
, P_CRES_CNRL_ID                IN CANDIDATE_FOR_SCREENINGS.CRES_CNRL_ID%TYPE
, P_CRES_CREATED_USER           IN CANDIDATE_FOR_SCREENINGS.CRES_CREATED_USER%TYPE

)
AS
    l_cres_id                     CANDIDATE_FOR_SCREENINGS.CRES_ID%TYPE;
    l_scrn_id                     CANDIDATE_SCREENINGS.SCRN_ID%TYPE;
BEGIN
     -- get new primary key
     l_cres_id := pkg_configuration.get_next_id('CANDIDATE_FOR_SCREENINGS');
     l_scrn_id := pkg_configuration.get_next_id('CANDIDATE_SCREENINGS');
     -- 1) insert into candidate_for_screenings
     INSERT INTO CANDIDATE_FOR_SCREENINGS
        (CRES_ID
        ,CRES_CNRL_ID
        ,CRES_CREATED_USER          
        ,CRES_CREATED_DATE
        ,CRES_LAST_MODIFIED_USER
        ,CRES_LAST_MODIFIED_DATE
        ,CRES_CINQ_ID
        ,CRES_STGS_ID
        ,CRES_CREQ_ID)
        VALUES(
        l_cres_id
        ,P_CRES_CNRL_ID
        ,P_CRES_CREATED_USER
        ,SYSDATE
        ,P_CRES_CREATED_USER
        ,SYSDATE
        ,P_CRES_CINQ_ID
        ,1  --Kandidat zum Screening freigegeben
        ,P_CRES_CREQ_ID);

     -- 2) insert into candidate_screenings
     INSERT INTO CANDIDATE_SCREENINGS (
         SCRN_ID
        ,SCRN_CRES_ID
        ,SCRN_STGS_ID
        ,SCRN_DATE
        ,SCRN_CREATED_USER
        ,SCRN_CREATED_DATE
        ,SCRN_LAST_MODIFIED_USER
        ,SCRN_LAST_MODIFIED_DATE)
        VALUES (
         l_scrn_id
        ,l_cres_id
        ,1 -- Screening noch nicht gestartet
        ,sysdate
        ,P_CRES_CREATED_USER
        ,sysdate
        ,P_CRES_CREATED_USER
        ,sysdate);

     -- 3) update ROLE STATUS from candidate
     update CANDIDATE_ROLES
     SET    CNRL_CNST_ID = 1 -- in RECRUITMENT
          , CNRL_LAST_MODIFIED_USER = P_CRES_CREATED_USER
          , CNRL_LAST_MODIFIED_DATE = SYSDATE
     WHERE CNRL_ID = P_CRES_CNRL_ID;

     --set next ID for CRES_ID to sequence table
     pkg_configuration.set_next_id('CANDIDATE_FOR_SCREENINGS');
     pkg_configuration.set_next_id('CANDIDATE_SCREENINGS');

     EXCEPTION
     WHEN OTHERS THEN
        raise_application_error(-20001,'Fehler bei Zuweisung der Kandidat zur Screening - '||SQLCODE||' -ERROR- '||SQLERRM);
END;

PROCEDURE PRC_INSERT_CNDT_SCREENINGS (
-- ----------------------------------------------------------------------------------------------
-- 1) insert into CANDIDATE_SCREENINGS
-- 2) update table CANDIDATE_FOR_SCREENINGS, CANDIDATE_ROLES, CUSTOMER_REQUESTS
-- 2.1) IF l_scrn_stgs_id in (10,11,12) Absage
-- 2.2) IF l_scrn_stgs_id = 13 (Screening bestanden --> SÜ), insert into CANDIDATE_SECURITY_CHECKS
-- 2.3) IF l_scrn_stgs_id = 14 (Screening bestanden --> Onboardings), insert into CANDIDATE_ONBOARDING
-- ----------------------------------------------------------------------------------------------
  P_SCRN_CRES_ID                IN CANDIDATE_SCREENINGS.SCRN_CRES_ID%TYPE
, P_SCRN_ID                     IN CANDIDATE_SCREENINGS.SCRN_ID%TYPE
, P_SCRN_STGS_ID                IN CANDIDATE_SCREENINGS.SCRN_STGS_ID%TYPE
, P_SCRN_DATE                   IN CANDIDATE_SCREENINGS.SCRN_DATE%TYPE
, P_SCRN_INTW_DATE              IN CANDIDATE_SCREENINGS.SCRN_INTW_DATE%TYPE
, P_SCRN_INTW_LOCATION          IN CANDIDATE_SCREENINGS.SCRN_INTW_LOCATION%TYPE
, P_SCRN_NOTES                  IN CANDIDATE_SCREENINGS.SCRN_NOTES%TYPE
, P_SCRN_FEEDBACK_DATE          IN CANDIDATE_SCREENINGS.SCRN_FEEDBACK_DATE%TYPE
, P_SCRN_FEEDBACK_NOTES         IN CANDIDATE_SCREENINGS.SCRN_FEEDBACK_NOTES%TYPE
, P_SCRN_CREATED_USER           IN CANDIDATE_SCREENINGS.SCRN_CREATED_USER%TYPE
, P_CREQ_ID                     IN CUSTOMER_REQUESTS.CREQ_ID%TYPE
, P_MULTI_INTW                  VARCHAR2
)
AS
    l_scrn_id                   CANDIDATE_SCREENINGS.SCRN_ID%TYPE;
    l_scrn_stgs_id              CANDIDATE_SCREENINGS.SCRN_STGS_ID%TYPE;
    l_creq_proc_id_cur          CUSTOMER_REQUESTS.CREQ_PROC_ID%TYPE;
    l_cnrl_id                   CANDIDATE_ROLES.CNRL_ID%TYPE;
    l_schk_id                   CANDIDATE_SECURITY_CHECKS.SCHK_ID%TYPE;
    l_onbr_id                   CANDIDATE_ONBOARDINGS.ONBR_ID%TYPE;
    v_count                     number;
    l_multiple_intw             apex_application_global.vc_arr2;
BEGIN
    -- get stages ID
    l_scrn_stgs_id := P_SCRN_STGS_ID;

    -- get new primary key
    select count (*) into v_count FROM CANDIDATE_SCREENINGS where SCRN_ID = P_SCRN_ID;
    IF v_count < 1 then
       l_scrn_id := pkg_configuration.get_next_id('CANDIDATE_SCREENINGS');
    END IF;

    -- get current CREQ_PROC_ID to update customer_requests process only when current process status not older then new proc_id
    SELECT creq_proc_id
    INTO   l_creq_proc_id_cur
    FROM   CUSTOMER_REQUESTS
    WHERE  CREQ_ID = P_CREQ_ID;

    -- get CANDIDATE_ROLE info
    SELECT CRES_CNRL_ID
    INTO   l_cnrl_id
    FROM   CANDIDATE_FOR_SCREENINGS
    WHERE  CRES_ID = P_SCRN_CRES_ID;

    -- 1) Insert into candidate_screenings
    INSERT INTO CANDIDATE_SCREENINGS(
          SCRN_ID
        , SCRN_CRES_ID
        , SCRN_STGS_ID
        , SCRN_DATE
        --, SCRN_INTW_ID
        , SCRN_INTW_DATE
        , SCRN_INTW_LOCATION
        , SCRN_NOTES
        , SCRN_FEEDBACK_DATE
        , SCRN_FEEDBACK_NOTES
        , SCRN_CREATED_USER
        , SCRN_CREATED_DATE
        , SCRN_LAST_MODIFIED_USER
        , SCRN_LAST_MODIFIED_DATE)
    VALUES(
          l_scrn_id
        , P_SCRN_CRES_ID
        , l_scrn_stgs_id
        , P_SCRN_DATE
        --, P_SCRN_INTW_ID
        , P_SCRN_INTW_DATE
        , P_SCRN_INTW_LOCATION
        , P_SCRN_NOTES
        , P_SCRN_FEEDBACK_DATE
        , P_SCRN_FEEDBACK_NOTES
        , P_SCRN_CREATED_USER
        , SYSDATE
        , P_SCRN_CREATED_USER
        , SYSDATE);

    -- set next ID for SCRN_ID to sequence table
    pkg_configuration.set_next_id('CANDIDATE_SCREENINGS');

    IF P_MULTI_INTW is null then
        NULL;
    ELSE
        l_multiple_intw := apex_util.string_to_table (P_MULTI_INTW);

        For i in 1..l_multiple_intw.count loop
          insert into SCREENING_INTERVIEWER_ASSIGNED (SINT_INTW_ID , SINT_SCRN_ID )
          values ( l_multiple_intw(i), l_scrn_id);

        end loop;
    END IF;

    -- 2.1) IF l_scrn_stgs_id in (10,11,12) -->  ABSAGE
    IF l_scrn_stgs_id in (10,11,12) THEN --
        -- update CANDIDATE_FOR_SCREENING STATUS CRES_STGS_ID = 4 (Absage in SCRN)
        UPDATE CANDIDATE_FOR_SCREENINGS SET
           CRES_STGS_ID = 4	--Absage in Screening
         , CRES_LAST_MODIFIED_USER = P_SCRN_CREATED_USER
         , CRES_LAST_MODIFIED_DATE = SYSDATE
        WHERE  CRES_ID = P_SCRN_CRES_ID;

        -- update CANDIDATE_ROLES, Status CNRL_CNST_ID = 5 (Rolle Abgesagt)
        UPDATE CANDIDATE_ROLES SET
               CNRL_CNST_ID = 5	--Abgesagt
             , CNRL_LAST_MODIFIED_USER = P_SCRN_CREATED_USER
             , CNRL_LAST_MODIFIED_DATE = SYSDATE
        WHERE  CNRL_ID = l_cnrl_id;

        -- update CUSTOMER_REQUESTS only when current status before "Kandidatenüberprüfung im Lauf"
            IF l_creq_proc_id_cur in (1,2) THEN
                update CUSTOMER_REQUESTS SET
                     CREQ_PROC_ID = 3--	Kandidatenüberprüfung im Lauf
                   , CREQ_LAST_MODIFIED_DATE = SYSDATE
                   , CREQ_LAST_MODIFIED_USER = P_SCRN_CREATED_USER
                WHERE CREQ_ID = P_CREQ_ID;
            END IF;   -- end if l_creq_proc_id_cur in (1,2)

    -- 2.2) IF l_scrn_stgs_id = 13 (Screening bestanden --> SÜ), insert into CANDIDATE_SECURITY_CHECKS
    ELSIF l_scrn_stgs_id in (13) THEN -- Screening Bestanden --> Sicherheitsüberprüfung
        -- get new primary key for CANDIDATE_SECURITY_CHECKS
        l_schk_id := pkg_configuration.get_next_id('CANDIDATE_SECURITY_CHECKS');

        -- Insert into CANDIDATE_SECURITY_CHECKS
        INSERT INTO CANDIDATE_SECURITY_CHECKS (
            SCHK_ID
          , SCHK_CRES_ID
          , SCHK_DATE
          , SCHK_STGS_ID
          , SCHK_CREATED_USER
          , SCHK_CREATED_DATE
          , SCHK_LAST_MODIFIED_USER
          , SCHK_LAST_MODIFIED_DATE
        )VALUES(
            l_schk_id
          , P_SCRN_CRES_ID
          , SYSDATE
          , 1 -- Screening bestanden --> SÜ im Lauf
          , P_SCRN_CREATED_USER
          , SYSDATE
          , P_SCRN_CREATED_USER
          , SYSDATE
        );
        -- set new CANDIDATE_SECURITY_CHECKS ID in sequence table
        pkg_configuration.set_next_id('CANDIDATE_SECURITY_CHECKS');

        -- update CANDIDATE Recuritment status
        UPDATE CANDIDATE_FOR_SCREENINGS SET
            CRES_STGS_ID = 3 -- Kandidat in Sicherheitsüberprüfung befindet
          , CRES_LAST_MODIFIED_USER = P_SCRN_CREATED_USER
          , CRES_LAST_MODIFIED_DATE = SYSDATE
        WHERE CRES_ID      = P_SCRN_CRES_ID
        AND   CRES_CNRL_ID = l_cnrl_id;

        -- update Request status ONLY if Request status before "Sicherheitsüberprüfung im Lauf"
        IF l_creq_proc_id_cur in (1,2,3) then
            UPDATE CUSTOMER_REQUESTS SET
                CREQ_PROC_ID = 4 -- Sicherheitsüberprüfung im Lauf
              , CREQ_LAST_MODIFIED_USER = P_SCRN_CREATED_USER
              , CREQ_LAST_MODIFIED_DATE = SYSDATE
            WHERE CREQ_ID = P_CREQ_ID;
        END IF;

    -- 2.3) IF l_scrn_stgs_id = 14 (Screening bestanden --> Onboardings), insert into CANDIDATE_ONBOARDING
    ELSIF l_scrn_stgs_id in (14) THEN -- Screening Bestanden --> Onboarding
        -- get new primary key for CANDIDATE_ONBOARDINGS
        l_onbr_id := pkg_configuration.get_next_id('CANDIDATE_ONBOARDINGS');
        -- INSERT INTO CANDIDATE_ONBOARDINGS
        INSERT INTO CANDIDATE_ONBOARDINGS (
            ONBR_ID
          , ONBR_DATE
          , ONBR_CREATED_USER
          , ONBR_CREATED_DATE
          , ONBR_LAST_MODIFIED_USER
          , ONBR_LAST_MODIFIED_DATE
          , ONBR_STGS_ID
          , ONBR_CRES_ID
        ) VALUES (
            l_onbr_id
          , SYSDATE
          , P_SCRN_CREATED_USER
          , SYSDATE
          , P_SCRN_CREATED_USER
          , SYSDATE
          , 1 --Alle Prüfungen bestanden - Onboarding
          , P_SCRN_CRES_ID
          );
        --SET new ID for CANDIDATE_ONBOARDINGS in sequence table
        pkg_configuration.set_next_id('CANDIDATE_ONBOARDINGS');

        --UPDATE STATUS CANDIDATE_FOR_SCREENINGS
        UPDATE CANDIDATE_FOR_SCREENINGS SET
            CRES_STGS_ID = 5 -- Akzeptiert (Onboarding)
          , CRES_LAST_MODIFIED_USER = P_SCRN_CREATED_USER
          , CRES_LAST_MODIFIED_DATE = SYSDATE
        WHERE CRES_ID      = P_SCRN_CRES_ID
        AND   CRES_CNRL_ID = l_cnrl_id;

    -- UPDATE STATUS CUSTOMER_REQUESTS
         IF l_creq_proc_id_cur in (1,2,3,4) THEN
            UPDATE CUSTOMER_REQUESTS SET
                CREQ_PROC_ID = 5 -- Vertragsabschluss und Onboarding
              , CREQ_LAST_MODIFIED_USER = P_SCRN_CREATED_USER
              , CREQ_LAST_MODIFIED_DATE = SYSDATE
            WHERE CREQ_ID = P_CREQ_ID;
         END IF;

    -- OTHER SCRN_STGS_ID (OTHER STGS_ID for Internal and External Fortschritte)
    ELSE
       -- update CANDIDATE_FOR_SCREENING STATUS
        UPDATE CANDIDATE_FOR_SCREENINGS SET
            CRES_STGS_ID            = 2	--Im Screeningsprozess
          , CRES_LAST_MODIFIED_USER = P_SCRN_CREATED_USER
          , CRES_LAST_MODIFIED_DATE = SYSDATE
        WHERE  CRES_ID = P_SCRN_CRES_ID;

        IF l_creq_proc_id_cur in (1,2) THEN
            UPDATE CUSTOMER_REQUESTS SET
                CREQ_PROC_ID            = 3--	Kandidatenüberprüfung im Lauf
              , CREQ_LAST_MODIFIED_DATE = SYSDATE
              , CREQ_LAST_MODIFIED_USER = P_SCRN_CREATED_USER
            WHERE CREQ_ID = P_CREQ_ID; -- Request ID
        END IF;

    END IF; -- END IF l_scrn_stgs_id

    EXCEPTION
      WHEN OTHERS THEN
      raise_application_error(-20001,'Fehler bei Speicherung der Screening Fortschritt - '||SQLCODE||' -ERROR- '||SQLERRM);

END; -- end of PRC_INSERT_CNDT_SCREENINGS

PROCEDURE PRC_UPDATE_CNDT_SCREENINGS (
  P_SCRN_ID                     IN CANDIDATE_SCREENINGS.SCRN_ID%TYPE
, P_SCRN_DATE                   IN CANDIDATE_SCREENINGS.SCRN_DATE%TYPE
--, P_SCRN_INTW_ID                IN CANDIDATE_SCREENINGS.SCRN_INTW_ID%TYPE
, P_SCRN_INTW_DATE              IN CANDIDATE_SCREENINGS.SCRN_INTW_DATE%TYPE
, P_SCRN_INTW_LOCATION          IN CANDIDATE_SCREENINGS.SCRN_INTW_LOCATION%TYPE
, P_SCRN_NOTES                  IN CANDIDATE_SCREENINGS.SCRN_NOTES%TYPE
, P_SCRN_FEEDBACK_DATE          IN CANDIDATE_SCREENINGS.SCRN_FEEDBACK_DATE%TYPE
, P_SCRN_FEEDBACK_NOTES         IN CANDIDATE_SCREENINGS.SCRN_FEEDBACK_NOTES%TYPE
, P_SCRN_CREATED_USER           IN CANDIDATE_SCREENINGS.SCRN_CREATED_USER%TYPE
, P_MULTI_INTW                  VARCHAR2
)AS
    v_scrn_count                number;
    l_multiple_intw             apex_application_global.vc_arr2;
    l_intw_id                   number;
    no_scrn_found               EXCEPTION;
BEGIN
    -- Check screening records
    SELECT count (*)
    INTO   v_scrn_count
    FROM   CANDIDATE_SCREENINGS
    WHERE  SCRN_ID = P_SCRN_ID;

    if v_scrn_count > 0  then
       UPDATE CANDIDATE_SCREENINGS SET
               SCRN_DATE                = P_SCRN_DATE
             --, SCRN_INTW_ID             = P_SCRN_INTW_ID
             , SCRN_INTW_DATE           = P_SCRN_INTW_DATE
             , SCRN_INTW_LOCATION       = P_SCRN_INTW_LOCATION
             , SCRN_NOTES               = P_SCRN_NOTES
             , SCRN_FEEDBACK_DATE       = P_SCRN_FEEDBACK_DATE
             , SCRN_FEEDBACK_NOTES      = P_SCRN_FEEDBACK_NOTES
             , SCRN_LAST_MODIFIED_USER  = P_SCRN_CREATED_USER
             , SCRN_LAST_MODIFIED_DATE  = SYSDATE
        WHERE SCRN_ID = P_SCRN_ID;

        -- delete what we have from this screening
        delete from SCREENING_INTERVIEWER_ASSIGNED where SINT_SCRN_ID = P_SCRN_ID;

        -- convert the shuttle values into a table
        l_multiple_intw := apex_util.string_to_table (P_MULTI_INTW);

        -- loop for every row in shuttle and determine if its a number from the LOV
        -- or a string from the previously filled right hand side of the shuttle
            FOR i in 1..l_multiple_intw.count loop
                BEGIN
                    -- try to convert to a number, throws error below for strings
                    l_intw_id := to_number(l_multiple_intw(i));
                    -- we catch the error specifically and resolve the name to an id
                    exception when VALUE_ERROR then
                        select SINT_INTW_ID
                        into   l_intw_id
                        from   V_SCREENING_INTERVW_ASSIGNED
                        where  INTW_FULLNAME = l_multiple_intw(i);
                    when others then
                        raise;
                END;

              -- Create new record for the interviewers
              insert into SCREENING_INTERVIEWER_ASSIGNED (SINT_INTW_ID , SINT_SCRN_ID )
              values ( l_multiple_intw(i), P_SCRN_ID);

            end loop;
            commit;
    END IF; -- v_scrn_count > 0

    EXCEPTION
      WHEN no_scrn_found THEN
        raise_application_error(-20001,'Keine Daten gefunden - '||SQLCODE||' -ERROR- '||SQLERRM);
      WHEN others THEN
        ROLLBACK;
        raise_application_error(-20002,'Fehler bei Aktualisierung der Screening Fortschritt - '||SQLCODE||' -ERROR- '||SQLERRM);

END; -- end of PRC_UPDATE_CNDT_SCREENINGS

PROCEDURE PRC_DELETE_CNDT_SCREENINGS (
  P_SCRN_ID                     IN CANDIDATE_SCREENINGS.SCRN_ID%TYPE
)AS
  v_scrn_count                NUMBER;
  v_sint_count                NUMBER;
  no_scrn_found               EXCEPTION;

BEGIN
    -- Check screening records
    SELECT count (*)
    INTO   v_scrn_count
    FROM   CANDIDATE_SCREENINGS
    WHERE  SCRN_ID = P_SCRN_ID;

    select count (*)
    into   v_sint_count
    FROM   SCREENING_INTERVIEWER_ASSIGNED
    WHERE  sint_scrn_id = P_SCRN_ID;

    IF v_sint_count > 0 then
        DELETE FROM SCREENING_INTERVIEWER_ASSIGNED WHERE  sint_scrn_id = P_SCRN_ID;
    ELSE NULL;
    END IF;

    IF  v_scrn_count > 0 THEN
        DELETE FROM CANDIDATE_SCREENINGS WHERE  SCRN_ID = P_SCRN_ID;
    ELSE NULL;
    END IF;

    EXCEPTION
      WHEN no_scrn_found THEN
        raise_application_error(-20001,'Keine Daten gefunden - '||SQLCODE||' -ERROR- '||SQLERRM);
      WHEN others THEN
        ROLLBACK;
        raise_application_error(-20002,'Fehler bei Löschung der Screening Fortschritt - '||SQLCODE||' -ERROR- '||SQLERRM);

END; -- end of PRC_DELETE_CNDT_SCREENINGS


/*PROCEDURE PRC_INSERT_CNDT_SECR_CHECKS
this procedure will proceed following actions
1) insert into CANDIDATE_SECURITY_CHECKS
2) update table CANDIDATE_FOR_SCREENINGS, CANDIDATE_ROLES, CUSTOMER_REQUESTS
2.1) IF l_schk_stgs_id in (6,8) 6 SÜ nicht bestanden - Absage, 8	Absage vom Kandidat
2.2) IF l_schk_stgs_id = 7 (7	SÜ bestanden - Vertrag/ Onboarding), insert into CANDIDATE_ONBOARDING
*/

PROCEDURE PRC_INSERT_CNDT_SECR_CHECKS (
-- ----------------------------------------------------------------------------------------------
--1) insert into CANDIDATE_SECURITY_CHECKS
--2) update table CANDIDATE_FOR_SCREENINGS, CANDIDATE_ROLES, CUSTOMER_REQUESTS
--2.1) IF l_schk_stgs_id in (6,8) 6 SÜ nicht bestanden - Absage, 8	Absage vom Kandidat
--2.2) IF l_schk_stgs_id = 7 (7	SÜ bestanden - Vertrag/ Onboarding), insert into CANDIDATE_ONBOARDING
-- ----------------------------------------------------------------------------------------------
  P_SCHK_CRES_ID                IN CANDIDATE_SECURITY_CHECKS.SCHK_CRES_ID%TYPE
, P_SCHK_DATE                   IN CANDIDATE_SECURITY_CHECKS.SCHK_DATE%TYPE
, P_SCHK_NOTES                  IN CANDIDATE_SECURITY_CHECKS.SCHK_NOTES%TYPE
, P_SCHK_STGS_ID                IN CANDIDATE_SECURITY_CHECKS.SCHK_STGS_ID%TYPE
, P_SCHK_CREATED_USER           IN CANDIDATE_SECURITY_CHECKS.SCHK_CREATED_USER%TYPE
, P_CREQ_ID                     IN CUSTOMER_REQUESTS.CREQ_ID%TYPE
, P_CNDT_SECURITY_CHECK_DATE    IN CANDIDATES.CNDT_SECURITY_CHECK_DATE%TYPE
)
AS
    l_schk_id                   CANDIDATE_SECURITY_CHECKS.SCHK_ID%TYPE;
    l_schk_stgs_id              CANDIDATE_SECURITY_CHECKS.SCHK_STGS_ID%TYPE;
    l_creq_proc_id_cur          CUSTOMER_REQUESTS.CREQ_PROC_ID%TYPE;
    l_cnrl_id                   CANDIDATE_ROLES.CNRL_ID%TYPE;
    l_onbr_id                   CANDIDATE_ONBOARDINGS.ONBR_ID%TYPE;

BEGIN
    -- get new ID
    l_schk_id := pkg_configuration.get_next_id('CANDIDATE_SECURITY_CHECKS');

    -- get Stages ID
    l_schk_stgs_id := P_SCHK_STGS_ID;

    --get candidate role ID
    SELECT CRES_CNRL_ID
    INTO   l_cnrl_id
    FROM   CANDIDATE_FOR_SCREENINGS
    WHERE  CRES_ID = P_SCHK_CRES_ID;

    -- get current CREQ_PROC_ID to update customer_requests process only when current process status not older then new proc_id
    SELECT creq_proc_id
    INTO   l_creq_proc_id_cur
    FROM   CUSTOMER_REQUESTS
    WHERE  CREQ_ID = P_CREQ_ID;

    --1) insert into CANDIDATE_SECURITY_CHECKS
    INSERT INTO CANDIDATE_SECURITY_CHECKS (
        SCHK_ID
      , SCHK_CRES_ID
      , SCHK_DATE
      , SCHK_NOTES
      , SCHK_STGS_ID
      , SCHK_CREATED_USER
      , SCHK_CREATED_DATE
      , SCHK_LAST_MODIFIED_USER
      , SCHK_LAST_MODIFIED_DATE
    ) VALUES(
        l_schk_id
      , P_SCHK_CRES_ID
      , P_SCHK_DATE
      , P_SCHK_NOTES
      , l_schk_stgs_id
      , P_SCHK_CREATED_USER
      , SYSDATE
      , P_SCHK_CREATED_USER
      , SYSDATE
    );
    -- set new ID
      pkg_configuration.set_next_id('CANDIDATE_SECURITY_CHECKS');

    --2) update table CANDIDATE_FOR_SCREENINGS, CANDIDATE_ROLES, CUSTOMER_REQUESTS
    --2.1) IF l_schk_stgs_id in (6,8) 6 SÜ nicht bestanden - Absage, 8	Absage vom Kandidat
    IF l_schk_stgs_id in (6,8) THEN
        -- update status candidate_for_screening
        UPDATE CANDIDATE_FOR_SCREENINGS SET
            CRES_STGS_ID = 6 --	SÜ - Absage
          , CRES_LAST_MODIFIED_USER = P_SCHK_CREATED_USER
          , CRES_LAST_MODIFIED_DATE = SYSDATE
        WHERE CRES_ID = P_SCHK_CRES_ID;
        -- update Status candidate role
        UPDATE CANDIDATE_ROLES SET
            CNRL_CNST_ID = 5 -- ABGESAGT
          , CNRL_LAST_MODIFIED_USER = P_SCHK_CREATED_USER
          , CNRL_LAST_MODIFIED_DATE = SYSDATE
        WHERE  CNRL_ID = l_cnrl_id;

    --2.2) IF l_schk_stgs_id = 7 (7	SÜ bestanden - Vertrag/ Onboarding), insert into CANDIDATE_ONBOARDING
    ELSIF l_schk_stgs_id = 7 THEN
        -- get new Onboarding ID
        l_onbr_id := pkg_configuration.get_next_id('CANDIDATE_ONBOARDINGS');
        -- insert new record in CANDIDATE_ONBOARDINGS
        INSERT INTO CANDIDATE_ONBOARDINGS (
            ONBR_ID
          , ONBR_DATE
          , ONBR_CREATED_USER
          , ONBR_CREATED_DATE
          , ONBR_LAST_MODIFIED_USER
          , ONBR_LAST_MODIFIED_DATE
          , ONBR_STGS_ID
          , ONBR_CRES_ID
        ) VALUES (
            l_onbr_id
          , SYSDATE
          , P_SCHK_CREATED_USER
          , SYSDATE
          , P_SCHK_CREATED_USER
          , SYSDATE
          , 1 --Alle Prüfungen bestanden - Onboarding
          , P_SCHK_CRES_ID
          );
       -- set new ID
       pkg_configuration.set_next_id('CANDIDATE_ONBOARDINGS');

        -- update status candidate_for_screening
        UPDATE CANDIDATE_FOR_SCREENINGS SET
            CRES_STGS_ID = 7	--SÜ bestanden - Vertrag/ Onboarding
          , CRES_LAST_MODIFIED_USER = P_SCHK_CREATED_USER
          , CRES_LAST_MODIFIED_DATE = SYSDATE
        WHERE CRES_ID = P_SCHK_CRES_ID;

        -- update candidate table set the security check information
        UPDATE CANDIDATES SET
            CNDT_SECURITY_CHECK = '1'
          , CNDT_SECURITY_CHECK_DATE = P_CNDT_SECURITY_CHECK_DATE
          , CNDT_LAST_MODIFIED_FROM  = P_SCHK_CREATED_USER
          , CNDT_LAST_MODIFIED_DATE  = SYSDATE
        WHERE CNDT_ID = (SELECT CNRL_CNDT_ID
                         FROM   CANDIDATE_ROLES
                         WHERE CNRL_ID = l_cnrl_id);

            -- update CUSTOMER_REQUESTS only when current status before "Kandidatenüberprüfung im Lauf"
            IF l_creq_proc_id_cur in (1,2,3,4) THEN
                update CUSTOMER_REQUESTS SET
                     CREQ_PROC_ID = 5 -- Vertragsabschluss und Onboarding
                   , CREQ_LAST_MODIFIED_DATE = SYSDATE
                   , CREQ_LAST_MODIFIED_USER = P_SCHK_CREATED_USER
                WHERE CREQ_ID = P_CREQ_ID;
            END IF;   -- end if l_creq_proc_id_cur

    ELSE -- other security checks fortschritte
        UPDATE CANDIDATE_FOR_SCREENINGS SET
            CRES_STGS_ID = 3	--Screening bestanden - SÜ im Prozess
          , CRES_LAST_MODIFIED_USER = P_SCHK_CREATED_USER
          , CRES_LAST_MODIFIED_DATE = SYSDATE
        WHERE CRES_ID = P_SCHK_CRES_ID;
        -- update Status candidate role
        UPDATE CANDIDATE_ROLES SET
            CNRL_CNST_ID = 1 --In Recruitment
          , CNRL_LAST_MODIFIED_USER = P_SCHK_CREATED_USER
          , CNRL_LAST_MODIFIED_DATE = SYSDATE
        WHERE  CNRL_ID = l_cnrl_id;
        -- update customer_requests status only if process before SÜ
        IF l_creq_proc_id_cur in (1,2,3) THEN
            UPDATE CUSTOMER_REQUESTS SET
                CREQ_PROC_ID            = 4 --	Sicherheitsüberprüfung im Lauf
              , CREQ_LAST_MODIFIED_DATE = SYSDATE
              , CREQ_LAST_MODIFIED_USER = P_SCHK_CREATED_USER
            WHERE CREQ_ID = P_CREQ_ID; -- Request ID
        END IF;
    END IF; -- end if l_schk_stgs_id

END; -- END PRC_INSERT_CNDT_SECR_CHECKS

PROCEDURE PRC_UPDATE_CNDT_SECR_CHECKS (
  P_SCHK_ID                     IN CANDIDATE_SECURITY_CHECKS.SCHK_ID%TYPE
, P_SCHK_DATE                   IN CANDIDATE_SECURITY_CHECKS.SCHK_DATE%TYPE
, P_SCHK_NOTES                  IN CANDIDATE_SECURITY_CHECKS.SCHK_NOTES%TYPE
, P_SCHK_CREATED_USER           IN CANDIDATE_SECURITY_CHECKS.SCHK_CREATED_USER%TYPE
)AS
    l_schk_id                   CANDIDATE_SECURITY_CHECKS.SCHK_ID%TYPE;
    no_schk_found               EXCEPTION;
BEGIN
    SELECT SCHK_ID
    INTO   l_schk_id
    FROM   CANDIDATE_SECURITY_CHECKS
    WHERE  SCHK_ID = P_SCHK_ID;

    IF l_schk_id is not null THEN
        UPDATE CANDIDATE_SECURITY_CHECKS SET
            SCHK_DATE   = P_SCHK_DATE
          , SCHK_NOTES  = P_SCHK_NOTES
          , SCHK_LAST_MODIFIED_USER = P_SCHK_CREATED_USER
          , SCHK_LAST_MODIFIED_DATE = SYSDATE
        WHERE SCHK_ID = l_schk_id;
    END IF;

    EXCEPTION
      WHEN no_schk_found THEN
        raise_application_error(-20001,'Keine Daten gefunden - '||SQLCODE||' -ERROR- '||SQLERRM);
      WHEN others THEN
        ROLLBACK;
        raise_application_error(-20002,'Fehler bei Aktualisierung der SÜ Fortschritt - '||SQLCODE||' -ERROR- '||SQLERRM);

END; -- END PRC_UPDATE_CNDT_SECR_CHECKS

PROCEDURE PRC_DELETE_CNDT_SECR_CHECKS (
  P_SCHK_ID                     IN CANDIDATE_SECURITY_CHECKS.SCHK_ID%TYPE
)AS
  l_schk_id                   CANDIDATE_SECURITY_CHECKS.SCHK_ID%TYPE;
  no_schk_found               EXCEPTION;

BEGIN
    -- Check screening records
    SELECT SCHK_ID
    INTO   l_schk_id
    FROM   CANDIDATE_SECURITY_CHECKS
    WHERE  SCHK_ID = P_SCHK_ID;

    IF    l_schk_id is not null THEN
        DELETE
        FROM   CANDIDATE_SECURITY_CHECKS
        WHERE  SCHK_ID = l_schk_id;
    END IF;

    EXCEPTION
      WHEN no_schk_found THEN
        raise_application_error(-20001,'Keine Daten gefunden - '||SQLCODE||' -ERROR- '||SQLERRM);
      WHEN others THEN
        ROLLBACK;
        raise_application_error(-20002,'Fehler bei Löschung der Screening Fortschritt - '||SQLCODE||' -ERROR- '||SQLERRM);


END; -- end PRC_DELETE CNDT_SECR_CHECKS

END; -- end of package body
