//to check all elements in toolbarData object
apex.region("emp_igrid").widget().interactiveGrid("option","config")


//------------------------------------------------------------------------------------------------------//
//https://thtechnology.com/2017/07/21/apex-interactive-grid-customize-toolbar/
//Let’s say our users do not like doing two clicks (Actions –> Download) to get to Download
//they want a Download button on their toolbar.  In fact, they want it all the way over to the right.
//------------------------------------------------------------------------------------------------------//

function(config) {
 var $ = apex.jQuery,
 //Copy the default toolbarData – we will make changes to a copy
 toolbarData = $.apex.interactiveGrid.copyDefaultToolbar(),
 //Get the actions4 toolbar group
 toolbarGroup = toolbarData.toolbarFind("actions4"); // this IS the rightmost GROUP WITH the RESET button

// add a Download button next to the Reset button
//Add (Push) the download dialog to the actions4 toolbar group
 toolbarGroup.controls.push( {
 type: "BUTTON",
 action: "show-download-dialog",
 iconBeforeLabel: true,
 hide: false,
 disabled: false
 });

 //Copy the modified toolbar to the return config
 config.toolbarData = toolbarData;
 return config;
}

//to turn off the download button use this command as part of you Advanced –> JavaScript Code function, or in a dynamic action.
//This command will also turn off your newly-placed Download button.
config.features.download = false;


//------------------------------------------------------------------------------------------------------//
//http://www.virtual7.de/blog/2018/05/implementing-a-select-list-in-the-interactive-grids-toolbar/
// Implementing a Select List in the Interactive Grid’s toolbar
//------------------------------------------------------------------------------------------------------//
function (config) {
    /* declare variables */
    var $ = apex.jQuery,
        toolbarData = $.apex.interactiveGrid.copyDefaultToolbar(), // get the default toolbar in the form of an array
        toolbarGroup = toolbarData[toolbarData.length - 2]; // get the desired array element or group, which usually are also arrays

    /* push a new element in the array */
    toolbarGroup.controls.push( {
        type: "SELECT", // set the element's type
        id: "my-select", // set an id for the element
        action: "my-action" // set a custom action or an already existing one
    });

    /* update the current toolbar's configuration */
    config.toolbarData = toolbarData;

    /* initialize a custom action */
    config.initActions = function( actions ) {
        actions.add( {
            name: "my-action",
            choices: [{ label: "A", value: "1" }, { label: "B", value: "2" }],
            action: function(event, focusElement) {
                /* custom action */
                /* it gets the currently selected value in the Select List and displays the value in an alert */
                var e = document.getElementById("test_ig_toolbar_my-select");
                var strUserValue = e.options[e.selectedIndex].value;
                var strUserText = e.options[e.selectedIndex].text;
                alert(strUserValue + ' ' + strUserText);
            }
        } );
    };
    console.log("config", config);

    /* return the new Interactive Grid's configuration */
    return config;
}


//------------------------------------------------------------------------------------------------------//
// adding button create project
// action: by clicking the button open a popup region inline Dialog hiddenCreate
//------------------------------------------------------------------------------------------------------//


function(config) {
    var $ = apex.jQuery,
        toolbarData = $.apex.interactiveGrid.copyDefaultToolbar(), // get the default toolbar in the form of an array
        lastToolbarGroup = toolbarData.toolbarFind("actions4"), // get the desired array element or group, which usually are also arrays


    /* push a new element in the array */
    lastToolbarGroup.controls.push( {
      type: "BUTTON",
      hot: true,
      action: "create-project"
    } );

     /* update the current toolbar's configuration */
    config.toolbarData = toolbarData;

    // this is how actions are added
    config.initActions = function(actions) {
        actions.add({
            name: "create-project",
            // you could define the label directly as English text
            // label: "Create"
            // components, text messages create MY_CREATE_BUTTON = Create and
            // set Used in JavaScript: Yes
            labelKey: "Neue Projekt anlegen",
            // this sets the action to be what the hidden button does when you click it
            action: $("#hiddenCreate").prop("onclick")  // click the hidden button with static id hiddenCreate
        });
    }

    console.log(config);

    return config;
}



// CREATE BTN in Interactive grid report "Rückmeldung erfassen" using button "RESP_HIDDEN_BTN"

function (config){
    var $ = apex.jQuery
    , toolbarData = $.apex.interactiveGrid.copyDefaultToolbar()
    , toolbarGroup = toolbarData.toolbarFind("actions4");

    // push new element to new array
    toolbarGroup.controls.push({
          type: "BUTTON"
        , hot: true
        , action: "create-response"
    });

    config.toolbarData = toolbarData;

    config.initActions = function(actions) {
        actions.add({
              name: "create-response"
            , action:  $("#hiddenCreate").prop("onclick")
            , labelKey: "Rückmeldung erfassen"
        })

    }

    console.log(config);
    return config;
}



// HIDE Toolbar
function( options ) {
    options.toolbar = false;    // to hide toolbar
    return options;
}


function(config) {     // Remove edit button
  var toolbar = $.apex.interactiveGrid.copyDefaultToolbar();
  var group = toolbar.toolbarFind("actions2");     // Edit is the first control, remove it.
   group.controls.shift();
   config.toolbarData = toolbar;
 }


// rename label

function(config) {
    let $             = apex.jQuery,
        toolbarData   = $.apex.interactiveGrid.copyDefaultToolbar(),
        addrowAction  = toolbarData.toolbarFind("selection-add-row"),
        saveAction    = toolbarData.toolbarFind("save"),
        editAction    = toolbarData.toolbarFind("edit");

    addrowAction.icon = "icon-ig-add-row";
    addrowAction.iconBeforeLabel = true;
    addrowAction.hot = true;
    addrowAction.label = "Neue Zeile"

    saveAction.label = "Speichern";
    saveAction.iconBeforeLabel = true;
    saveAction.icon ="icon-ig-save-as";
    saveAction.hot = true;

    editAction.label = "Editieren";

    config.toolbarData = toolbarData;
    return config;
}


function(config) {
    let $ = apex.jQuery,
        toolbarData = $.apex.interactiveGrid.copyDefaultToolbar(), // copy the whole toolbar
        toolbarGroup = toolbarData.toolbarFind("actions3"); // this is the group with the action=add row
        addrowAction = toolbarData.toolbarFind("selection-add-row"), //add row button
        saveAction = toolbarData.toolbarFind("save"); // Save button

    // add a new "delete" button
    toolbarGroup.controls.push({type: "BUTTON",
                                action: "selection-delete",
                                icon: "icon-ig-delete", // alternative FontAwesome icon: "fa fa-trash",
                                iconBeforeLabel: true,
                                hot: true
                               });


    // manipulate the buttons
    addrowAction.icon = "icon-ig-add-row"; // alternative font awesome icon: "fa fa-plus";
    addrowAction.iconBeforeLabel = true;
    addrowAction.hot = true;
    addrowAction.label = "Neue Rolle zuweisen"

    saveAction.iconBeforeLabel = true;
    saveAction.icon ="icon-ig-save-as"; // list of alternative grid icons (Font Apex):icon-ig-save,icon-irr-saved-report
    //saveAction.icon ="fa fa-save"; // list of alternative font awesome icons: fa-save,fa-check
    saveAction.hot = true;


    //store the config
    config.toolbarData = toolbarData;
    return config;
}
