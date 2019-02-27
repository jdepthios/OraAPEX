-- At the top of each package body
scope_prefix constant varchar2(31) := lower($$plsql_unit) || '.';

-- Sample procedure usage
PROCEDURE todo_proc_name
  (param1_mandatory IN VARCHAR2
  ,param2_optional  IN VARCHAR2
  ,param3_out       OUT VARCHAR2) IS
  scope  logger_logs.scope%type := scope_prefix || 'todo_proc_name';
  params logger.tab_param;
BEGIN
  logger.append_param(params, 'param1_mandatory', param1_mandatory);
  logger.append_param(params, 'param2_optional', param2_optional);
  logger.log('START', scope, null, params);

  assert(param1_mandatory IS NOT NULL, 'param1_mandatory cannot be null', scope);

  ... your procedure logic ...

  logger.append_param(params, 'param3_out', param3_out);
  logger.log('END', scope, null, params);
EXCEPTION
  WHEN UTIL.application_error THEN
    logger.log_error('Application Error', scope, null, params);
    RAISE;
  WHEN OTHERS THEN
    logger.log_error('Unhandled Exception', scope, null, params);
    RAISE;
END todo_proc_name;

-- Sample function usage
FUNCTION todo_func_name
  (param1_mandatory IN VARCHAR2
  ,param2_optional  IN VARCHAR2
  ) RETURN ret_type IS
  scope  logger_logs.scope%type := scope_prefix || 'todo_func_name';
  params logger.tab_param;
  ret    ret_type;
BEGIN
  logger.append_param(params, 'param1_mandatory', param1_mandatory);
  logger.append_param(params, 'param2_optional', param2_optional);
  logger.log('START', scope, null, params);

  assert(param1_mandatory IS NOT NULL, 'param1_mandatory cannot be null', scope);

  ... your procedure logic ...

  logger.append_param(params, 'ret.attr1', ret.attr1);
  logger.append_param(params, 'ret.attr2', ret.attr2);
  logger.log('END', scope, null, params);
  RETURN ret;
EXCEPTION
  WHEN UTIL.application_error THEN
    logger.log_error('Application Error', scope, null, params);
    RAISE;
  WHEN OTHERS THEN
    logger.log_error('Unhandled Exception', scope, null, params);
    RAISE;
END todo_func_name;
