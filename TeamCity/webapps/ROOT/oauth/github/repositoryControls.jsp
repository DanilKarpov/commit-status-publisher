<%@ page import="jetbrains.buildServer.serverSide.oauth.github.GitHubOAuthProvider" %>
<%@ include file="/include-internal.jsp"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="afn" uri="/WEB-INF/functions/authz" %>
<%@ taglib prefix="util" uri="/WEB-INF/functions/util" %>
<%@ taglib prefix="intprop" uri="/WEB-INF/functions/intprop"%>
<jsp:useBean id="githubConnections" scope="request" type="java.util.Map"/>
<jsp:useBean id="project" scope="request" type="jetbrains.buildServer.serverSide.SProject"/>
<jsp:useBean id="showMode" scope="request" type="java.lang.String"/>
<c:set var="createPrefix" value="${showMode == 'createProjectMenu' ? 'Create project' : 'Create build configuration'}"/>
<style type="text/css">
  .githubRepoControl {
    padding-left: 0.25em;
    white-space: nowrap;
  }

  .tc-icon_github,
  .tc-icon_github-enterprise {
    cursor: pointer;
  }

  a > .tc-icon_github_disabled {
    text-decoration: none;
  }
</style>
<c:url value="/oauth/github/repositories.html" var="repositoriesPage"/>
<c:set var="cameFromUrl" value="${empty param['cameFromUrl'] ? pageUrl : param['cameFromUrl']}"/>
<c:set var="repositoriesPage" value="${repositoriesPage}?cameFromUrl=${util:urlEscape(cameFromUrl)}"/>
<script type="text/javascript">
  BS.GitHubRepositoriesPopup = new BS.Popup('gitHubRepositories', {
    url: "${repositoriesPage}",
    method: "get",
    hideDelay: 0,
    hideOnMouseOut: false,
    hideOnMouseClickOutside: true
  });

  BS.GitHubRepositoriesPopup.showPopup = function(nearestElement, connectionId) {
    this.options.parameters = "projectId=${project.externalId}&connectionId=" + connectionId + "&showMode=popup";
    var that = this;

    window.GitHubRepositoriesContentUpdater = function() {
      that.hidePopup(0);
      that.showPopupNearElement(nearestElement);
    };
    this.showPopupNearElement(nearestElement);
  };
</script>
<c:set var="connectionType" value="<%=GitHubOAuthProvider.TYPE%>"/>
<c:url var="oauthConnectionsUrl" value="/admin/editProject.html?projectId=${project.externalId}&tab=oauthConnections"/>
<c:choose>
  <c:when test="${showMode == 'popup'}">
    <c:forEach items="${githubConnections}" var="entry">
      <c:set var="connection" value="${entry.key}"/>
      <c:set var="title">Pick repository from <c:out value="${connection.parameters['gitHubUrl']}"/> (<c:out value="${connection.connectionDisplayName}"/>)</c:set>
      <span class="githubRepoControl"><i class="tc-icon icon16 tc-icon_github${connection.oauthProvider.type == 'GHE' ? '-enterprise' : ''}" title="${title}" onclick="BS.GitHubRepositoriesPopup.showPopup(this, '${connection.id}')"></i></span>
    </c:forEach>
    <c:if test="${fn:length(githubConnections) == 0 and afn:permissionGrantedForProject(project, 'EDIT_PROJECT')}">
      <span class="githubRepoControl"><a href="${oauthConnectionsUrl}#addDialog=${connectionType}"><i class="tc-icon icon16 tc-icon_github_disabled" title="Click to set up connection to GitHub"></i></a></span>
    </c:if>
  </c:when>
  <c:otherwise>
    <c:forEach items="${githubConnections}" var="entry">
    <c:set var="connection" value="${entry.key}"/>
    <a href="#github" class="createOption readyToUseOption <c:if test="${entry.value}">preferableOption</c:if> ${connection.oauthProvider.type == 'GHE' ? 'wide' : ''}" data-url="${repositoriesPage}&projectId=${project.externalId}&connectionId=${connection.id}&showMode=${util:urlEscape(showMode)}">
      <h3><i class="tc-icon icon16 tc-icon_github${connection.oauthProvider.type == 'GHE' ? '-enterprise' : ''}"></i> From <c:out value="${connection.oauthProvider.displayName}"/></h3>
      <c:if test="${connection.oauthProvider.type == 'GitHub'}">
        <div class="createOption__second-line"><c:out value="${connection.connectionDisplayName}"/></div>
      </c:if>
      <c:if test="${connection.oauthProvider.type == 'GHE'}">
        <div class="createOption__second-line"><c:out value="${connection.parameters['gitHubUrl']}"/></div>
      </c:if>
    </a>
    </c:forEach>
  </c:otherwise>
</c:choose>
