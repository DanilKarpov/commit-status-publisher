<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %><%@
    include file="/include-internal.jsp" %><%@
    taglib prefix="ext" tagdir="/WEB-INF/tags/ext"
%><c:choose
  ><c:when test="${showTabs}"
    ><ext:showTabs placeId="<%=PlaceId.ADMIN_USER_MANAGEMENT_TAB%>"
                   urlPrefix="/admin/admin.html?item=users"
                   tabContainerId="tabsContainer4"
    /></c:when
  ><c:otherwise
    ><ext:includeExtension extension="${extensionTab}"/></c:otherwise
></c:choose>