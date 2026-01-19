<%@ page import="jetbrains.buildServer.controllers.BranchUtil" %><%@
    page import="jetbrains.buildServer.serverSide.healthStatus.SuggestionCategory" %>
<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<%@
    include file="include-internal.jsp" %><%@
    taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %><%@
    taglib prefix="resp" tagdir="/WEB-INF/tags/responsible" %><%@
    taglib prefix="tags" tagdir="/WEB-INF/tags/tags"

%><jsp:useBean id="buildType" type="jetbrains.buildServer.serverSide.BuildTypeEx" scope="request"
/><jsp:useBean id="pinnedBuild" type="jetbrains.buildServer.controllers.buildType.BuildTypeController.PinnedBuildBean" scope="request"
/><jsp:useBean id="currentUser" type="jetbrains.buildServer.users.User" scope="request"
/><jsp:useBean id="branchBean" type="jetbrains.buildServer.controllers.BuildTypeBranchBean" scope="request"

/><c:set var="buildTypeStatus" value="<%=BranchUtil.getStatus(branchBean)%>"
/><ext:defineExtensionTab placeId="<%=PlaceId.BUILD_CONF_TAB%>"/>
<%--@elvariable id="extensionTab" type="jetbrains.buildServer.web.openapi.CustomTab"--%>
<c:set var='currentTabTitle' value=" > ${extensionTab.tabTitle}"
/><c:set var="pageTitle" value="${buildType.name} Configuration${currentTabTitle}" scope="request"
/><c:set var="projectId" value="${buildType.projectId}"
/><bs:page disableScrollingRestore="${extensionTab.tabId eq 'buildTypeChains'}">
  <jsp:attribute name="quickLinks_include">
    <div class="toolbarItem">
      <jsp:include page="/notificationsInfoController.html"/>
    </div>
    <authz:authorize projectId="${projectId}" allPermissions="RUN_BUILD">
      <div class="toolbarItem">
        <bs:runBuild buildType="${buildType}" redirectTo="" hideDeployments="true" branchBean="${branchBean}"/>
      </div>
    </authz:authorize>
    <authz:authorize projectId="${projectId}"
                     anyPermission="PAUSE_ACTIVATE_BUILD_CONFIGURATION, CLEAN_BUILD_CONFIGURATION_SOURCES, RUN_BUILD, ASSIGN_INVESTIGATION">
      <div class="toolbarItem">
        <bs:actionsPopup controlId="bcActions"
                         popup_options="shift: {x: -150, y: 20}, className: 'quickLinksMenuPopup'">
          <jsp:attribute name="content">
            <div id="btDetails">
              <ul class="menuList">
                <jsp:include page="buildTypeActions.jsp"/>
              </ul>
            </div>
          </jsp:attribute>
          <jsp:body>Actions</jsp:body>
        </bs:actionsPopup>
      </div>
    </authz:authorize>
    <c:if test="${afn:permissionGrantedForProject(buildType.project, 'EDIT_PROJECT') or (afn:adminSpaceAvailable() and afn:permissionGrantedForProject(buildType.project, 'VIEW_BUILD_CONFIGURATION_SETTINGS'))}">
      <div class="toolbarItem">
        <admin:editBuildTypeMenu buildType="${buildType}">${afn:permissionGrantedForProject(buildType.project, 'EDIT_PROJECT') && !buildType.project.readOnly ? 'Edit' : 'View'} Configuration Settings</admin:editBuildTypeMenu>
      </div>
    </c:if>
    <bs:openInSakuraUI buildType="${buildType}" />
  </jsp:attribute>
  <jsp:attribute name="head_include">
    <bs:redirectToSakuraUI buildType="${buildType}" />
    <bs:sakuraReleaseBanner buildType="${buildType}" />

    <bs:linkCSS>
      /css/pager.css
      /css/progress.css
      /css/modificationListTable.css
      /css/compatibilityList.css
      /css/buildTypeSettings.css
      /css/filePopup.css
      /css/viewType.css
      /css/overviewTable.css
      /css/buildQueue.css
      /css/historyTable.css
      /css/agentsInfoPopup.css
      /css/buildChains.css
      /healthStatus/css/healthStatus.css
      /css/admin/buildTypeForm.css
    </bs:linkCSS>
    <bs:linkScript>
      /js/bs/blocks.js
      /js/bs/blocksWithHeader.js
      /js/bs/blockWithHandle.js
      /js/bs/changesBlock.js
      /js/bs/collapseExpand.js

      /js/bs/runningBuilds.js

      /js/bs/systemProblemsMonitor.js
      /js/bs/overflower.js
      /js/bs/queueLikeSorter.js
      /js/bs/buildQueue.js
      /js/bs/historyTable.js
      /js/bs/buildType.js
      /js/bs/testGroup.js
    </bs:linkScript>
    <c:if test="${not empty buildType.description}">
      <c:set var="buildTypeDescription"><bs:out value="${buildType.description}" resolverContext="${buildType}" /></c:set>
      <c:set var="buildTypeDescription">(<bs:escapeForJs text="${buildTypeDescription}" forHTMLAttribute="false"/>)</c:set>
    </c:if>

    <script type="text/javascript">
      <bs:trimWhitespace>
        BS.Navigation.items = [];

        <c:forEach var="p" items="${buildType.project.projectPath}" varStatus="status">
          <c:if test="${not status.first}">
            BS.Navigation.items.push({
              title: "<bs:escapeForJs text="${p.name}" forHTMLAttribute="true"/>",
              url: "project.html?projectId=${p.externalId}",
              selected: false,
              itemClass: "project",
              projectId: "${p.externalId}",
              siblingsTree: {
                parentId: "${p.parentProjectExternalId}",
                buildTypeUrlFormat: BS.Navigation.fromUrl("${buildType.externalId}", "{id}")
              }
            });
          </c:if>
        </c:forEach>

        BS.Navigation.items.push({
          title: "<bs:escapeForJs text="${buildType.name}" forHTMLAttribute="true"/><c:if test="${not empty buildTypeDescription}"> <small>${buildTypeDescription}</small></c:if>",
          url: BS.Navigation.fromUrl("${buildType.externalId}", "${buildType.externalId}", null, true),
          selected: true,
          itemClass: "buildType",
          status: "${buildTypeStatus.failed ? 'failed' : buildTypeStatus.successful ? 'successful' : ''}",
          buildTypeId: "${buildType.externalId}",
          composite: ${buildType.compositeBuildType},
          siblingsTree: {
            parentId: "${buildType.projectExternalId}",
            buildTypeUrlFormat: BS.Navigation.fromUrl("${buildType.externalId}", "{id}")
          }
        });
      </bs:trimWhitespace>
    </script>
  </jsp:attribute>
  <jsp:attribute name="toolbar_include">
    <div class="healthItemIndicatorContainer" style="display: none;">
      <c:set var="buildTypeId" scope="request" value="${buildType.buildTypeId}"/>
      <c:set var="excludeCategoryId" scope="request" value="<%=SuggestionCategory.CATEGORY_ID%>"/>
      <jsp:include page="/buildTypeHealthStatusItems.html">
        <jsp:param name="originUrl" value="${pageUrl}"/>
      </jsp:include>
    </div>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <bs:refreshable containerId="buildConfigurationContainer" pageUrl="${pageUrl}">
      <bs:_buildTypeBranchSelector branchBean="${branchBean}" buildType="${buildType}"
                                   wildcardDisplayName="${wildcardBranchDisplayName}"/>
      <script type="text/javascript">
        if (BS.BuildType && BS.BuildType.updateStatus) {
          BS.BuildType.updateStatus(${buildTypeStatus.failed});
        }
      </script>

      <ext:showTabs placeId="<%=PlaceId.BUILD_CONF_TAB%>"
                    urlPrefix="viewType.html?buildTypeId=${buildType.externalId}">
        <div style="padding-top: 3px" id="messagesDiv">
           <bs:messages key="sourcesCleanedMessage"/>
           <bs:messages key="buildHasBeenRemoved"/>
        </div>
        <bs:buildTypePaused buildType="${buildType}" style="margin-top: 6px;"/>
      </ext:showTabs>
    </bs:refreshable>

    <bs:valuePopup buildType="${buildType}"/>

    <authz:authorize projectId="${projectId}" allPermissions="PAUSE_ACTIVATE_BUILD_CONFIGURATION">
      <jsp:attribute name="ifAccessGranted">
        <bs:pauseBuildTypeDialog/>
      </jsp:attribute>
    </authz:authorize>
  </jsp:attribute>
</bs:page>

