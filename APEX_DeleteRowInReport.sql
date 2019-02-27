--------------------------------------------------------------------------------------------
--https://jackiemcilroy.blogspot.com/2018/03/delete-row-of-report-with-dynamic-action.html--
--http://www.virtual7.de/blog/2017/02/oracle-aperx-5-1-link-to-deletion/
--------------------------------------------------------------------------------------------
/*
what we need:
1) a hidden page item
2) a link column in report
3) dynamic actions

PREPARATION

1) CREATE hidden Page
Name: P_DELETE_ID, type: hidden

2) a link column in Report for the delete Icon, you could use ID column for it
Report --> Column --> ID
Column name: DOCS_ID
Type: link
Link target: URL
URL:   javascript:void(null);



Link Text: <span class="t-Icon fa fa-trash delete-note" aria-hidden="true"></span>
Link Attributes: data-id=#DOCS_ID#

!! in the link  text there is a class called "delete-note" this is the jQuery selector we will use to trigger our dynamic action

3) dynamic actions
Next, we need a dynamic action that fires on click of our jQuery selector, .delete-note. This action will have four true actions:
3a) Confirm : Text: Möchten Sie wirklich die Daten endgültig löschen?
3b) Set VALUE
3c) Execute PL/SQL
3d) Refresh

*/
--dynamic actions
Event: Click
Selection type: JQuery selector
jQuery Selector: .delete-note

--True Action 3a): Confirm
Text: Möchten Sie wirklich die Daten endgültig löschen?

--True Action 3b): Set Value
Settings:
Set Type: JavaScript Expression
JavaScript Expression: $(this.triggeringElement).parent().data('id')
Affected elements:
Selection Type: Item(s)
Items(s): P_DELETE_ID <---- your hidden page item

--True Action 3c): Execute PL/SQL Code
PL/SQL Code:
      begin

          delete from candidate_documents where DOCS_ID = :P_DELETE_ID;

        exception
          when NO_DATA_FOUND then null;

      end;

Items to Submit: P20_DELETE_ID <---- your hidden page item

-- True Action 3d) Refresh
Selection Type: Region
Region: Report  <---- your report region




//custom message for the dynamic actions

	function show_success_message(p_message){

	  $("div#t_Alert_Success").remove();  //remove the item first

	 $('#APEX_SUCCESS_MESSAGE').append('<div class="t-Alert t-Alert--defaultIcons t-Alert--horizontal t-Alert--page t-Alert--colorBG is-visible t-Alert--warning" id="t_Alert_Success" role="alert">    <div class="t-Alert-wrap">      <div class="t-Alert-icon">        <span class="t-Icon"></span>      </div>     <div class="t-Alert-content">        <div class="t-Alert-header">          <h2 class="t-Alert-title">'+apex.util.escapeHTML(p_message)+'</h2>        </div>      </div>      <div class="t-Alert-buttons">        <button class="t-Button t-Button--noUI t-Button--icon t-Button--closeAlert" onclick="apex.jQuery(\'#t_Alert_Success\').remove();" type="button" title="Close Notification"><span class="t-Icon icon-close"></span></button>      </div>    </div>');


	    $('#APEX_SUCCESS_MESSAGE').removeClass('u-hidden');


	    $("div#t_Alert_Success").fadeOut(4000);

	}
