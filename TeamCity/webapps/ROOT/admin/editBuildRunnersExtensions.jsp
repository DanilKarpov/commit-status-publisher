<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="buildTypeForm" scope="request" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm"/>
<!-- include PlaceId.ADMIN_EDIT_BUILD_STEPS_ACTIIONS_PAGE -->
<bs:changeRequest key="buildTypeForm" value="${buildTypeForm}">
  <ext:includeExtensions placeId="<%=PlaceId.ADMIN_EDIT_BUILD_STEPS_ACTIONS_PAGE%>">
    <jsp:attribute name="beforeExtensionContent"><div class="shift"></div></jsp:attribute>
  </ext:includeExtensions>
</bs:changeRequest>
<!-- end of include PlaceId.ADMIN_EDIT_BUILD_STEPS_ACTIIONS_PAGE -->