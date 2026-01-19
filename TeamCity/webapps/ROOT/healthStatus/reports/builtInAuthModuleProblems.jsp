<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<c:if test="${healthStatusItem.category.id == 'freeRegistrationDisabled'}">
  This server allowed new user registration from the login page.
  Such setup may be insecure, especially if the server is accessible from the Internet.

  <br/>

  During the upgrade, new user registration has been disabled.
  If you want to re-enable it, use  the <strong>Built-in</strong> authentication module settings on the <a href="<c:url value='/admin/admin.html?item=auth'/>">Authentication page</a>.

  <c:url var="confirmDisablingUrl" value="/admin/action.html"/>
  <div style="margin-top: .5em;">
    <input type="button" class="btn btn_mini" value="Leave it disabled" onclick="BS.ajaxRequest('${confirmDisablingUrl}', { method: 'post', parameters: 'freeRegistrationDisablingConfirmed=true', onComplete: function() { BS.reload(true); } }); return false;">
  </div>
</c:if>
