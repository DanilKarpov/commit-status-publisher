<%@ page import="jetbrains.buildServer.serverSide.healthStatus.SuggestionCategory" %>
<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<%@
    include file="include-internal.jsp" %><%@
    taglib prefix="admin" tagdir="/WEB-INF/tags/admin"
%><jsp:useBean id="currentUser" type="jetbrains.buildServer.users.User" scope="request"
/><jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject"  scope="request"
/><jsp:useBean id="branchBean" type="jetbrains.buildServer.controllers.BranchBean" scope="request"

/><ext:defineExtensionTab placeId="<%=PlaceId.PROJECT_TAB%>"/>
<%--@elvariable id="contextProject" type="jetbrains.buildServer.serverSide.SProject"--%>
<%--@elvariable id="extensionTab" type="jetbrains.buildServer.web.openapi.CustomTab"--%>
<bs:page disableScrollingRestore="${extensionTab.tabId eq 'projectBuildChains'}">
  <jsp:attribute name="page_title"><c:out value='${project.name}'/> Project</jsp:attribute>
  <jsp:attribute name="quickLinks_include">
    <div class="toolbarItem">
      <jsp:include page="/notificationsInfoController.html"/>
    </div>
    <c:if test="${afn:permissionGrantedForProject(project, 'EDIT_PROJECT') or (afn:adminSpaceAvailable() and afn:permissionGrantedForProject(project, 'VIEW_BUILD_CONFIGURATION_SETTINGS'))}">
      <div class="toolbarItem">
        <admin:editProjectLink projectId="${project.externalId}"
                               title="Edit project settings"
                               addToUrl="&cameFromUrl=${cameFromUrl}"
                               classes="btn btn_mini"
        >${afn:permissionGrantedForProject(project, 'EDIT_PROJECT') && !project.readOnly ? 'Edit' : 'View'} Project Settings</admin:editProjectLink>
      </div>
    </c:if>
    <bs:openInSakuraUI project="${project}" />
  </jsp:attribute>
  <jsp:attribute name="head_include">
    <bs:redirectToSakuraUI project="${project}" />
    <bs:sakuraReleaseBanner project="${project}" />

    <bs:linkCSS>
      /css/settingsTable.css
      /css/progress.css
      /css/overviewTable.css
      /css/overview.css
      /css/filePopup.css
      /css/buildQueue.css
      /css/agentsInfoPopup.css
      /css/pager.css
      /css/project.css
      /css/visibleProjects.css
      /healthStatus/css/healthStatus.css
    </bs:linkCSS>

    <style type="text/css">
      .projectContent {
        margin-top: 10px;
      }

      .projectContent .logTable {
        padding: 0;
      }
    </style>

    <bs:linkScript>
      /js/bs/blocks.js
      /js/bs/blockWithHandle.js

      /js/bs/overview.js
      /js/bs/runningBuilds.js
      /js/bs/testGroup.js

      /js/bs/systemProblemsMonitor.js
      /js/bs/collapseExpand.js
      /js/bs/visibleDialog.js
      /js/bs/queueLikeSorter.js
      /js/bs/buildQueue.js
      /js/bs/overflower.js
      /js/bs/buildType.js
      /js/bs/problemsSummary.js
      /js/bs/restProjectsPopup.js
    </bs:linkScript>
    <c:if test="${not empty project.description}">
      <c:set var="projectDescription"><bs:out value="${project.description}" /></c:set>
      <c:set var="projectDescription">(<bs:escapeForJs text="${projectDescription}" forHTMLAttribute="false"/>)</c:set>
    </c:if>

    <script type="text/javascript">
      <bs:trimWhitespace>
        BS.Navigation.items = [];

        <c:forEach var="p" items="${project.projectPath}" varStatus="status">
        <c:if test="${not status.first}">
          BS.Navigation.items.push({
            title: "<bs:escapeForJs text="${p.name}" forHTMLAttribute="true"/> <small>${status.last ? projectDescription : ''}</small>",
            url: BS.Navigation.fromUrl("${project.externalId}", "${p.externalId}", "&projectId=${p.externalId}", ${status.last}),
            selected: ${status.last ? 'true' : 'false'},
            itemClass: "project",
            projectId: "${p.externalId}",
            siblingsTree: {
              parentId: "${p.parentProjectExternalId}",
              projectUrlFormat: BS.Navigation.fromUrl("${project.externalId}")
            }
          });
        </c:if>
        </c:forEach>
        <c:if test="${project.rootProject}">
          BS.Navigation.items.push({
            title: "<c:out value="${project.name}"/> <small>${projectDescription}</small>",
            url: "project.html?projectId=${project.externalId}",
            selected: true,
            itemClass: "project",
            projectId: "${project.externalId}"
          });
        </c:if>

        $j(document).ready(function() {
          BS.SystemProblems.setOptions({projectId:'${project.externalId}'});
          BS.SystemProblems.startUpdates();
        });

        <c:if test="${!isSpecialUser && !project.rootProject && !project.archived}">
          <authz:authorize allPermissions="CHANGE_OWN_PROFILE">
            $j(document).on("bs.navigationRendered", function() {
              BS.Projects.installShowHideLink(${isProjectPresentOnOverview ? 1 : 0}, "${project.projectId}");
            });
          </authz:authorize>
        </c:if>

        BS.Projects._projectUpdateUrl = '/project.html'; //see overview.js
      </bs:trimWhitespace>
     </script>
    <bs:_projectBranchSelector branchBean="${branchBean}" project="${project}" tab="${extensionTab.tabId}"/>
  </jsp:attribute>
  <jsp:attribute name="toolbar_include">
    <div class="healthItemIndicatorContainer">
      <bs:changeRequest key="project" value="${project}">
        <bs:changeRequest key="excludeCategoryId" value="<%=SuggestionCategory.CATEGORY_ID%>">
          <jsp:include page="/projectHealthStatusItems.html">
            <jsp:param name="originUrl" value="${pageUrl}"/>
          </jsp:include>
        </bs:changeRequest>
      </bs:changeRequest>
    </div>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <et:subscribeOnProjectEvents projectId="${project.projectId}">
      <jsp:attribute name="eventNames">
        PROJECT_REMOVED
        PROJECT_ARCHIVED
        PROJECT_DEARCHIVED
      </jsp:attribute>
      <jsp:attribute name="eventHandler">
        BS.reload();
      </jsp:attribute>
    </et:subscribeOnProjectEvents>
    <bs:refreshable containerId="projectContainer" pageUrl="${pageUrl}"> <!-- required by investigation.js -->
      <bs:projectArchived project="${project}"/>
      <div class="projectContent">
        <ext:showTabs placeId="<%=PlaceId.PROJECT_TAB%>" urlPrefix="/project.html?projectId=${project.externalId}"/>
      </div>
    </bs:refreshable>
  </jsp:attribute>
</bs:page>
