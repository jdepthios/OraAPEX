//https://ruepprich.wordpress.com/2017/03/09/apex-updating-interactive-grid-cells/

First I built an interactive grid on the EMP table. I’ve used all the defaults except:
Enable editing with Update Row.
Set the region’s static ID to emps.
Added a link column with target type: URL, URL: #

The link text is set to Promote, and I added class (ig-link) so that I can connect a dynamic action to it

Next I created a dynamic action that fires when the Promote link is clicked.

The true action is a Execute JavaScript Code action, with the following code:

//Get the link element that was clicked
var $te = $(this.triggeringElement);

//Get the ID of the row
var rowId = $te.closest('tr').data('id');
 
//Identify the particular interactive grid
var ig$ = apex.region("emps").widget();

//Fetch the model for the interactive grid
var model = ig$.interactiveGrid("getViews","grid").model;

//Fetch the record for the particular rowId
var record = model.getRecord(rowId);

//Access the cell value via the column name
var sal = model.getValue(record,"SAL");

//Set the values for the JOB and SAL cells
model.setValue(record,"JOB",'MANAGER');
model.setValue(record,"SAL",sal*2);
