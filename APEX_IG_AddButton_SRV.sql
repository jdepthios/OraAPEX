-- Interactive Grid
-- Create Button in Report
-- Single Report View
-----------------------------------------------------------
-- Interactive Grid Reports Region und Attribute
-----------------------------------------------------------
--  Reports Region: --
SELECT
  PROJ_ID
, PROJ_NAME
, PROJ_OWNER
, PROJ_START_DATE
, PROJ_END_DATE
, PROJ_CUST_ID
FROM PROJECTS
ORDER BY PROJ_NAME

-- static ID : proj

-- Attribute --
-- JavaScript Initialization Code --
function(config) {
    var $ = apex.jQuery,
        toolbarData = $.apex.interactiveGrid.copyDefaultToolbar(),
        lastToolbarGroup = toolbarData.toolbarFind("actions4"),
        createButton = {
            type: "BUTTON",
            hot: true,
            action: "create-project"
        };
    lastToolbarGroup.controls.push( createButton );
    config.toolbarData = toolbarData;

    // this is how actions are added
    config.initActions = function(actions) {
        actions.add({
            name: "create-project",
            // you could define the label directly as English text
            // label: "Create"
            // But better to use a message so it can be translated. In shared
            // components, text messages create MY_CREATE_BUTTON = Create and
            // set Used in JavaScript: Yes
            labelKey: "Neue Projekt anlegen",
            // this sets the action to be what the hidden button does when you click it
            action: $("#hiddenCreate").prop("onclick")
        });
    }

    console.log(config);

    return config;
}


-----------------------------------------------------------
-- Create Dummy Region, Button und Hidden ID
-----------------------------------------------------------
--  Static Content Region: --
Custom attribute : style="display:none"

-- Button
Name: dummy_proj
Redirect to Page 111 (Create new Projekt )
Static ID: hiddenCreate --> this will be called in the JavaScript Initialization CODE
