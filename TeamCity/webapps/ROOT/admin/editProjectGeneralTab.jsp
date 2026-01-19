<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="currentProject" type="jetbrains.buildServer.serverSide.impl.ProjectEx" scope="request"
/><jsp:useBean id="projectForm" type="jetbrains.buildServer.controllers.admin.projects.EditProjectForm" scope="request"
/><jsp:useBean id="editableProjects" type="java.util.Collection" scope="request"
/><jsp:useBean id="serverSummary" type="jetbrains.buildServer.web.openapi.ServerSummary" scope="request"
/><jsp:useBean id="subProjects" type="java.util.List" scope="request"
/><jsp:useBean id="editablePipelines" type="java.util.List" scope="request"
/><jsp:useBean id="hasHiddenArchivedSubProjects" type="java.lang.Boolean" scope="request"
/><c:set var="originalExternalId" value="${currentProject.externalId}"
/><c:set var="ownBuildTypes" value="${currentProject.ownBuildTypes}"
/><c:set var="ownSubprojects" value="${subProjects}"
/><c:set var="ownTemplates" value="${currentProject.ownBuildTypeTemplates}"/>

<bs:linkScript>
  /js/bs/queueLikeSorter.js
</bs:linkScript>

<div class="editProjectPage">
  <bs:messages key="projectCreated"/>
  <bs:messages key="projectCopied"/>
  <bs:messages key="projectMoved"/>
  <bs:messages key="projectRemoved"/>
  <bs:messages key="projectArchived"/>
  <bs:messages key="projectDearchived"/>
  <bs:messages key="projectIdsSaved"/>
  <bs:messages key="buildTypesStatusBulkChanged"/>
  <bs:messages key="objectsCreated"/>

  <%--@elvariable id="buildTypesOrderingEnabled" type="java.lang.Boolean"--%>
  <%--@elvariable id="projectOrderingEnabled" type="java.lang.Boolean"--%>
  <c:set var="projectAuthorized" value="${afn:permissionGrantedForProject(currentProject, 'EDIT_PROJECT')}"/>
  <form id="editProjectForm" action="<c:url value='/admin/editProject.html?projectId=${originalExternalId}'/>"
        onsubmit="return BS.EditProjectForm.submitProject()" method="post" class="clearfix">
    <admin:projectForm projectForm="${projectForm}"/>

    <admin:showHideAdvancedOpts containerId="editProjectForm" optsKey="editCreateProject"/>

    <c:if test="${projectAuthorized and (not projectForm.rootProject or not empty projectForm.availableTemplates)}">
      <div class="saveButtonsBlock">
        <forms:submit name="submitButton" label="Save"/>
        <forms:cancel cameFromSupport="${projectForm.cameFromSupport}"/>
        <forms:saving/>
      </div>
    </c:if>
  </form>

  <c:set var="canCreateObjects" value="${projectAuthorized and not currentProject.readOnly}"/>

  <%--@elvariable id="canCreatePipelines" type="java.lang.Boolean"--%>
  <c:if test="${not currentProject.rootProject && (canCreatePipelines || not empty editablePipelines)}">
    <div class="section">
      <h2 class="noBorder">Pipelines <span style="font-size: 85%; font-style: italic" class="commentText small">(early access)</span><admin:pipelinesLeft/></h2>
      <bs:smallNote>A simplified alternative to build configurations linked in a build chain. Features a smart visual editor and allows you to use YAML for configuration-as-code.<%--<bs:help file="TODO"/>--%> </bs:smallNote>
      <c:if test="${canCreateObjects && canCreatePipelines}">
        <div class="clearfix">

          <admin:createPipelineButtons parentProject="${currentProject}" cameFromUrl="${pageUrl}" createPipelineTitle="Create pipeline"/>

            <%-- reordering not yet supported --%>

        </div>
      </c:if>
      <c:if test="${empty editablePipelines and !canCreateObjects}"><div>None defined</div></c:if>
      <c:if test="${not empty editablePipelines}">
        <l:tableWithHighlighting className="parametersTable" id="subprojects">
          <tr>
            <th class="name" colspan="3">Name</th>
          </tr>
          <c:forEach items="${editablePipelines}" var="pipeline">
            <c:set var="onclick">BS.openUrl(event, '<admin:pipelineLink edit="true" pipelineId="${pipeline.projectId}"
                                                                        title="Edit pipeline"
                                                                        withoutLink="true"/>');</c:set>
            <tr>
              <c:set var="editable" value="${afn:permissionGrantedForProject(pipeline, 'EDIT_PROJECT')}"/>
              <c:set var="canViewSettings" value="${afn:permissionGrantedForProject(pipeline, 'VIEW_BUILD_CONFIGURATION_SETTINGS')}"/>
              <td class="${editable or canViewSettings ? 'highlight beforeActions' : ''}" style="width: 90%" onclick="${editable or canViewSettings ? onclick : ''}" colspan="${editable ? 1 : (canViewSettings ? 2 : 3)}">
                <strong><c:out value="${pipeline.name}"/></strong>
              </td>
              <c:if test="${editable or canViewSettings}">
                <td class="edit highlight" onclick="${onclick}">

                  <admin:pipelineLink edit="true" pipelineId="${pipeline.projectId}">${pipeline.readOnly or not editable ? 'View' : 'Edit'}</admin:pipelineLink>

                </td>
                <c:if test="${editable}">
                  <td class="edit highlight">
                    <admin:pipelineActions project="${pipeline}"/>
                  </td>
                </c:if>
              </c:if>
            </tr>
          </c:forEach>
        </l:tableWithHighlighting>
      </c:if>
    </div>
    </div>
  </c:if>

  <c:if test="${not currentProject.rootProject}">
  <div class="section smallMargin">
    <h2 class="noBorder">Build Configurations<admin:bcLeft/></h2>
    <bs:messages key="buildTypeRemoved" style="text-align: left;"/>

    <c:set var="description">Build configurations define how to retrieve and build sources of a project.<bs:help file="Creating+and+Editing+Build+Configurations"/></c:set>
    <bs:smallNote>${description}</bs:smallNote>
    <c:if test="${canCreateObjects}">
      <div class="buildConfigurationsTableHeader">
        <admin:createBuildTypeButtons project="${currentProject}" cameFromUrl="${pageUrl}"/>
        <c:if test="${fn:length(ownBuildTypes) > 1}">
          <bs:reorderDialog dialogId="reorderBuildTypesDialog" dialogTitle="Build Configurations">
              <jsp:attribute name="sortables">
                <c:forEach items="${ownBuildTypes}" var="buildType">
                  <div class="buildType draggable tc-icon_before icon16 tc-icon_draggable" id="ord_${buildType.externalId}"><c:out value="${buildType.name}"/></div>
                </c:forEach>
              </jsp:attribute>
            <jsp:attribute name="actionsExtension">
                <c:if test="${buildTypesOrderingEnabled}"><forms:button className="resetOrder">Disable custom order</forms:button></c:if>
              </jsp:attribute>
            <jsp:attribute name="messageBody"><div>This will affect the default display for all users.</div></jsp:attribute>
          </bs:reorderDialog>

          <div class="editCustomOrder" data-hint-container-id='reorder-items'>
            <span class="greyNote">sorted ${buildTypesOrderingEnabled ? 'with custom order' : 'alphabetically'}
              <a title="Click to ${buildTypesOrderingEnabled ? 'edit or disable' : 'enable'} custom ordering" id="editBuildTypesOrder" class="btn">Reorder</a>
            </span>
            <script>
              ReactUI.registerHint({
                id: 'reorder-items',
                name: 'Reorder Objects',
                text: 'By default, projects and configurations are sorted in a list alphabetically, but you can reorder them according to your preferences.',
                category: 'Administration',
              });
            </script>
          </div>
        </c:if>
      </div>
    </c:if>
    <c:if test="${empty ownBuildTypes and !canCreateObjects}"><div>None defined</div></c:if>
    <c:if test="${not empty ownBuildTypes}">
      <l:tableWithHighlighting className="parametersTable" id="configurations">
        <tr>
          <th class="name">Name</th>
          <th class="runner" colspan="${projectAuthorized ? '3' : '2'}">Build Steps</th>
        </tr>
        <c:forEach items="${ownBuildTypes}" var="buildType">
          <c:set var="onclick">BS.openUrl(event, '<admin:editBuildTypeLink withoutLink="true"
                                                                           buildTypeId="${buildType.externalId}"
                                                                           cameFromUrl="${cameFromUrl}"/>');</c:set>
          <tr>
            <td class="name highlight" onclick="${onclick}">
              <admin:buildTypeTemplateInfo buildType="${buildType}"/>
              <bs:_buildTypePausedIcon buildType="${buildType}"/>
              <strong><c:out value="${buildType.name}"/></strong>
              <div class="smallNote" style="margin-left: 0;"><c:out value="${buildType.description}"/></div>
            </td>
            <td class="runner highlight beforeActions" onclick="${onclick}">
              <admin:buildRunnersInfo buildTypeSettings="${buildType}"/>
            </td>
            <c:if test="${projectAuthorized or afn:permissionGrantedForProject(currentProject, 'VIEW_BUILD_CONFIGURATION_SETTINGS')}">
            <td class="edit highlight" onclick="${onclick}">
              <admin:editBuildTypeMenu buildType="${buildType}" cameFromUrl="${cameFromUrl}">${buildType.readOnly or !afn:permissionGrantedForProject(currentProject, 'EDIT_PROJECT') ? 'View' : 'Edit'}</admin:editBuildTypeMenu>
            </td>
            </c:if>
            <c:if test="${projectAuthorized}">
            <td class="edit highlight">
              <admin:buildTypeActions buildType="${buildType}" editableProjects="${editableProjects}"/>
            </td>
            </c:if>
          </tr>
        </c:forEach>
      </l:tableWithHighlighting>
    </c:if>
  </div>
  </c:if>

  <div class="section">
    <h2 class="noBorder">Build Configuration Templates</h2>
    <bs:smallNote>Build configuration templates define settings that can be reused by different build configurations.<bs:help file="Build+Configuration+Template"/></bs:smallNote>

    <bs:messages key="templateRemoved" style="text-align: left;"/>
    <c:if test="${canCreateObjects}">
      <div class="clearfix">
        <c:url value="/admin/createTemplate.html?projectId=${currentProject.externalId}&init=1" var="url"/>
        <forms:addButton href="${url}">Create template</forms:addButton>
      </div>
    </c:if>
    <c:if test="${empty ownTemplates and !canCreateObjects}"><div>None defined</div></c:if>
    <c:if test="${not empty ownTemplates}">
    <l:tableWithHighlighting className="parametersTable" id="templates">
      <tr>
        <th class="name" colspan="${projectAuthorized ? '3' : '2'}">Name</th>
      </tr>
      <c:forEach items="${ownTemplates}" var="template">
        <tr>
          <c:set var="onclick">BS.openUrl(event, '<admin:editTemplateLink withoutLink="true"
                                                                          templateId="${template.externalId}"
                                                                          cameFromUrl="${cameFromUrl}"/>');</c:set>
          <td class="name highlight beforeActions" onclick="${onclick}">
            <strong><c:out value="${template.name}"/></strong>
            <span class="smallNote" style="margin-left: 2em;"><c:out value="${template.description}"/></span>
            <span style="float:right; padding-right: 1em;"><a href="<c:url value='/admin/editProject.html?tab=usagesReport&projectId=${template.project.externalId}&templateId=${template.externalId}'/>">View usages</a></span>
          </td>
          <c:if test="${afn:permissionGrantedForProject(currentProject, 'EDIT_PROJECT') or afn:permissionGrantedForProject(currentProject, 'VIEW_BUILD_CONFIGURATION_SETTINGS')}">
          <td class="edit highlight" onclick="${onclick}">
            <admin:editTemplateMenu template="${template}" cameFromUrl="${cameFromUrl}">${template.readOnly or !projectAuthorized ? 'View' : 'Edit'}</admin:editTemplateMenu>
          </td>
          </c:if>
          <c:if test="${afn:permissionGrantedForProject(currentProject, 'EDIT_PROJECT')}">
          <td class="edit highlight">
            <admin:templateActions template="${template}" editableProjects="${editableProjects}"/>
          </td>
          </c:if>
        </tr>
      </c:forEach>
    </l:tableWithHighlighting>
    </c:if>
  </div>

  <c:set var="canCreateSubprojects" value="${afn:permissionGrantedForProject(currentProject, 'CREATE_SUB_PROJECT') and not currentProject.readOnly and currentProject.projectCreateSupported}"/>
  <c:set var="canReorderSubprojects" value="${fn:length(ownSubprojects) > 1 && projectAuthorized and not currentProject.readOnly}"/>

  <div class="section">
    <h2 class="noBorder">Subprojects</h2>
    <bs:smallNote>Subprojects can be used to group build configurations and define projects hierarchy within a single project.<bs:help file="Creating+and+Editing+Projects"/></bs:smallNote>
    <c:if test="${canCreateSubprojects or canReorderSubprojects}">
    <div class="clearfix subProjectsTableHeader">
      <c:if test="${canCreateSubprojects}">
        <admin:createProjectButtons parentProject="${currentProject}" cameFromUrl="${pageUrl}" createProjectTitle="Create subproject"/>
      </c:if>
      <c:if test="${canReorderSubprojects}">
        <bs:reorderDialog dialogId="reorderProjectsDialog" dialogTitle="Subprojects">
          <jsp:attribute name="sortables">
            <c:forEach items="${ownSubprojects}" var="project">
              <div class="project draggable tc-icon_before icon16 tc-icon_draggable" id="ord_${project.externalId}"><c:out value="${project.name}"/></div>
            </c:forEach>
          </jsp:attribute>
          <jsp:attribute name="actionsExtension">
            <c:if test="${projectOrderingEnabled}"><forms:button className="resetOrder">Disable custom order</forms:button></c:if>
          </jsp:attribute>
          <jsp:attribute name="messageBody"><div>This will affect the default display for all users.</div></jsp:attribute>
        </bs:reorderDialog>

        <div class="editCustomOrder">
          <span class="greyNote">sorted ${projectOrderingEnabled ? 'with custom order' : 'alphabetically'}
             <a title="Click to ${projectOrderingEnabled ? 'edit or disable' : 'enable'} custom ordering" id="editProjectsOrder" class="btn">Reorder</a> </span>
        </div>
      </c:if>
    </div>
    </c:if>
    <c:if test="${empty ownSubprojects and !canCreateSubprojects}"><div>None defined</div></c:if>
    <c:if test="${not empty ownSubprojects}">
      <l:tableWithHighlighting className="parametersTable" id="subprojects">
        <tr>
          <th class="name" colspan="3">Name</th>
        </tr>
        <c:forEach items="${ownSubprojects}" var="project">
          <c:set var="onclick">BS.openUrl(event, '<admin:editProjectLink projectId="${project.externalId}"
                                                                         title="Edit project"
                                                                         withoutLink="true"/>');</c:set>
          <tr>
            <c:set var="editable" value="${afn:permissionGrantedForProject(project, 'EDIT_PROJECT')}"/>
            <c:set var="canViewSettings" value="${afn:permissionGrantedForProject(project, 'VIEW_BUILD_CONFIGURATION_SETTINGS')}"/>
            <td class="${editable or canViewSettings ? 'highlight beforeActions' : ''}" style="width: 90%" onclick="${editable or canViewSettings ? onclick : ''}" colspan="${editable ? 1 : (canViewSettings ? 2 : 3)}">
              <strong><c:out value="${project.name}"/></strong>
              <c:if test="${project.archived}"><i class="archived_project">(archived)</i></c:if>
              <span class="smallNote" style="margin-left: 2em;"><c:out value="${project.description}"/></span>
            </td>
            <c:if test="${editable or canViewSettings}">
              <td class="edit highlight" onclick="${onclick}">
                <admin:editProjectLink projectId="${project.externalId}">${project.readOnly or not editable ? 'View' : 'Edit'}</admin:editProjectLink>
              </td>
              <c:if test="${editable}">
              <td class="edit highlight">
                <admin:projectActions project="${project}"/>
              </td>
              </c:if>
            </c:if>
          </tr>
        </c:forEach>
      </l:tableWithHighlighting>
    </c:if>
    <c:if test="${hasHiddenArchivedSubProjects}"><a href="${pageUrl}&showArchived=true">Show archived subprojects &raquo;</a></c:if>
  </div>

<script type="text/javascript">
  $j(function() {
    BS.EditProjectTab.initReorderModalDialogs("${currentProject.externalId}");
    var $modifiedMessage = $j(".modifiedMessage");
    $j("#subprojectsOrderingCB").on("change", function(event) {
      var $cb = $j(event.target);
      if (arguments[0].target.checked == $cb.attr("data-init-state")) {
        $modifiedMessage.hide();
      } else {
        $modifiedMessage.show();
      }
      $j("td.reorderHandle").toggleClass("draggable");
    });

    var $subs = $j("#subprojects tbody");
    if ($subs.length > 0) {
      $subs.sortable({
                       cancel: ".inherited",
                       tolerance: "pointer",
                       scroll: true,
                       axis: "y",
                       opacity: 0.7,
                       handle: ".reorderHandle",
                       items: "tr.allowed"
                     });
    }

    $subs.on("sortupdate", function() {
      $modifiedMessage.show();
    });
  });

  <c:if test="${currentProject.readOnly}">
  BS.EditProjectForm.disable();
  </c:if>
</script>

<forms:modified/>
