Hide and show if ITEM 1 Changed

--------------------
-- ITEMS --
--------------------
ITEM 1
Name: P106_INTW_TYPE (select list)
Type: Static Values (YES/ NO)
display extra value: NO
Display null value: Yes
Null Return value: -1

ITEM 2
Name: P106_INTW_RESC_ID (select list)

ITEM 3
NAME: P106_INTW_CUST_ID (select list)
--------------------
-- DYNAMIC ACTION --
--------------------
Create Dynamic action: P106_INTW_TYPE Item changed
True Action: Execute JavaScript

var rn=$('#P106_INTW_TYPE').val(),
    c1='#P106_INTW_RESC_ID_CONTAINER',
    c2='#P106_INTW_CUST_ID_CONTAINER';

   if (rn == "External") {
        $(c1).hide();
        $(c2).show();
    }
    else if (rn == "Internal") {
        $(c1).show();
        $(c2).hide();
    }
    else if (rn == "-1"){
        $(c1).hide();
        $(c2).hide();
    }
--------------------
--PAGE --
--------------------
JavaScript
Execute when Page loads:
apex.item( "P106_INTW_TYPE" ).setValue( '&P106_INTW_TYPE.')
