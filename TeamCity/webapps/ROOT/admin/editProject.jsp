<%@ page import="jetbrains.buildServer.serverSide.healthStatus.SuggestionCategory" %>
<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<%@ page import="jetbrains.buildServer.web.openapi.PageExtension" %>
<%--@elvariable id="currentProject" type="jetbrains.buildServer.serverSide.impl.ProjectEx"--%>
<%--@elvariable id="serverSummary" type="jetbrains.buildServer.web.openapi.ServerSummary"--%>
<%--@elvariable id="isAccessError" type="java.lang.Boolean"--%>
<%@
    include file="/include-internal.jsp" %><%@
    taglib prefix="admin" tagdir="/WEB-INF/tags/admin"
%><jsp:useBean id="currentProject" type="jetbrains.buildServer.serverSide.impl.ProjectEx" scope="request"
/><jsp:useBean id="pageUrl" type="java.lang.String" scope="request"
/><jsp:useBean id="projectTabs" type="java.util.Map<java.lang.String, java.util.List<jetbrains.buildServer.web.openapi.PageExtension>>" scope="request"
/><c:set var="pageTitle" value="${currentProject.name} Project Settings" scope="request"
/><c:set var="originalExternalId" value="${currentProject.externalId}"
/><c:set var="ownBuildTypes" value="${currentProject.ownBuildTypes}"
/><c:set var="ownSubprojects" value="${currentProject.ownProjects}"
/><ext:defineExtensionTab placeId="<%=PlaceId.EDIT_PROJECT_PAGE_TAB%>"
/><bs:page isAdmin="${true}" isEditProjectPage="true" >
  <jsp:attribute name="head_include">
    <admin:projectAdminHead />
  </jsp:attribute>

  <jsp:attribute name="quickLinks_include">
    <div class="toolbarItem" data-hint-container-id="project-admin-actions">
      <admin:projectActions project="${currentProject}" useRingStyles="true"/>
    </div>
    <c:set var="id" value="homeLink"/>
    <div class="toolbarItem" id="${id}" data-hint-container-id="project-home">
      <div id="project-link-container"></div>
      <script>
        ReactUI.renderConnected(document.getElementById('project-link-container'), ReactUI.EditEntity, {
          isGoBack: true,
          href: location.origin + '<bs:projectUrl projectId="${currentProject.externalId}" />',
        }, false);
        BS.Branch.injectBranchParamToLinks($j("#" + "${id}"), "${currentProject.externalId}");
        ReactUI.registerHint({
          id: 'project-home',
          name: 'Project Home',
          text: 'The TeamCity UI has the user mode, where you can view the results, and admin mode, where you can edit the settings. Use this link to switch between these modes.',
          category: 'Administration',
          directions: ['BOTTOM_LEFT']
        });
        ReactUI.registerHint({
          id: 'project-admin-actions',
          name: 'Actions',
          text: 'Access the main operations available for this project: copy, edit, delete, and more.',
          category: 'Administration',
          helpLink: BS.helpUrlPrefix + 'Creating+and+Editing+Projects#Managing+Project',
          directions: ['BOTTOM_LEFT']
        });
      </script>
    </div>
    <div class="healthItemIndicatorContainer">
      <bs:changeRequest key="project" value="${currentProject}">
        <bs:changeRequest key="excludeCategoryId" value="<%=SuggestionCategory.CATEGORY_ID%>">
          <jsp:include page="/admin/projectHealthStatusItems.html">
            <jsp:param name="originUrl" value="${pageUrl}"/>
          </jsp:include>
        </bs:changeRequest>
      </bs:changeRequest>
    </div>
  </jsp:attribute>

  <jsp:attribute name="sidebar_include">
    <div id="projectsSidebarWrapper">
      <div id="projectsSidebar"></div>
    </div>
    <script>
      ReactUI.renderProjectsSidebar('projectsSidebar');
    </script>
  </jsp:attribute>

  <jsp:attribute name="sidebar_script_include">
    <script>
      <bs:trimWhitespace>
        BS.Navigation.items = [];

        <c:set var="curId" value="${currentProject.externalId}"/>
        <c:forEach var="p" items="${currentProject.projectPath}" varStatus="status">
          BS.Navigation.items.push({
            title: "<bs:escapeForJs text="${p.name}" forHTMLAttribute="true"/>",
            url: BS.Navigation.fromUrl("${curId}", "${p.externalId}", null, ${status.last}),
            selected: ${status.last ? 'true' : 'false'},
            itemClass: "project",
            projectId: "${p.externalId}",
            siblingsTree: {
              parentId: "${p.parentProjectExternalId}",
              projectUrlFormat: '<admin:editProjectLink projectId="{id}" withoutLink="true" addToUrl="&tab=${extensionTab.tabId}"/>',
              buildTypeUrlFormat: '<admin:editBuildTypeLink buildTypeId="{id}" withoutLink="true"/>',
              templateUrlFormat: '<admin:editTemplateLink templateId="{id}" withoutLink="true"/>',
              pipelineUrlFormat: '<admin:pipelineLink edit="true" pipelineId="{id}" withoutLink="true"/>',
            }
          });
        </c:forEach>
      </bs:trimWhitespace>

      ReactUI.setActivePageId('projects');

      {
        const settings = {
          currentId: '${currentProject.externalId}',
          currentNodeType: 'project',
          projectUrlFormat: '<admin:editProjectLink projectId="{id}" withoutLink="true"/>',
          buildTypeUrlFormat: '<admin:editBuildTypeLink buildTypeId="{id}" withoutLink="true"/>',
          templateUrlFormat: '<admin:editTemplateLink templateId="{id}" withoutLink="true"/>',
          pipelineUrlFormat: '<admin:pipelineLink edit="true" pipelineId="{id}" withoutLink="true"/>',
        };
        BS.RestProjectsPopup.addUrlFormats(settings);

        ReactUI.setAdminSidebarPanelSettings(settings);
      }
    </script>
  </jsp:attribute>

  <jsp:attribute name="body_include">
    <c:choose>
      <c:when test="${isAccessError}">
        <c:set var="homeHref"><bs:projectUrl projectId="${originalExternalId}" /></c:set>
        <admin:accessError type="project" homeHref="${homeHref}"/>
      </c:when>
      <c:otherwise>
        <script>
          $j('#restPageDescription').html(`
            <bs:forJs><admin:configModificationInfo auditLogAction="${currentProject.lastConfigModificationAction}" project="${currentProject}" inline="true"/></bs:forJs>
          `).css({display: 'block', marginTop: '6px'});
        </script>
        <table id="admin-container">
          <tr>
            <td class="admin-sidebar project-sidebar compact">
              <aside>
                <div id="projectTabsContainer" class="simpleTabs clearfix">
                  <ext:showSidebar paramName="tab" urlPrefix="/admin/editProject.html?projectId=${currentProject.externalId}" extensions="${projectTabs}" selectedExtension="${extensionTab}"/>
                  <div hidden id="warningIcon">
                    <bs:buildStatusIcon type="red-sign" className="warningIcon"/>
                  </div>
                  <script>
                    new TabbedPane.Tab().extractCountForElements('#projectTabsContainer .item a');
                    {
                      const hints = [{
                        id: 'projectVcsRoots',
                        name: 'VCS Roots',
                        text: 'VCS roots define the project\'s source repositories or their specific branches.',
                        helpLink: BS.helpUrlPrefix + 'VCS+Root',
                      }, {
                        id: 'projectParams',
                        name: 'Project parameters',
                        text: 'Parameters can be reused in settings or passed between the project\'s builds: for example, you can define a password and reference its value in multiple subprojects.',
                        helpLink: BS.helpUrlPrefix + 'VCS+Root',
                      }, {
                        id: 'oauthConnections',
                        name: 'Connections',
                        text: 'Configure integrations with different services, like GitHub or Slack, in one place and use them in the nested projects and build configurations.',
                      }, {
                        id: 'clouds',
                        name: 'Cloud profiles',
                        text: 'TeamCity can start build agents on virtual machines in the cloud. Cloud profiles define integration with cloud solutions like Amazon EC2, Microsoft Azure, or Kubernetes.',
                        helpLink: BS.helpUrlPrefix + 'Agent+Cloud+Profile',
                      }, {
                        id: 'cleanup',
                        name: 'Clean-up Rules',
                        text: 'Configure clean-up rules to schedule the deletion of no longer necessary data, like artifacts or build logs.',
                        helpLink: BS.helpUrlPrefix + 'Clean-Up',
                      }, {
                        id: 'versionedSettings',
                        name: 'Versioned settings',
                        text: 'Store your project settings as a code in VCS, in Kotlin or XML format.',
                        helpLink: BS.helpUrlPrefix + 'Storing+Project+Settings+in+Version+Control',
                      }, {
                        id: 'artifactsStorage',
                        name: 'Artifacts storage',
                        text: 'Choose where to store artifacts produced by builds: on the same machine with the TeamCity server or in some third-party service like Amazon S3.',
                        helpLink: BS.helpUrlPrefix + 'Configuring+Artifacts+Storage',
                      }];
                      const hintsMap = new Map(hints.map(hint => [hint.id, {...hint, registered: false}]));
                      $j('#projectTabsContainer [data-tab-id]').each((_, item) => {
                        const hint = hintsMap.get(item.getAttribute('data-tab-id'));

                        if (!hint) {
                          return;
                        }

                        if (!hint.registered) {
                          ReactUI.registerHint({
                            ...hint,
                            selector: `[data-tab-id=${hint.id}]`,
                            className: 'admin-sidebar-hint',
                            category: 'Sidebar',
                            directions: ['RIGHT_BOTTOM'],
                          });
                          hint.registered = true;
                        }
                      });
                    }
                  </script>
                </div>
                <div class="admin-menu__bg"></div>
              </aside>
            </td>
            <td class="admin-content projectContent">
              <bs:main>
                <div id="adminBreadcrumbsWrapper"></div>
                <bs:projectArchived project="${currentProject}"/>
                <bs:projectReadOnly project="${currentProject}"/>
                <ext:includeExtension extension="${extensionTab}"/>
              </bs:main>
            </td>
          </tr>
        </table>
        <bs:executeOnce id="archiveProjectDialog"><bs:archiveProjectDialog/></bs:executeOnce>
      </c:otherwise>
    </c:choose>
  </jsp:attribute>
</bs:page>
