<%@ page import="jetbrains.buildServer.serverSide.oauth.azuredevops.AzureDevOpsOAuthProvider" %>
<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="afn" uri="/WEB-INF/functions/authz" %>
<%@ taglib prefix="util" uri="/WEB-INF/functions/util" %>
<%@ taglib prefix="intprop" uri="/WEB-INF/functions/intprop"%>
<jsp:useBean id="azureConnections" scope="request" type="java.util.Map"/>
<jsp:useBean id="project" scope="request" type="jetbrains.buildServer.serverSide.SProject"/>
<jsp:useBean id="showMode" scope="request" type="java.lang.String"/>
<c:set var="createPrefix" value="${showMode == 'createProjectMenu' ? 'Create project' : 'Create build configuration'}"/>
<style type="text/css">
  .azureDevOpsRepoControl {
    padding-left: 0.25em;
    white-space: nowrap;
  }

  .tc-icon_azureDevOps {
    background-image: url('../img/icons/azure-devops.svg');
    background-size: 100% 100%;
    cursor: pointer;
    padding-bottom: 2px;
  }

  .tc-icon_azureDevOps_disabled {
    filter: grayscale(1) contrast(0.1) brightness(1.84);
    text-decoration: none;
  }
</style>
<c:url value="/oauth/azuredevops/repositories.html" var="repositoriesPage"/>
<c:set var="cameFromUrl" value="${empty param['cameFromUrl'] ? pageUrl : param['cameFromUrl']}"/>
<c:set var="repositoriesPage" value="${repositoriesPage}?cameFromUrl=${util:urlEscape(cameFromUrl)}"/>
<script type="text/javascript">
  BS.AzureDevOpsRepositoriesPopup = new BS.Popup('azureRepositories', {
    url: "${repositoriesPage}",
    method: "get",
    hideDelay: 0,
    hideOnMouseOut: false,
    hideOnMouseClickOutside: true
  });

  BS.AzureDevOpsRepositoriesPopup.showPopup = function (nearestElement, connectionId) {
    this.options.parameters = "projectId=${project.externalId}&connectionId=" + connectionId + "&showMode=popup";
    var that = this;

    window.AzureDevOpsRepositoriesContentUpdater = function () {
      that.hidePopup(0);
      that.showPopupNearElement(nearestElement);
    };
    this.showPopupNearElement(nearestElement);
  };
</script>

<c:set var="connectionType" value="<%=AzureDevOpsOAuthProvider.TYPE%>"/>
<c:set var="connectionName" value="<%=AzureDevOpsOAuthProvider.DISPLAY_NAME%>"/>
<c:url var="oauthConnectionsUrl" value="/admin/editProject.html?projectId=${project.externalId}&tab=oauthConnections"/>
<c:choose>
  <c:when test="${showMode == 'popup'}">
    <c:forEach items="${azureConnections}" var="entry">
      <c:set value="${entry.key}" var="connection"/>
      <c:set value="${entry.value}" var="parameters"/>
      <c:set var="title">Pick repository from <c:out value="${parameters['description']}"/></c:set>
      <span class="azureDevOpsRepoControl"><i class="tc-icon icon16 tc-icon_azureDevOps" title="${title}" onclick="BS.AzureDevOpsRepositoriesPopup.showPopup(this, '${connection.id}')"></i></span>
    </c:forEach>
    <c:if test="${fn:length(azureConnections) == 0 and afn:permissionGrantedForProject(project, 'EDIT_PROJECT')}">
      <span class="azureDevOpsRepoControl"><a href="${oauthConnectionsUrl}#addDialog=${connectionType}"><i class="tc-icon icon16 tc-icon_azureDevOps tc-icon_azureDevOps_disabled" title="Click to set up connection to ${connectionName}"></i></a></span>
    </c:if>
  </c:when>
  <c:otherwise>
    <c:forEach items="${azureConnections}" var="entry">
      <c:set value="${entry.key}" var="connection"/>
      <c:set value="${entry.value}" var="parameters"/>
      <a href="#azureDevOps" class="createOption readyToUseOption <c:if test="${parameters['hasToken']}">preferableOption</c:if>" data-url="${repositoriesPage}&projectId=${project.externalId}&connectionId=${connection.id}&showMode=${util:urlEscape(showMode)}">
        <h3><i class="tc-icon icon16 tc-icon_azureDevOps"></i> From <c:out value="${connection.connectionDisplayName}"/></h3>
        <div class="createOption__second-line"><c:out value="${parameters['description']}"/></div>
      </a>
    </c:forEach>
  </c:otherwise>
</c:choose>


