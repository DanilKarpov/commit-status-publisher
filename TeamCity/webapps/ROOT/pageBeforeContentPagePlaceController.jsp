<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<%@ page import="jetbrains.buildServer.web.util.WebUtil" %>
<%@ include file="include-internal.jsp"%>

<c:set var="overview" value="<%=WebUtil.sakuraUIOpened(request)%>" />

<c:if test="${overview != true}">
  <ext:includeExtensions placeId="<%=PlaceId.BEFORE_CONTENT%>" includeReactExtensions="true" />
  <!-- end of include PlaceId.BEFORE_CONTENT -->
</c:if>
