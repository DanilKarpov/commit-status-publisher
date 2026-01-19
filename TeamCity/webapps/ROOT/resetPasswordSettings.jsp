<%@ page import="jetbrains.buildServer.serverSide.impl.auth.DefaultLoginModuleConstants" %>
<%@ page import="jetbrains.buildServer.resetPassword.ResetPasswordSettings" %>
<%@ include file="/include-internal.jsp"%>
<%@ taglib prefix="prop" tagdir="/WEB-INF/tags/props" %>

<script type="application/javascript">
  var changeCheckboxState = function() {
    if ($("<%=DefaultLoginModuleConstants.USERS_CAN_CHANGE_OWN_PASSWORDS_KEY%>").checked)   {
      $('<%=ResetPasswordSettings.USERS_CAN_RESET_OWN_PASSWORDS_KEY%>').enable();
      $j('#resetPassDisableWarn').hide();
    } else {
      $('<%=ResetPasswordSettings.USERS_CAN_RESET_OWN_PASSWORDS_KEY%>').disable();
      $j('#resetPassDisableWarn').show();
      $('<%=ResetPasswordSettings.USERS_CAN_RESET_OWN_PASSWORDS_KEY%>').checked = false;
    }
  };
  $("<%=DefaultLoginModuleConstants.USERS_CAN_CHANGE_OWN_PASSWORDS_KEY%>").on('click', changeCheckboxState);
  changeCheckboxState();
</script>
<div style="margin-left: 1.5em; margin-top: 0.5em;">
  <prop:checkboxProperty name="<%=ResetPasswordSettings.USERS_CAN_RESET_OWN_PASSWORDS_KEY%>" uncheckedValue="false"/>
  <label width="100%" for="<%=ResetPasswordSettings.USERS_CAN_RESET_OWN_PASSWORDS_KEY%>">Allow users to reset forgotten passwords on the login page</label>
  <div id="resetPassDisableWarn" width="100%" class="grayNote" style="display: none;">Reset password can't be enabled when users are not allowed to change their passwords</div>
</div>
