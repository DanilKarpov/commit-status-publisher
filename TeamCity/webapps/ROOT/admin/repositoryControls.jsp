<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<%@ include file="/include-internal.jsp"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<jsp:useBean id="project" scope="request" type="jetbrains.buildServer.serverSide.SProject"/>
<script type="text/javascript">
  BS.Repositories = {
    installControls: function(elem, callbackFunc) {
      if (!elem) {
        alert("Element where to install oauth controls is not specified");
        return;
      }
      var controls = $j('.listRepositoriesControls').detach();
      controls.insertAfter($j(elem));
      window.repositoryCallback = callbackFunc;
    }
  };
</script>

<c:set var="pluginName" value="${param['pluginName']}"/>
<c:set var="vcsType" value="${param['vcsType']}" scope="request"/>
<c:set var="showMode" value="popup" scope="request"/>
<div style="display:none">
  <ext:forEachExtension placeId="<%=PlaceId.ADMIN_LIST_REPOSITORIES%>">
    <c:if test="${empty pluginName or pluginName == extension.pluginName}">
      <span class="listRepositoriesControls"><ext:includeExtension extension="${extension}"/></span>
    </c:if>
  </ext:forEachExtension>
</div>
