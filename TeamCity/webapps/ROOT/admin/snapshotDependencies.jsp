<%@ page import="jetbrains.buildServer.serverSide.dependency.DependencyOptions" %>
<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="snapshotDependenciesBean" type="jetbrains.buildServer.controllers.admin.projects.EditableSnapshotDependenciesBean" scope="request"/>
<c:set var="takeStartedBuildOption"><%=DependencyOptions.TAKE_STARTED_BUILD_WITH_SAME_REVISIONS.getKey()%></c:set>
<c:set var="takeSuccessfulBuildsOnlyOption"><%=DependencyOptions.TAKE_SUCCESSFUL_BUILDS_ONLY.getKey()%></c:set>
<c:set var="runBuildOnTheSameAget"><%=DependencyOptions.RUN_BUILD_ON_THE_SAME_AGENT.getKey()%></c:set>
<c:set var="runBuildIfDependencyFailedOption"><%=DependencyOptions.RUN_BUILD_IF_DEPENDENCY_FAILED.getKey()%></c:set>
<c:set var="runBuildIfDependencyFailedToStartOption"><%=DependencyOptions.RUN_BUILD_IF_DEPENDENCY_FAILED_TO_START.getKey()%></c:set>
<c:set var="continuationMode_fail_to_start"><%=DependencyOptions.BuildContinuationMode.MAKE_FAILED_TO_START.name()%></c:set>
<c:set var="continuationMode_add_problem"><%=DependencyOptions.BuildContinuationMode.RUN_ADD_PROBLEM.name()%></c:set>
<c:set var="continuationMode_run"><%=DependencyOptions.BuildContinuationMode.RUN.name()%></c:set>
<c:set var="continuationMode_cancel"><%=DependencyOptions.BuildContinuationMode.CANCEL.name()%></c:set>
<form action="#" class="section noMargin">
  <h2 class="noBorder">Snapshot Dependencies</h2>

  <bs:smallNote>
    Snapshot dependencies are used to create build chains. When being a part of build chain the build of this configuration
    will start only when all dependencies are built. <br/>If necessary, the dependencies will be triggered automatically.
    By default, the build configurations linked by a snapshot dependency use revisions synchronization to ensure the same snapshot
    of the sources. <bs:help file="Snapshot+Dependencies"/>
  </bs:smallNote>

  <c:set var="chainId" value="${snapshotDependenciesBean.buildChainId}"/>
  <c:if test="${not empty chainId}">
    <c:set value='/viewChain.html?chainId=${chainId}&selectedBuildTypeId=${buildForm.settingsBuildType.buildTypeId}&contextProjectId=${buildForm.settingsBuildType.projectExternalId}' var="relativeViewChainUrl"/>
    <c:url value='${relativeViewChainUrl}' var="viewChainUrl"/>
    <p>This build configuration is a part of a&nbsp;&nbsp;<a href="${viewChainUrl}" target="_blank" onclick="BS.stopPropagation(event);" title="Open build chain in a new window"><i class="tc-icon icon16 tc-icon_build-chain"></i>build chain</a></p>
  </c:if>

  <c:set var="buildTypesForAddDependency" value="${snapshotDependenciesBean.buildTypesForAddDependency}"/>
  <c:if test="${not buildForm.readOnly and not empty buildTypesForAddDependency}">
    <div>
      <forms:addButton onclick="BS.SourceDependencyForm.addDependency(event); return false" showdiscardchangesmessage="false">Add new snapshot dependency</forms:addButton>
    </div>
  </c:if>

  <c:if test="${not empty snapshotDependenciesBean.dependencies}">
    <l:tableWithHighlighting highlightImmediately="true" id="snapshotDeps" className="parametersTable">
      <tr>
        <th class="checkbox">
          <forms:checkbox name="selectAllSnapshotDeps"
                          onmouseover="BS.Tooltip.showMessage(this, {shift: {x: 10, y: 20}, delay: 600}, 'Click to select / unselect all dependencies')"
                          onmouseout="BS.Tooltip.hidePopup()"
                          onclick="if (this.checked) BS.Util.selectAll($('snapshotDeps'), 'snDepChkbox'); else BS.Util.unselectAll($('snapshotDeps'), 'snDepChkbox')"
                          disabled="${buildForm.readOnly}"/>
        </th>
        <th class="sourceBuildType">Depends On</th>
        <th colspan="3" class="dependencyOptions">Dependency Options</th>
      </tr>
      <c:forEach items="${snapshotDependenciesBean.dependencies}" var="dependency" varStatus="pos">
        <c:set var="canBeEdited" value="${(dependency.sourceBuildTypeAccessible or not dependency.sourceBuildTypeExists) and not dependency.inherited and not buildForm.readOnly}"/>
        <c:set var="highlight" value='${canBeEdited ? "highlight" : ""}'/>
        <c:set var="onclick"><c:if test="${canBeEdited}">BS.SourceDependencyForm.editDependency(event, '${dependency.sourceBuildTypeId}')</c:if></c:set>
        <tr>
          <td class="checkbox">
            <forms:checkbox name="snDepChkbox" id="snDepChkbox_${pos.index}"
                            value="${dependency.sourceBuildTypeId}" disabled="${not dependency.sourceBuildTypeAccessible or not canBeEdited}"/>
          </td>
          <td class="${highlight}" onclick="${onclick}">
            <c:choose>
              <c:when test="${dependency.sourceBuildTypeAccessible}">
                <c:set var="dependOn" value="${dependency.sourceBuildType}"/>
                <strong>
                  <admin:viewOrEditBuildTypeLinkFull buildType="${dependOn}" step="dependencies"/>
                </strong>
              </c:when>
              <c:when test="${not dependency.sourceBuildTypeExists}"><em title="Build configuration with ID &quot;${dependency.sourceBuildTypeExternalId}&quot; does not exist">&laquo;build configuration with ID "${dependency.sourceBuildTypeExternalId}" does not exist&raquo;</em></c:when>
              <c:otherwise><em title="You do not have enough permissions for this build configuration">&laquo;inaccessible build configuration&raquo;</em></c:otherwise>
            </c:choose>
            <c:if test="${dependency.inherited}">
              <span class="inheritedParam">
                <c:choose>
                  <c:when test="${snapshotDependenciesBean.numberOfTemplates > 1}">(<c:out value="${dependency.inheritedFrom}" />)</c:when>
                  <c:otherwise>(inherited)</c:otherwise>
                </c:choose>
              </span>
            </c:if>
            <c:if test="${not dependency.dependencyResolvable and dependency.sourceBuildTypeAccessible}">
              <br/>
              <bs:buildStatusIcon type="red-sign" className="warningIcon"/>
              This dependency is not trusted by the project <bs:projectLinkFull project="${dependency.sourceBuildType.project}"/>
            </c:if>
          </td>
          <td class="dependencyOptions ${highlight} beforeActions" onclick="${onclick}">
            <bs:_dependencyDescription dependency="${dependency}" settings="${buildForm.settings}"/>
          </td>
          <c:choose>
            <c:when test="${buildForm.readOnly}"/>
            <c:when test="${not canBeEdited}">
              <c:set var="title" value="${dependency.inherited ? 'Inherited dependencies cannot be edited' : ''}"/>
              <td class="edit" colspan="2" title="${title}">cannot be edited</td>
            </c:when>
            <c:otherwise>
              <td class="edit ${highlight}" onclick="${onclick}">
                <a href="#" onclick="BS.SourceDependencyForm.editDependency(event, '${dependency.sourceBuildTypeId}'); Event.stop(event)" showdiscardchangesmessage="false">Edit</a>
              </td>
              <td class="edit ${highlight}">
                <a href="#"
                   onclick="BS.SourceDependencyForm.removeDependencies(['${dependency.sourceBuildTypeId}'], 'remove'); return false" showdiscardchangesmessage="false">Delete</a>
              </td>
            </c:otherwise>
          </c:choose>
        </tr>
      </c:forEach>
    </l:tableWithHighlighting>

    <script type="text/javascript">
      BS.SourceDependencyForm.showOrHideActionsOnSelect();
    </script>
  </c:if>
</form>

<bs:refreshable containerId="sourceEditingDependencyDialog" pageUrl="${pageUrl}&snapshotDepsDialog=true">
  <c:url var="action" value='/admin/editDependencies.html?id=${buildForm.settingsId}'/>
  <c:set var="selectedBuildTypes" value="${snapshotDependenciesBean.selectedBuildTypes}"/>
  <c:set var="dialogTitle">
    <c:choose>
      <c:when test="${snapshotDependenciesBean.addDependencyMode and empty selectedBuildTypes}">Add New Snapshot Dependency</c:when>
      <c:when test="${snapshotDependenciesBean.addDependencyMode and not empty selectedBuildTypes}">Set Dependencies Options</c:when>
      <c:when test="${snapshotDependenciesBean.editDependencyMode}">Edit Snapshot Dependency</c:when>
    </c:choose>
  </c:set>
  <c:set var="editingDep" value="${snapshotDependenciesBean.editingDependency}"/>
  <bs:modalDialog formId="sourceDependencies"
                  action="${action}"
                  title="${dialogTitle}"
                  closeCommand="BS.EditDsl.closeEditDsl('sdDsl', '#sdUiContainer', '.sdDslContainer.fragmentEditDsl'); BS.SourceDependencyForm.close()"
                  saveCommand="BS.SourceDependencyForm.saveDependency()">
    <div class="sdDslContainer fragmentEditDsl">
      <div id="sdDslContainer"></div>
    </div>
    <div id="sdUiContainer">
      <admin:addSnapshotDependencies dependenciesBean="${snapshotDependenciesBean}" compositeBuildType="${buildForm.settings.compositeBuildType}" currentBuildType="${buildForm.settingsBuildType}"/>
    </div>
    <div class="popupSaveButtonsBlock withDslButton">
      <forms:submit label="Save"/>
      <forms:cancel onclick="BS.EditDsl.closeEditDsl('sdDsl', '#sdUiContainer', '.sdDslContainer.fragmentEditDsl'); BS.SourceDependencyForm.close()"/>
      <forms:saving id="addSourceDependencyProgress"/>
      <c:set var="addEditMode"><c:choose><c:when test="${snapshotDependenciesBean.addDependencyMode}"
      >add</c:when><c:when test="${snapshotDependenciesBean.editDependencyMode}"
      >edit:<c:out value="${editingDep.sourceBuildTypeId}"/></c:when></c:choose></c:set>
      <c:if test="${snapshotDependenciesBean.editDependencyMode || snapshotDependenciesBean.addDependencyMode}">
      <authz:authorize projectId="${buildForm.project.projectId}" allPermissions="EDIT_PROJECT">
        <input type="hidden" name="showSourceDependenciesDSL" id="showSourceDependenciesDSL" value="${addEditMode}"/>
        <input type="hidden" name="showDSL" id="showSourceDSL" value=""/>
        <input type="hidden" name="showDSLVersion" id="showSourceDSLVersion" value=""/>
        <input type="hidden" name="showDSLPortable" id="showSourceDSLPortable" value=""/>
        <input type="hidden" name="checkSnapshotDepParams" id="checkSnapshotDepParams" value="true"/>
        <div class="dialogDslButtons"><div id="sdDslButton"></div></div>
        <script type="application/javascript">
          var controlId = 'sdDsl';
          ReactUI.renderShowDslButton('sdDslButton', {
            controlId: controlId,
            onShowDsl: function(){
              var validState =  BS.SourceDependencyForm.configurationIsChosen();
              if (!validState) {
                BS.EditDsl.closeEditDsl(controlId, '#sdUiContainer', '.sdDslContainer.fragmentEditDsl');
                return;
              }
              ReactUI.renderFragmentDslEditor('sdDslContainer', {
                currentZindex: BS.Hider._currentZindex(),
                controlId: controlId,
                onFetch: function(version, portable) {
                  BS.SourceDependencyForm.showSourceDepDSLWithValues(version, portable, controlId, '#sdUiContainer', '.sdDslContainer.fragmentEditDsl')
                }
              })
            },
            onHideDsl: function() {BS.EditDsl.hideEditDslPanel('#sdUiContainer', '.sdDslContainer.fragmentEditDsl');},
          })
        </script>
      </authz:authorize>
    </c:if>
    </div>
    <input type="hidden" name="saveSourceDependency" value="${addEditMode}"/>
  </bs:modalDialog>
</bs:refreshable>

<forms:modified id="snapshot-actions-docked">
  <jsp:body>
    <div class="bulk-operations-toolbar fixedWidth">
      <span class="users-operations">
        <a href="#" class="btn btn_primary submitButton" onclick="BS.SourceDependencyForm.addDependency(event, BS.SourceDependencyForm.getSelectedDeps()); return false">Set dependencies options...</a>
        <a href="#" class="btn btn_primary submitButton" onclick="BS.SourceDependencyForm.removeDependencies(BS.SourceDependencyForm.getSelectedDeps(), ${buildForm.templateBased ? '\'remove / reset\'' : '\'remove\''}); return false">
          Remove${buildForm.templateBased ? ' / Reset' : ''} selected dependencies...
        </a>
      </span>
    </div>
  </jsp:body>
</forms:modified>

<script type="text/javascript">
  var parsedHash = BS.Util.paramsFromHash('&');
  if (parsedHash['addSnapshotDependency']) {
    BS.Util.removeParamFromHash('addSnapshotDependency', '&', true);
    BS.SourceDependencyForm.addDependency();
  }
</script>
