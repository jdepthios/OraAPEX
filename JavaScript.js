//https://apex.oracle.com/pls/apex/germancommunities/apexcommunity/tipp/6341/index.html

//den Wert eines Elements auslesen
$v( "P2_ENAME" )
apex.item( "P2_ENAME" ).getValue()

//Anzeigewert
//displayValueFor() funktioniert allerdings nur für solche Elementtypen, bei denen die Werteliste komplett im Browser vorliegt, wie es bei Auswahllisten oder Radiobuttons der Fall ist.
//Bei einer Popup LOV kann die Funktion dagegen nicht verwendet werden.
apex.item( "P2_DEPNO" ).getValue()
<"20"
apex.item( "P2_DEPNO" ).displayValueFor(20)
<"RESEARCH"

// set value
apex.item( "P2_POPUP_LOV" ).getValue()
> "DUAL"
apex.item( "P2_POPUP_LOV" ).setValue( "RETURN","DISPLAY" )
>undefinied
apex.item( "P2_POPUP_LOV" ).getValue()
>"RETURN"

apex.item( "P2_ENAME" ).setValue( "MUSTERMANN", null, true )

//Verstecken und Anzeigen
apex.item( "P2_ENAME" ).hide()
apex.item( "P2_ENAME" ).show()

//isChanged() liefert unmittelbar nach dem Laden der Seite ein false zurück.
//Wenn der Anwender den Wert im Eingabefeld geändert hat, oder setValue() aufgerufen wurde, wird isChanged() von da an true zurückliefern.
//Das kann sehr interessant sein, um beispielsweise festzustellen, ob ein AJAX-Request zum Server wirklich nötig ist oder nicht.
//Wenn isChanged() für alle beteiligten Elemente false zurückliefert, kann man sich AJAX-Requests zum Server sparen ...

apex.item("P2_ENAME").isChanged()
< false
apex.item("P2_ENAME").setValue("APEX")
< undefinied
apex.item("P2_ENAME").isChanged()
< true

//Aktivieren und deaktivieren
apex.item( "P2_ENAME" ).enable()
apex.item( "P2_ENAME" ).disable()

//Mit setStyle() kann schließlich ein CSS-Style zugewiesen werden.
apex.item( "P2_JOB" ).setStyle({"background-color":"yellow", "font-weight": "bold"})



//Beispiel
var rn=$('#P606_EMPL_REPL_NEEDED').val(),
    c1='#P606_EMPL_REPL_NEEDED_NOTES_CONTAINER',
    c2='#P606_CREQ_ROLE_PERIOD_REPL_CONTAINER';
if (rn == "Y") {
        $(c1).hide();
        $(c2).show();
    } else if (rn == "N") {
        $(c1).show();
        $(c2).hide();
    }  else if (rn == "-1") {
        $(c1).hide();
        $(c2).hide();
    }

//------------------------------------------------------------------------------------------//
// HOW TO DETECT Browser
// https://stackoverflow.com/questions/9847580/how-to-detect-safari-chrome-ie-firefox-and-opera-browser/9851769

//------------------------------------------------------------------------------------------//
//Opera 8.0+
var isOpera = (!!window.opr && !!opr.addons) || !!window.opera || navigator.userAgent.indexOf(' OPR/') >= 0;

// Firefox 1.0+
var isFirefox = typeof InstallTrigger !== 'undefined';

// Safari 3.0+ "[object HTMLElementConstructor]"
var isSafari = /constructor/i.test(window.HTMLElement) || (function (p) { return p.toString() === "[object SafariRemoteNotification]"; })(!window['safari'] || safari.pushNotification);

// Internet Explorer 6-11
var isIE = /*@cc_on!@*/false || !!document.documentMode;

// Edge 20+
var isEdge = !isIE && !!window.StyleMedia;

// Chrome 1+
var isChrome = !!window.chrome && !!window.chrome.webstore;

// Blink engine detection
var isBlink = (isChrome || isOpera) && !!window.CSS;

var output = 'Detecting browsers by ducktyping:<hr>';
output += 'isFirefox: ' + isFirefox + '<br>';
output += 'isChrome: ' + isChrome + '<br>';
output += 'isSafari: ' + isSafari + '<br>';
output += 'isOpera: ' + isOpera + '<br>';
output += 'isIE: ' + isIE + '<br>';
output += 'isEdge: ' + isEdge + '<br>';
output += 'isBlink: ' + isBlink + '<br>';
document.body.innerHTML = output;

if (isIE = /*@cc_on!@*/false || !!document.documentMode) {
alert ("IE");}
else {
alert ("others");
}


//------------------------------------------------------------------------------------------//
// Apex Using Page Items In Javascript
//------------------------------------------------------------------------------------------//

//If you want to get value of an item you should follow below syntax :

function showItemValue(){
  alert('Item value is ' +$v('P1_ITEM'))
};

//It is simple all you need to do is using $v to get the value of the item.Another example is assigning a value to the page item :

function setItemValue(pItemValue){
  $s('P1_ITEM', pItemValue);
};
