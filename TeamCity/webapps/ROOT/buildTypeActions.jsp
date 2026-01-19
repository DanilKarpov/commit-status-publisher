<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<%@ include file="include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<%@ taglib prefix="resp" tagdir="/WEB-INF/tags/responsible" %>
<%@ taglib prefix="tags" tagdir="/WEB-INF/tags/tags" %>
<%@ taglib prefix="responsible" uri="/WEB-INF/functions/resp" %>

<jsp:useBean id="buildType" type="jetbrains.buildServer.serverSide.BuildTypeEx" scope="request"/>
<jsp:useBean id="pinnedBuild" type="jetbrains.buildServer.controllers.buildType.BuildTypeController.PinnedBuildBean" scope="request"/>
<jsp:useBean id="currentUser" type="jetbrains.buildServer.users.User" scope="request"/>
<jsp:useBean id="branchBean" type="jetbrains.buildServer.controllers.BuildTypeBranchBean" scope="request"/>
<c:set var="fullname" value="${buildType.fullName}"
/><ext:defineExtensionTab placeId="<%=PlaceId.BUILD_CONF_TAB%>"/>
<%--@elvariable id="extensionTab" type="jetbrains.buildServer.web.openapi.CustomTab"--%>
<c:set var='currentTabTitle' value=" > ${extensionTab.tabTitle}"
/><c:set var="pageTitle" value="${fullname}${currentTabTitle}" scope="request"
/><c:set var="projectId" value="${buildType.projectId}"
/>
<authz:authorize projectId="${projectId}" allPermissions="PAUSE_ACTIVATE_BUILD_CONFIGURATION">
  <c:if test="${buildType.paused and not buildType.project.archived and not buildType.readOnly}">
    <l:li>
      <a href="#" onclick="<bs:_pauseBuildTypeLinkOnClick buildType="${buildType}" pause="false" noReload="${not empty param.actionsOnly}"/>">
        Activate...
      </a>
    </l:li>
  </c:if>
  <c:if test="${not buildType.paused and not buildType.readOnly}">
    <l:li>
      <a href="#" onclick="<bs:_pauseBuildTypeLinkOnClick buildType="${buildType}" pause="true" noReload="${not empty param.actionsOnly}"/>">
        Pause...
      </a>
    </l:li>
  </c:if>
</authz:authorize>
<authz:authorize projectId="${projectId}" allPermissions="RUN_BUILD">
  <l:li>
    <a href="#" onclick="event.stopPropagation(); event.preventDefault(); return fetch('<c:url value='/action.html'/>', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded'
          },
          body: 'checkForChangesBuildType=${buildType.buildTypeId}&tc-csrf-token=${sessionScope['tc-csrf-token']}'
        }).then(function(response) {
          if (${empty param.actionsOnly}) {
            location.reload();
          }
        })">Check for pending changes</a>
  </l:li>
</authz:authorize>
<c:if test="${afn:permissionGrantedForBuildType(buildType, 'CLEAN_BUILD_CONFIGURATION_SOURCES') or
                              afn:permissionGrantedGlobally('CLEAN_AGENT_SOURCES')}">
  <bs:buildTypeResetSourcesDialog buildType="${buildType}"/>
  <l:li>
    <a href="#" onclick="event.stopPropagation(); event.preventDefault(); return BS.BuildTypeResetSources.showResetSourcesDialog(${not empty param.actionsOnly})">Enforce clean checkout...</a>
  </l:li>
</c:if>

<l:li>
  <div id="build-type-investigation-history-popup-${buildType.externalId}"></div>
  <a onclick="ReactUI.showBuildTypeInvestigationHistoryPopup(document.getElementById('build-type-investigation-history-popup-${buildType.externalId}'), '${buildType.externalId}', '${buildType.projectId}')" href="#">Investigation History</a>
</l:li>

<authz:authorize projectId="${projectId}" allPermissions="ASSIGN_INVESTIGATION">
  <c:set var="name"><bs:escapeForJs text="${buildType.name}" forHTMLAttribute="true"/></c:set>
  <l:li>
    <a href="#" class="assignInvestigationAction" onclick="return BS.ResponsibilityDialog.showDialog('${buildType.externalId}', '${name}', false, ${not empty param.actionsOnly})">Assign investigation...</a>
  </l:li>
  <c:set var="responsibility" value="${buildType.responsibilityInfo}"/>
  <c:set var="hasResponsible" value="${not empty responsibility and responsible:hasResponsible(responsibility)}"/>
  <c:set var="investigatedByCurrentUser" value="${hasResponsible and responsibility.responsibleUser == currentUser}"/>
  <c:if test="${investigatedByCurrentUser}">
    <l:li>
      <a href="#" onclick="return BS.ResponsibilityDialog.showDialog('${buildType.externalId}', '${name}', true, ${not empty param.actionsOnly})">Mark as fixed...</a>
    </l:li>
  </c:if>
</authz:authorize>

<l:li>
  <div id="build-status-widget-popup-${buildType.externalId}"></div>
  <a href="#" onclick="ReactUI.showBuildStatusWidgetPopup(
      document.getElementById('build-status-widget-popup-${buildType.externalId}'),
      '${buildType.externalId}',
      '${buildType.internalId}',
      BS.Branch != null ? BS.Branch.parseBranch('<bs:escapeForJs text="${branchBean.userBranch}"/>') : null
  )">Get build status icon...</a>
</l:li>

<ext:includeExtensions placeId="<%=PlaceId.BUILD_CONF_ACTIONS%>"/>
