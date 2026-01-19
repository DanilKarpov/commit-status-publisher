<%@ page import="jetbrains.buildServer.serverSide.oauth.tfs.TfsAuthProvider" %>
<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="afn" uri="/WEB-INF/functions/authz" %>
<%@ taglib prefix="util" uri="/WEB-INF/functions/util" %>
<%@ taglib prefix="intprop" uri="/WEB-INF/functions/intprop"%>
<jsp:useBean id="tfsConnections" scope="request" type="java.util.Map"/>
<jsp:useBean id="project" scope="request" type="jetbrains.buildServer.serverSide.SProject"/>
<jsp:useBean id="showMode" scope="request" type="java.lang.String"/>
<c:set var="createPrefix" value="${showMode == 'createProjectMenu' ? 'Create project' : 'Create build configuration'}"/>
<style type="text/css">
  .tfsRepoControl {
    padding-left: 0.25em;
    white-space: nowrap;
  }

  .tc-icon_tfs {
    cursor: pointer;
  }

  a > .tc-icon_tfs_disabled {
    text-decoration: none;
  }
</style>
<c:url value="/oauth/tfs/repositories.html" var="repositoriesPage"/>
<c:set var="cameFromUrl" value="${empty param['cameFromUrl'] ? pageUrl : param['cameFromUrl']}"/>
<c:set var="repositoriesPage" value="${repositoriesPage}?cameFromUrl=${util:urlEscape(cameFromUrl)}"/>
<script type="text/javascript">
  BS.TfsRepositoriesPopup = new BS.Popup('tfsRepositories', {
    url: "${repositoriesPage}",
    method: "get",
    hideDelay: 0,
    hideOnMouseOut: false,
    hideOnMouseClickOutside: true
  });

  BS.TfsRepositoriesPopup.showPopup = function (nearestElement, connectionId) {
    this.options.parameters = "projectId=${project.externalId}&connectionId=" + connectionId + "&showMode=popup";
    var that = this;

    window.TfsRepositoriesContentUpdater = function () {
      that.hidePopup(0);
      that.showPopupNearElement(nearestElement);
    };
    this.showPopupNearElement(nearestElement);
  };
</script>

<c:set var="connectionType" value="<%=TfsAuthProvider.TYPE%>"/>
<c:set var="connectionName" value="<%=TfsAuthProvider.DISPLAY_NAME%>"/>
<c:url var="oauthConnectionsUrl" value="/admin/editProject.html?projectId=${project.externalId}&tab=oauthConnections"/>
<c:choose>
  <c:when test="${showMode == 'popup'}">
    <c:forEach items="${tfsConnections}" var="entry">
      <c:set value="${entry.key}" var="connection"/>
      <c:set value="${entry.value}" var="parameters"/>
      <c:set var="title">Pick repository from <c:out value="${parameters['description']}"/></c:set>
      <span class="tfsRepoControl"><i class="tc-icon icon16 tc-icon_tfs" title="${title}" onclick="BS.TfsRepositoriesPopup.showPopup(this, '${connection.id}')"></i></span>
    </c:forEach>
    <c:if test="${fn:length(tfsConnections) == 0 and afn:permissionGrantedForProject(project, 'EDIT_PROJECT')}">
      <span class="tfsRepoControl"><a href="${oauthConnectionsUrl}#addDialog=${connectionType}"><i class="tc-icon icon16 tc-icon_tfs_disabled" title="Click to set up connection to ${connectionName}"></i></a></span>
    </c:if>
  </c:when>
  <c:otherwise>
    <c:forEach items="${tfsConnections}" var="entry">
      <c:set value="${entry.key}" var="connection"/>
      <c:set value="${entry.value}" var="parameters"/>
      <a href="#tfs" class="createOption readyToUseOption <c:if test="${parameters['hasToken']}">preferableOption</c:if>" data-url="${repositoriesPage}&projectId=${project.externalId}&connectionId=${connection.id}&showMode=${util:urlEscape(showMode)}">
        <h3><i class="tc-icon icon16 tc-icon_tfs"></i> From <c:out value="${connection.connectionDisplayName}"/></h3>
        <div class="createOption__second-line"><c:out value="${parameters['description']}"/></div>
      </a>
    </c:forEach>
  </c:otherwise>
</c:choose>


