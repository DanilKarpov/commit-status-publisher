<%@ page import="jetbrains.buildServer.serverSide.impl.auth.DefaultLoginModuleConstants" %>
<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="prop" tagdir="/WEB-INF/tags/props" %>
<%--@elvariable id="type" type="jetbrains.buildServer.serverSide.impl.auth.DefaultLoginModuleDescriptor"--%>
<div>
  <prop:checkboxProperty name="<%=DefaultLoginModuleConstants.FREE_REGISTRATION_ALLOWED_KEY%>" uncheckedValue="false"/>
  <label width="100%" for="<%=DefaultLoginModuleConstants.FREE_REGISTRATION_ALLOWED_KEY%>">Allow user registration from the login page</label>
  <%--@elvariable id="serverSummary" type="jetbrains.buildServer.web.openapi.ServerSummary"--%>
  <c:if test="${serverSummary.perProjectPermissionsEnabled}">
  <authz:authorize anyPermission="CHANGE_USER_ROLES_IN_PROJECT">
    <bs:smallNote>Note: You can
      <a href="<c:url value='/admin/editGroup.html?groupCode=ALL_USERS_GROUP&tab=groupRoles'/>" class="external">configure the default roles</a>
      assigned to the newly registered users.
    </bs:smallNote>
  </authz:authorize>
  </c:if>
</div>
<br/>
<div>
  <prop:checkboxProperty name="<%=DefaultLoginModuleConstants.USERS_CAN_CHANGE_OWN_PASSWORDS_KEY%>" uncheckedValue="false"/>
  <label width="100%" for="<%=DefaultLoginModuleConstants.USERS_CAN_CHANGE_OWN_PASSWORDS_KEY%>">Allow users to change their passwords on the profile page</label>
  <bs:smallNote>Note: Administrators are always able to change the password of any user.</bs:smallNote>
</div>
<c:forEach var="extension" items="${type.extensionParameters}">
  <jsp:include page="${extension.jspPath}"/>
</c:forEach>