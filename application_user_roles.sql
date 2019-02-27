--USER
select * from APEX_APPL_ACL_USERS;
select * from APEX_APPL_ACL_ROLES;

/*-------------------------------------
APPLICATION 101> SHARED COMPONENTS > AUTHORIZATION SCHEMES

Scheme Type: PL/SQL Function Returning Boolean
MAV_AUTH_MAIN
*/
BEGIN;
IF(to_number(F_IS_AUTHORIZED(
	  P_APP_USER		=> :APP_USER
	, P_APP_ID			=> :APP_ID
	, P_PAGE_ID			=> :APP_PAGE_ID
	, P_COMP_ID			=> :APP_COMPONENT_ID
	, P_COMP_TYPE		=> :APP_COMPONENT_TYPE
	, P_COMP_NAME		=> :APP_COMPONENT_NAME
	, P_SCHEMA			=> sys_context('userenv', 'current_schema'))) > 0
THEN
	RETURN TRUE;
ELSE
	RETURN FALSE;
END IF;
END;
-------------------------------------------------------------

return apex_acl.has_user_role (
     p_application_id=>:APP_ID,
     p_user_name => :APP_USER,
     p_role_static_id => 'ADMINISTRATOR');


if apex_acl.has_user_role (
  p_application_id=>:APP_ID,
  p_user_name => :APP_USER,
  p_role_static_id => 'ADMINISTRATOR') or
  apex_acl.has_user_role (
    p_application_id=>:APP_ID,
    p_user_name=> :APP_USER,
    p_role_static_id=> 'CONTRIBUTOR') then
    return true;
else
    return false;
end if;



if nvl(apex_app_setting.get_value(
   p_name => 'ACCESS_CONTROL_SCOPE'),'x') = 'ALL_USERS' then
    -- allow user not in the ACL to access the application
    return true;
else
    -- require user to have at least one role
    return apex_acl.has_user_any_roles (
        p_application_id => :APP_ID,
        p_user_name      => :APP_USER);
end if;



-------------------------- TEST ---
APPLICATION 101> SHARED COMPONENTS > AUTHORIZATION SCHEMES

Scheme Type: PL/SQL Function Returning Boolean
MAV_AUTH_MAIN

IF(to_number(F_IS_AUTHORIZED(
	  P_APP_USER		=> :APP_USER
	, P_APP_ID			=> :APP_ID
	, P_PAGE_ID			=> :APP_PAGE_ID
	, P_COMP_ID			=> :APP_COMPONENT_ID
	, P_COMP_TYPE		=> :APP_COMPONENT_TYPE
	, P_COMP_NAME		=> :APP_COMPONENT_NAME
	, P_SCHEMA			=> sys_context('userenv, 'current_schema'))) > 0
THEN
	RETURN TRUE;
ELSE
	RETURN FALSE;
END IF;
