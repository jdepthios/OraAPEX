// to hide button RESET in IG (inline css)
button[data-action=reset-report]  {
   display: none !important;
}

//IG Report --> Attribute --> JavaScript Initialization Code

// to see options put this in code, run it, open F12, console --> object
function( options ) {
    console.log(options);
    return options;
}

// to see all available options for columns in the region cndt in console
apex.region("proj").widget().interactiveGrid("option").config
oder
apex.region("proj").widget().interactiveGrid("option","config")


// example for report attribute
function( options ) {
    options.toolbar = false;    // to hide toolbar
    options.appearance.showNullValue = '';
    options.features.download.formats.pop(); // hide HTML as download

    return options;
}

//example for column attribute ENAME

function( options ) {
    options.features = options.features || {};
    options.features.sort = false;
    options.features.controlBreak = false;
    return options;
}


// to controll all JS in report attribute js setIGCol (functionname, columnname, feature name, value)
function(config) {
  setIGCol (config, 'ENAME', 'features.sort', false)
  return config

}
