<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="project" scope="request" type="jetbrains.buildServer.serverSide.SProject"/>
<ext:forEachExtension placeId="<%=PlaceId.ADMIN_EDIT_PROJECT_ACTIONS_PAGE%>">
  <ext:includeExtension extension="${extension}"/>
</ext:forEachExtension>
