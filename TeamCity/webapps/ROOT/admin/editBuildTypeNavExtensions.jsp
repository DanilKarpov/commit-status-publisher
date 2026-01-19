<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="buildTypeForm" scope="request" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm"/>
<!-- include PlaceId.ADMIN_EDIT_BUILD_TYPE_ACTIIONS_PAGE -->
<bs:changeRequest key="buildTypeForm" value="${buildTypeForm}">
  <ext:includeExtensions placeId="<%=PlaceId.ADMIN_EDIT_BUILD_TYPE_ACTIONS_PAGE%>">
    <jsp:attribute name="beforeExtensionContent"><li class="menuItem"></jsp:attribute>
    <jsp:attribute name="afterExtensionContent"></li></jsp:attribute>
  </ext:includeExtensions>
</bs:changeRequest>
<!-- end of include PlaceId.ADMIN_EDIT_BUILD_TYPE_ACTIIONS_PAGE -->