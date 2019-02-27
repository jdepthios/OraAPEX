//------------------------------------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------//
var my_primary_report_name;

$('#'+this.triggeringElement.id+' .a-IRR-selectList')
  .find('option').each(function(index,elem){
  $(elem).text(function(i,text){
    return text.replace('1. Primary Report',my_primary_report_name);
  }); // end of text change
}); // end of option walk
//------------------------------------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------//
var htmldb_delete_message='"DELETE_CONFIRM_MSG"';
//------------------------------------------------------------------------------------------------------//

function isLeapYear(year) {
    return (((year % 4 === 0) && (year % 100 !== 0)) || (year % 400 === 0));
}

function getDaysInMonth(year, month) {
    return [31, (isLeapYear(year) ? 29 : 28), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month];
}
function addMonths() {
    var   date = $("#P524_CHSE_PROJ_START_DATE").datepicker("getDate")
        , m =  $x("P524_ROLE_PERIOD").value
        , d = new Date(date)
        , n = date.getDate();

    const months = ["JAN", "FEB", "MAR","APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
     d.setDate(1);
     d.setMonth(d.getMonth() + m);
     d.setDate(Math.min(n, getDaysInMonth(d.getFullYear(), d.getMonth())));

    df = d.getDate() + "-" + months[d.getMonth()] + "-" + d.getFullYear()
    return df;
}
//------------------------------------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------//
var htmldb_delete_message='"DELETE_CONFIRM_MSG"';

function addMonths(m) {
      if (m === undefined){
          // get the Item Value for the Months
          m= $v('P524_ROLE_PERIOD');

          const months = ["JAN", "FEB", "MAR","APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
          var   date = $("#P524_CHSE_PROJ_START_DATE").datepicker("getDate")
              , d = new Date(date)
              , n = date.getDate()
              // konvertiert m in number
              , mn = Number(m);

           d.setMonth(d.getMonth() + mn);
           df = d.getDate() + "-" + months[d.getMonth()] + "-" + d.getFullYear();
        }
      return df;
}


function dateCalc(itemDuration, itemDate) {

     var itemDuration = document.getElementById('itemDuration').value;
     var itemDate = document.getElementById('itemDate').value;

     var d1 = new Date(itemDate)
       , n = itemDate.getDate();

     const months = ["JAN", "FEB", "MAR","APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
     d1.setMonth(d.getMonth() + mn);
     d2 = d.getDate() + "-" + months[d1.getMonth()] + "-" + d1.getFullYear();
    return d2;
}
