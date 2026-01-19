<%@ include file="/include-internal.jsp" %><%@
    page import="jetbrains.buildServer.web.openapi.PlaceId" %><%@
    taglib prefix="resp" tagdir="/WEB-INF/tags/responsible" %><%@
    taglib prefix="authz" tagdir="/WEB-INF/tags/authz" %><%@
    taglib prefix="ext" tagdir="/WEB-INF/tags/ext"
%><ext:includeExtensions placeId="<%=PlaceId.PROJECT_FRAGMENT%>" includeReactExtensions="true"
/>
<div id="builds"></div>
<script>
  ReactUI.renderProjectHistory('builds');
</script>
