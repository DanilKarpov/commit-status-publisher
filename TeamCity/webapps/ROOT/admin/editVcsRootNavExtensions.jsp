<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<%@ include file="/include-internal.jsp" %>
<ext:forEachExtension placeId="<%=PlaceId.ADMIN_EDIT_VCS_ROOT_ACTIONS_PAGE%>">
  <ext:includeExtension extension="${extension}"/>
</ext:forEachExtension>
