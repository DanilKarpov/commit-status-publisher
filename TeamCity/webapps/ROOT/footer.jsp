<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<%@ include file="include-internal.jsp"%>
<c:if test="${!param.embedded}">
  <ext:includeExtensions placeId="<%=PlaceId.ALL_PAGES_FOOTER%>"/>
  <div id="react-ui-version"></div>
  <script>
    ReactUI.renderConnected(document.getElementById('react-ui-version'), ReactUI.Version);
  </script>
</c:if>
<div class="hidden">
  <ext:includeExtensions placeId="<%=PlaceId.ALL_PAGES_FOOTER_PLUGIN_CONTAINER%>"/>
</div>

