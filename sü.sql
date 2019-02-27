PROCEDURE PRC_CANDIDATE_SECURITY_CHECKS (
  P_SCHK_ID                     IN CANDIDATE_SECURITY_CHECKS.SCHK_ID%TYPE
, P_SCHK_CRES_ID                IN CANDIDATE_SECURITY_CHECKS.SCHK_CRES_ID%TYPE
, P_SCHK_DATE                   IN CANDIDATE_SECURITY_CHECKS.SCHK_DATE%TYPE
, P_SCHK_NOTES                  IN CANDIDATE_SECURITY_CHECKS.SCHK_NOTES%TYPE
, P_SCHK_STGS_ID                IN CANDIDATE_SECURITY_CHECKS.SCHK_STGS_ID%TYPE
, P_SCHK_CREATED_USER           IN CANDIDATE_SECURITY_CHECKS.SCHK_CREATED_USER%TYPE
, P_CNDT_SECURITY_CHECK_DATE    IN CANDIDATES.CNDT_SECURITY_CHECK_DATE%TYPE
-- ----------------------------------------------------------------------------------------------
-- 1) insert into CANDIDATE_SECURITY_CHECKS
--2) update table CANDIDATE_FOR_SCREENINGS, CANDIDATE_ROLES, CUSTOMER_REQUESTS
--2.1) IF l_schk_stgs_id in (6,8) 6 SÜ nicht bestanden - Absage, 8	Absage vom Kandidat
--2.2) IF l_schk_stgs_id = 7 (7	SÜ bestanden - Vertrag/ Onboarding), insert into CANDIDATE_ONBOARDING
-- ----------------------------------------------------------------------------------------------

)
AS
  v_cnt NUMBER;
  l_schk_id                   CANDIDATE_SECURITY_CHECKS.SCHK_ID%TYPE;
  l_schk_stgs_id              CANDIDATE_SECURITY_CHECKS.SCHK_STGS_ID%TYPE;
  l_cnrl_id                   CANDIDATE_ROLES.CNRL_ID%TYPE;
  l_onbr_id                   CANDIDATE_ONBOARDINGS.ONBR_ID%TYPE;
  l_creq_id                   CUSTOMER_REQUESTS.CREQ_ID%TYPE;
  l_creq_proc_id_cur          CUSTOMER_REQUESTS.CREQ_PROC_ID%TYPE;

BEGIN
  SELECT COUNT (*)
  into   v_cnt
  FROM   CANDIDATE_SECURITY_CHECKS
  WHERE  SCHK_ID =  P_SCHK_ID;

  IF v_cnt > 0 THEN
    BEGIN
       UPDATE CANDIDATE_SECURITY_CHECKS SET
            SCHK_DATE   = P_SCHK_DATE
          , SCHK_NOTES  = P_SCHK_NOTES
          , SCHK_LAST_MODIFIED_USER = P_SCHK_CREATED_USER
          , SCHK_LAST_MODIFIED_DATE = SYSDATE
        WHERE SCHK_ID = P_SCHK_ID;

      EXCEPTION
      WHEN OTHERS THEN
      ROLLBACK;
      raise_application_error(-20112,'ERROR - UPDATE CANDIDATE_SECURITY_CHECKS - '||SQLCODE||' -ERROR- '||SQLERRM);
    END;
  ELSE
    -- get new ID
    l_schk_id := pkg_configuration.get_next_id('CANDIDATE_SECURITY_CHECKS');

    SELECT CRES_CREQ_ID, CRES_CNRL_ID
    INTO   l_creq_id, l_cnrl_id
    FROM   CANDIDATE_FOR_SCREENINGS
    WHERE  CRES_ID = P_SCHK_CRES_ID;

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
          , P_SCHK_STGS_ID
          , P_SCHK_CREATED_USER
          , SYSDATE
          , P_SCHK_CREATED_USER
          , SYSDATE
        );
    -- set new ID
    pkg_configuration.set_next_id('CANDIDATE_SECURITY_CHECKS');

    -- SECURITY CHECKS STAGES

      SELECT CREQ_PROC_ID
      INTO   l_creq_proc_id_cur
      FROM   CUSTOMER_REQUESTS
      WHERE  CREQ_ID = (SELECT CRES_CREQ_ID FROM CANDIDATE_FOR_SCREENINGS WHERE CRES_ID = P_SCHK_CRES_ID);

      IF P_SCHK_STGS_ID in (6,8) THEN
        BEGIN -- ABSAGE

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
        END; -- ABSAGE
      --
      ELSIF P_SCHK_STGS_ID = 7 THEN
        BEGIN -- 7	SÜ bestanden - Vertrag/ Onboarding
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
                           JOIN   CANDIDATE_FOR_SCREENINGS ON CRES_CNRL_ID = CNRL_ID
                           WHERE  CRES_ID = P_SCHK_CRES_ID);

          -- update CUSTOMER_REQUESTS only when current status before "Kandidatenüberprüfung im Lauf"
          IF l_creq_proc_id_cur in (1,2,3,4) THEN
              update CUSTOMER_REQUESTS SET
                   CREQ_PROC_ID = 5 -- Vertragsabschluss und Onboarding
                 , CREQ_LAST_MODIFIED_DATE = SYSDATE
                 , CREQ_LAST_MODIFIED_USER = P_SCHK_CREATED_USER
              WHERE CREQ_ID = (SELECT CRES_CREQ_ID FROM CANDIDATE_FOR_SCREENINGS WHERE CRES_ID = P_SCHK_CRES_ID);
          END IF;   -- end if l_creq_proc_id_cur

          EXCEPTION
          WHEN OTHERS THEN
          ROLLBACK;
          raise_application_error(-20113,'ERROR- IN SECURITY CHECKS, UPDATE STATUS - '||SQLCODE||' -ERROR- '||SQLERRM);
        END; --7	SÜ bestanden - Vertrag/ Onboarding
      --
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
            WHERE CREQ_ID = (SELECT CRES_CREQ_ID FROM CANDIDATE_FOR_SCREENINGS WHERE CRES_ID = P_SCHK_CRES_ID);
        END IF;
      END IF;

    EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
    raise_application_error(-20113,'ERROR- IN SECURITY CHECKS, UPDATE STATUS - '||SQLCODE||' -ERROR- '||SQLERRM);
    END;


EXCEPTION
WHEN OTHERS THEN
raise_application_error(-20111,'Fehler bei Löschung der Screening Fortschritt - '||SQLCODE||' -ERROR- '||SQLERRM);
END; --PRC_CANDIDATE_SECURITY_CHECKS
