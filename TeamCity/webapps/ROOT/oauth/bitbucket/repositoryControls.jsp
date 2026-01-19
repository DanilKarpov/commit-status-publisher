<%@ page import="jetbrains.buildServer.serverSide.oauth.bitbucket.BitBucketOAuthProvider" %>
<%@ include file="/include-internal.jsp"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="afn" uri="/WEB-INF/functions/authz" %>
<%@ taglib prefix="util" uri="/WEB-INF/functions/util" %>
<%@ taglib prefix="intprop" uri="/WEB-INF/functions/intprop"%>
<jsp:useBean id="connections" scope="request" type="java.util.Map"/>
<jsp:useBean id="project" scope="request" type="jetbrains.buildServer.serverSide.SProject"/>
<c:set var="createPrefix" value="${showMode == 'createProjectMenu' ? 'Create project' : 'Create build configuration'}"/>
<style type="text/css">
  .bitbucketRepoControl {
    padding-left: 0.25em;
  }

  .tc-icon_bitbucket {
    cursor: pointer;
  }

  a > .tc-icon_bitbucket_disabled {
    text-decoration: none;
  }
</style>
<c:url value="/oauth/bitbucket/repositories.html" var="repositoriesPage"/>
<c:set var="cameFromUrl" value="${empty param['cameFromUrl'] ? pageUrl : param['cameFromUrl']}"/>
<c:set var="repositoriesPage" value="${repositoriesPage}?cameFromUrl=${util:urlEscape(cameFromUrl)}"/>
<script type="text/javascript">
  BS.BitBucketRepositoriesPopup = new BS.Popup('bitbucketRepositories', {
    url: "${repositoriesPage}",
    method: "get",
    hideDelay: 0,
    hideOnMouseOut: false,
    hideOnMouseClickOutside: true
  });

  BS.BitBucketRepositoriesPopup.showPopup = function(nearestElement, connectionId, vcsType) {
    this.options.parameters = "projectId=${project.externalId}&connectionId=" + connectionId + "&vcsType=" + vcsType + "&showMode=popup";
    var that = this;

    window.BitBucketRepositoriesContentUpdater = function() {
      that.hidePopup(0);
      that.showPopupNearElement(nearestElement);
    };
    this.showPopupNearElement(nearestElement);
  };
</script>

<c:set var="vcsType" value="${vcsType == null ? '' : vcsType}"/>
<c:set var="connectionType" value="<%=BitBucketOAuthProvider.TYPE%>"/>
<c:url var="oauthConnectionsUrl" value="/admin/editProject.html?projectId=${project.externalId}&tab=oauthConnections"/>
<c:choose>
  <c:when test="${showMode == 'popup'}">
  <c:forEach items="${connections}" var="entry">
    <c:set value="${entry.key}" var="connection"/>
    <c:set var="title">Pick repository from <c:out value="${connection.connectionDisplayName}"/></c:set>
    <span class="bitbucketRepoControl"><i class="tc-icon icon16 tc-icon_bitbucket" title="${title}" onclick="BS.BitBucketRepositoriesPopup.showPopup(this, '${connection.id}', '${vcsType}')"></i></span>
  </c:forEach>
  <c:if test="${fn:length(connections) == 0 and afn:permissionGrantedForProject(project, 'EDIT_PROJECT')}">
    <span class="bitbucketRepoControl"><a href="${oauthConnectionsUrl}#addDialog=${connectionType}"><i class="tc-icon icon16 tc-icon_bitbucket_disabled" title="Click to set up connection to Bitbucket Cloud"></i></a></span>
  </c:if>
  </c:when>
  <c:otherwise>

    <c:forEach items="${connections}" var="entry">
      <c:set value="${entry.key}" var="connection"/>
      <a href="#bitbucket" class="createOption readyToUseOption <c:if test="${entry.value}">preferableOption</c:if>" data-url="${repositoriesPage}&projectId=${project.externalId}&connectionId=${connection.id}&showMode=${util:urlEscape(showMode)}">
        <h3><i class="tc-icon icon16 tc-icon_bitbucket"></i> From <c:out value="${connection.oauthProvider.displayName}"/></h3>
        <c:if test="${fn:length(connections) > 1 && connection.connectionDisplayName != connection.oauthProvider.displayName}">
          <div class="createOption__second-line"><c:out value="${connection.connectionDisplayName}"/></div>
        </c:if>
      </a>
    </c:forEach>
  </c:otherwise>
</c:choose>
