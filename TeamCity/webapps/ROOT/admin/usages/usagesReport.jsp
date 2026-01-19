<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<%@ include file="/include-internal.jsp" %>
<style type="text/css">
  .usagesSection {
    margin-top: 20px;
  }
  .readOnlyNote {
    display: none;
  }
</style>

<div class="section noMargin">
  <ext:includeExtensions placeId="<%=PlaceId.ADMIN_USAGES_FRAGMENT%>"/>
</div>
