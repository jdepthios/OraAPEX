-- prepare view

CREATE OR REPLACE VIEW V_PROJECTS_SUBPROJECTS_TREE AS
SELECT
     'CUST' TYPE
    , CUST_NAME NAME
    , CUST_ID   VALUE_ID
    , NULL      PARENT_ID
    , NULL      DESCRIPTION
FROM CUSTOMERS
UNION
select
      'PROJ' TYPE
    , PROJ_NAME NAME
    , PROJ_ID VALUE_ID
    , PROJ_CUST_ID PARENT_ID
    , PROJ_OWNER
  from projects
UNION
select
      'SPRJ' TYPE
    , SPRJ_NAME as name
    , SPRJ_ID VALUE_ID
    , SPRJ_PROJ_ID PARENT_ID
  from SUBPROJECTS
  ;

-- Region Type: Tree
--SQL Query
select  case when connect_by_isleaf = 1 then 0
             when level = 1 then 1
             else -1
        end as status
      , level
      , NAME as title
      , 'icon-tree-folder' as icon
      , VALUE_ID as value
      , NAME as tooltip
      , CASE WHEN TYPE = 'PROJ'
                THEN apex_util.prepare_url( 'f?p='|| :APP_ID || ':111:' ||:APP_SESSION||'::NO::P111_PROJ_ID:'||value_id)
             WHEN TYPE = 'SPRJ'
                THEN apex_util.prepare_url('f?p='|| :APP_ID || ':112:'|| :APP_SESSION||'::NO::P112_SPRJ_ID:'||value_id)
             ELSE
                NULL
        END as link
from V_PROJECTS_SUBPROJECTS_TREE
start with PARENT_ID is null
CONNECT BY PRIOR VALUE_ID = PARENT_ID
order siblings by NAME;

--Attributes
Node label column : title
node value column : value
hierarchy : not computed
node status column: level
tooltip: database column
tooltip column: tooltip
activate node link with: single click
link column: link

--customizing TREE

Dynamic action --> on page load
So I simply used following DA, I called customize tree, on page load

with javascript code to set the desired CSS
$("[aria-level=2]").css({"color":"green","font-weight":"bold"});
$("[aria-level=3]").css({"color":"blue","font-weight":"bold"});

-- oder in der inline css
[aria-level="2"] {
  color: green;
  font-weight: bold;
}
[aria-level="3"] {
  color: blue;
  font-weight: bold;
}
