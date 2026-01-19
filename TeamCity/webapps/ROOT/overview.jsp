<%@ include file="include-internal.jsp"
%><jsp:useBean id="currentUser" type="jetbrains.buildServer.users.User" scope="request"
/><jsp:useBean id="overviewBean" type="jetbrains.buildServer.controllers.overview.OverviewBean" scope="request"
/><jsp:useBean id="serverSummary" type="jetbrains.buildServer.web.openapi.ServerSummary" scope="request"
/><bs:page>
<jsp:attribute name="page_title">Projects</jsp:attribute>
<jsp:attribute name="toolbar_include">
  <c:choose>
    <c:when test="${serverSummary.projectsAvailable()}">
      <div id="toolbar" class="clearfix">
        <div class="toolbar-right">
          <c:if test="${not isSpecialUser}">
            <authz:authorize allPermissions="CHANGE_OWN_PROFILE">
              <a class="quickLinksControlLink toolbarItem" id="configVisibleProjects" href="#" onclick="BS.VisibleProjectsDialog.show(); return false"
                 title="Show/hide and reorder the projects on this page">Configure Visible Projects</a>
            </authz:authorize>
          </c:if>
        </div>
        <div class="toolbar-left">
          <bs:collapseExpand collapseAction="BS.CollapsableBlocks.collapseAll(true); return false" expandAction="BS.CollapsableBlocks.expandAll(true); return false"/>
          <div style="display: inline-block; width: 8px;"></div>
          <profile:booleanPropertyCheckbox propertyKey="overview.hideSuccessful"
                                           labelText="Hide successful configurations"
                                           afterComplete="BS.reload(true);"/>
        </div>
        <bs:openInSakuraUI />
          <%--
            Use this JS sample for debugging:
            BS.User.setProperty("overview.preferredProjects", "project2:project3");
          --%>
        <authz:authorize allPermissions="CHANGE_OWN_PROFILE">
          <c:if test="${not empty overviewBean.overviewProjectBeans and not empty overviewBean.newProjects and not isSpecialUser}">
            <div id="new-projects">
              <c:set var="newProjectsNum" value="${fn:length(overviewBean.newProjects)}"/>
              <c:set var="allIds" value=""/>
              <c:forEach var="newProject" items="${overviewBean.newProjects}">
                <c:set var="allIds" value="${newProject.projectId},${allIds}"/>
              </c:forEach>
              <c:choose>
                <c:when test="${newProjectsNum > 20}">
                  ${newProjectsNum} new projects
                  <a href="#" onclick="BS.VisibleProjectsDialog.show(); return false" class="middle-link"
                     title="Show/hide and reorder the projects on this page">Configure visible</a>
                  <a href="#" onclick="return BS.Projects.hideAllProjects('${allIds}');">Dismiss</a>
                </c:when>
                <c:when test="${newProjectsNum > 1}">
                  <span id="new-projects-count">${newProjectsNum}</span> new projects
                  <bs:popup_static controlId="newProjectsPopup"
                                  linkOpensPopup="true"
                                  controlClass="middle-link"
                                  popup_options="shift: {x: -85, y: 20}, className: 'flatView'">
                    <jsp:attribute name="content">
                      <div class="list" id="new-projects-list">
                        <c:forEach var="newProject" items="${overviewBean.newProjects}">
                          <div id="new_${newProject.projectId}" class="entry">
                            <a href="#" class="right"
                               onclick="return BS.Projects.addNewProject('${newProject.projectId}');">add to overview</a>
                            <span class="project-link">
                              <bs:projectLinkFull project="${newProject}"/>
                              <bs:trim maxlength="40">${newProject.description}</bs:trim>
                            </span>
                          </div>
                        </c:forEach>
                      </div>
                      <div class="action-bar">
                        <a href="#" onclick="BS.Projects.addAllProjects('${allIds}'); return false">Add all projects</a> or
                        <a href="#" onclick="BS.VisibleProjectsDialog.show(); return false"
                           title="Show/hide and reorder the projects on this page">Configure visible</a>
                      </div>
                    </jsp:attribute>
                    <jsp:body>Show projects</jsp:body>
                  </bs:popup_static>
                  <a href="#" onclick="return BS.Projects.hideAllProjects('${allIds}');">Dismiss</a>
                </c:when>
                <c:otherwise>
                  <c:set var="newProject" value="${overviewBean.firstNewProject}"/>
                  A new project <b><bs:projectLinkFull project="${newProject}"/></b> was created
                  <a href="#" class="middle-link" onclick="return BS.Projects.addAllProjects('${newProject.projectId}');">Add to overview</a>
                  <a href="#" onclick="return BS.Projects.hideAllProjects('${newProject.projectId}');">Dismiss</a>
                </c:otherwise>
              </c:choose>
            </div>
          </c:if>
        </authz:authorize>
      </div>
    </c:when>
    <c:otherwise>
      <div id="toolbar">
        <bs:openInSakuraUI />
      </div>
    </c:otherwise>
  </c:choose>

</jsp:attribute>
<jsp:attribute name="head_include">
  <bs:sakuraReleaseBanner />
  <c:choose>
    <c:when test="${empty overviewBean.overviewProjectBeans}">
      <script type="text/javascript">
        BS.Navigation.items = [
          {title:"Getting started with TeamCity"}
        ];
      </script>
    </c:when>
    <c:otherwise>
      <script type="text/javascript">
        if (BS.TogglePopup != undefined) {
          BS.TogglePopup.isOverviewPage = true;
        }
      </script>
    </c:otherwise>
  </c:choose>
  <bs:linkCSS>
    /css/settingsTable.css
    /css/visibleProjects.css
    /css/progress.css
    /css/overviewTable.css
    /css/overview.css
    /css/filePopup.css
    /css/buildQueue.css
    /css/agentsInfoPopup.css
  </bs:linkCSS>
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
    /js/bs/buildType.js
    /js/bs/problemsSummary.js
  </bs:linkScript>
  <script type="text/javascript">
    $j(document).ready(function() {
      BS.SystemProblems.setOptions({overview: true});
      BS.SystemProblems.startUpdates();
    });

    ReactUI.setActivePageId('projects');
  </script>
</jsp:attribute>

<jsp:attribute name="body_include">
  <c:choose>
    <c:when test="${(not overviewBean.showConfigureVisibilityWarning)}">
      <et:subscribeOnEvents>
        <jsp:attribute name="eventNames">
          PROJECT_CREATED
          PROJECT_ARCHIVED
          PROJECT_DEARCHIVED
        </jsp:attribute>
        <jsp:attribute name="eventHandler">
          BS.reload();
        </jsp:attribute>
      </et:subscribeOnEvents>
      <et:subscribeOnEvents>
        <jsp:attribute name="eventNames">
          BUILD_TYPE_RESPONSIBILITY_CHANGES
          TEST_RESPONSIBILITY_CHANGED
        </jsp:attribute>
        <jsp:attribute name="eventHandler">
          BS.ProblemsSummary.requestUpdateAll();
        </jsp:attribute>
      </et:subscribeOnEvents>
      <%@ include file="overviewProjects.jsp" %>
    </c:when>
    <c:otherwise>
      <c:set var="prjNum" value="${overviewBean.accessibleProjectsNumber}"/>
      <c:set var="btNum" value="${overviewBean.accessibleBuildTypesNumber}"/>
      <div class="configure-visible-message">
        You can view <b>${prjNum}</b> project<bs:s val="${prjNum}"/> and <b>${btNum}</b> build configuration<bs:s val="${btNum}"/>.
        <authz:authorize allPermissions="CHANGE_OWN_PROFILE">
          Please <a href="#" onclick="BS.VisibleProjectsDialog.show(); return false">configure</a>
          the ones that you'd like to see on the Projects page.
        </authz:authorize>
      </div>
      <script type="text/javascript">
        BS.VisibleProjectsDialog.alwaysReload = true;
      </script>
    </c:otherwise>
  </c:choose>
  <jsp:include page="/_visibilityDialogs.jsp"/>
</jsp:attribute>
</bs:page>
