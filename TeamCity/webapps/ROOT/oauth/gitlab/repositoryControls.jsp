<%@ page import="jetbrains.buildServer.serverSide.oauth.gitlab.GitLabComOAuthProvider" %>
<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="afn" uri="/WEB-INF/functions/authz" %>
<%@ taglib prefix="util" uri="/WEB-INF/functions/util" %>
<%@ taglib prefix="intprop" uri="/WEB-INF/functions/intprop"%>
<jsp:useBean id="gitlabConnections" scope="request" type="java.util.Map"/>
<jsp:useBean id="project" scope="request" type="jetbrains.buildServer.serverSide.SProject"/>
<jsp:useBean id="showMode" scope="request" type="java.lang.String"/>
<c:set var="createPrefix" value="${showMode == 'createProjectMenu' ? 'Create project' : 'Create build configuration'}"/>
<style type="text/css">
  .gitlabRepoControl {
    padding-left: 0.25em;
    white-space: nowrap;
  }

  .tc-icon_gitlab{
    cursor: pointer;
  }

  .tc-icon_gitlab-enterprise{
    cursor: pointer;
  }

  a > .tc-icon_gitlab_disabled {
    text-decoration: none;
  }
</style>
<c:url value="/oauth/gitlab/repositories.html" var="repositoriesPage"/>
<c:set var="cameFromUrl" value="${empty param['cameFromUrl'] ? pageUrl : param['cameFromUrl']}"/>
<c:set var="repositoriesPage" value="${repositoriesPage}?cameFromUrl=${util:urlEscape(cameFromUrl)}"/>
<script type="text/javascript">
  BS.GitLabRepositoriesPopup = new BS.Popup('gitlabRepositories', {
    url: "${repositoriesPage}",
    method: "get",
    hideDelay: 0,
    hideOnMouseOut: false,
    hideOnMouseClickOutside: true
  });

  BS.GitLabRepositoriesPopup.showPopup = function (nearestElement, connectionId) {
    this.options.parameters = "projectId=${project.externalId}&connectionId=" + connectionId + "&showMode=popup";
    var that = this;

    window.GitLabRepositoriesContentUpdater = function () {
      that.hidePopup(0);
      that.showPopupNearElement(nearestElement);
    };
    this.showPopupNearElement(nearestElement);
  };
</script>

<c:set var="connectionType" value="<%=GitLabComOAuthProvider.TYPE%>"/>
<c:url var="oauthConnectionsUrl" value="/admin/editProject.html?projectId=${project.externalId}&tab=oauthConnections"/>
<c:choose>
  <c:when test="${showMode == 'popup'}">
    <c:forEach items="${gitlabConnections}" var="entry">
      <c:set value="${entry.key}" var="connection"/>
      <c:set var="title">Pick repository from GitLab Connection (<c:out value="${connection.description}"/>)</c:set>
      <span class="gitlabRepoControl"><i class="tc-icon icon16 tc-icon_gitlab${connection.oauthProvider.type == 'GitLabCEorEE' ? '-enterprise' : ''}" title="${title}" onclick="BS.GitLabRepositoriesPopup.showPopup(this, '${connection.id}')"></i></span>
    </c:forEach>
    <c:if test="${fn:length(gitlabConnections) == 0 and afn:permissionGrantedForProject(project, 'EDIT_PROJECT')}">
      <span class="gitlabRepoControl"><a href="${oauthConnectionsUrl}#addDialog=${connectionType}"><i class="tc-icon icon16 tc-icon_gitlab_disabled" title="Click to set up connection to GitLab"></i></a></span>
    </c:if>
  </c:when>
  <c:otherwise>
    <c:forEach items="${gitlabConnections}" var="entry">
      <c:set value="${entry.key}" var="connection"/>
      <c:set value="${entry.value}" var="hasToken" />
      <a href="#gitlab" class="createOption readyToUseOption <c:if test="${hasToken}">preferableOption</c:if>" data-url="${repositoriesPage}&projectId=${project.externalId}&connectionId=${connection.id}&showMode=${util:urlEscape(showMode)}">
        <h3><i class="tc-icon icon16 tc-icon_gitlab${connection.oauthProvider.type == 'GitLabCEorEE' ? '-enterprise' : ''}"></i> From <c:out value="${connection.connectionDisplayName}"/></h3>
        <c:if test="${connection.oauthProvider.type == 'GitLabCEorEE'}">
          <div class="createOption__second-line"><c:out value="${connection.parameters['gitLabUrl']}" /></div>
        </c:if>
      </a>
    </c:forEach>
  </c:otherwise>
</c:choose>


