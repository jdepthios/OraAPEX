---------------------------------------------------------------------------------------
-- Skeleton by http://barrybrierley.blogspot.de/2015/05/apex-shuttle-selecting-multiple-values.html
-- 15.11.16  SOB  tweaked shuffle behaviour to convert "displyed" strings to numbers (see below)
---------------------------------------------------------------------------------------
-- see also http://dgielis.blogspot.com/2015/01/using-shuttles-in-many-to-many.html

---------------------------------------------------------------------------------------
--Defaulting the values from the database --we want to default the values based on what we already have in the database.
--In the designer, right-click on the shuttle that you created, and "Create Computation".
--Type: PL/SQL Function Body:
DECLARE
   tab apex_application_global.vc_arr2;
   i    number := 1;
begin
   for r in (select ura.role_id
               from user_roles_assigned ura
                where ura.user_id = :P5_USER_ID) loop
      tab(i) := r.role_id;
      i := i + 1;
   end loop;

   return apex_util.table_to_string(tab,':');
end;

---------------------------------------------------------------------------------------
-- Shuttle Left Pane => roles NOT yet assigned to user
-- Inline LOV for Shuttle Object -> List Of Values -> SQL Query:
select r.role_name as d,
       r.role_id as r
  from user_roles r
where not exists (select 1 from user_roles_assigned ura
              where ura.role_id = r.role_id
              and ura.user_id = :P5_USER_ID)  order by 1

---------------------------------------------------------------------------------------
-- page process (after submit) to update the roles_assigned table
-- needed to be tweaked, since if you use role_id in right hand side of the shuffle
-- it will be displayed as numbers, because the overall shuttle is displayed by a LOV.
-- Selecting Names and trying insert them will yield
-- ORA-06502: PL/SQL: numeric or value error: character to number conversion error
-- pre defined in PL/SQL as VALUE_ERROR  -6502 declare
    tab apex_application_global.vc_arr2;
    l_role_id number;
begin
    -- delete what we have for this user
    delete from odbdat.user_roles_assigned where user_id = :P5_USER_ID;
    -- convert the shuttle values into a table
    tab := apex_util.string_to_table (:P5_SHUTTLE);
    -- loop for every row in shuttle and determine if its a number from the LOV
    -- or a string from the previously filled right hand side of the shuttle
    for i in 1..tab.count loop
        begin
            -- try to convert to a number, throws error below for strings
            l_role_id := to_number(tab(i));
            -- we catch the error specifically and resolve the name to an id
            exception when VALUE_ERROR then
                select role_id into l_role_id
                from user_roles
                where role_name = tab(i);
            when others then
                raise;
        end;
        insert into odbdat.user_roles_assigned (ura_id, user_id, role_id)
        values (odbdat.rolesassigned_seq.nextval, :P5_USER_ID, l_role_id);
    end loop;
    commit;
end;


-- ad a submit button to fire the page process
