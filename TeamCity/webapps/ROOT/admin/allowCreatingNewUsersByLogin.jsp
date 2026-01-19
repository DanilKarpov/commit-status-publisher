<%@ include file="/include-internal.jsp"
%><%@ taglib prefix="prop" tagdir="/WEB-INF/tags/props"
%><prop:checkboxProperty name="allowCreatingNewUsersByLogin" uncheckedValue="false"
/><label width="100%" for="allowCreatingNewUsersByLogin">Allow creating new users on the first login</label
><%--@elvariable id="serverSummary" type="jetbrains.buildServer.web.openapi.ServerSummary"--%>
<c:if test="${serverSummary.perProjectPermissionsEnabled}"><br/><span class="grayNote">Note: You can
  <a href="<c:url value='/admin/editGroup.html?groupCode=ALL_USERS_GROUP&tab=groupRoles'/>" class="external">configure the default roles</a>
  assigned to the newly registered users.</span></c:if>