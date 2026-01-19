<%@ page import="jetbrains.buildServer.controllers.admin.projects.EditVcsRootsController" %>
<%@ page import="jetbrains.buildServer.controllers.admin.projects.VcsPropertiesBean" %>
<%@ include file="/include-internal.jsp"%>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<jsp:useBean id="vcsPropertiesBean" scope="request" type="jetbrains.buildServer.controllers.admin.projects.VcsPropertiesBean"/>
<jsp:useBean id="pageUrl" scope="request" type="java.lang.String"/>
<c:set var="pageTitle" scope="request"><c:choose><c:when test="${vcsPropertiesBean.newRoot}">New </c:when><c:otherwise>Edit </c:otherwise></c:choose>VCS Root</c:set>
<c:set var="tplUsages" value="${vcsPropertiesBean.templateVcsRootUsages}"/>
<c:set var="btUsages" value="${vcsPropertiesBean.buildTypeVcsRootUsages}"/>
<c:set var="vsettingsUsages" value="${vcsPropertiesBean.versionedSettingsRootUsages}"/>
<c:set var="moveToProjects" value="${vcsPropertiesBean.moveToProjects}"/>
<c:set var="belongsToProject" value="${vcsPropertiesBean.belongsToProject}"/>
<c:set var="extIdChangeSupported" value="${vcsPropertiesBean.newRoot or belongsToProject.extIdChangeSupported}"/>
<c:set var="inaccessibleNum" value="${vcsPropertiesBean.numberOfInaccessibleUsages}"/>
<c:set var="readOnly" value="${vcsPropertiesBean.readOnly}"/>
<c:if test="${not empty belongsToProject}">
  <c:set var="belongsToProjectLink">
    <admin:editProjectLink projectId="${belongsToProject.externalId}"><c:out value="${belongsToProject.fullName}"/></admin:editProjectLink>
  </c:set>
</c:if>
<c:set var="totalUsages" value="${fn:length(tplUsages) + fn:length(btUsages) + fn:length(vsettingsUsages)}"/>
<bs:page>
<jsp:attribute name="head_include">
  <bs:linkCSS>
    /css/admin/adminMain.css
    /css/admin/vcsSettings.css
    /healthStatus/css/healthStatus.css
  </bs:linkCSS>
  <bs:linkScript>
    /js/bs/editProject.js
    /js/bs/testConnection.js
    /js/bs/moveBuildType.js
    /js/bs/editBuildType.js
  </bs:linkScript>
  <script type="text/javascript">
    <admin:projectPathJS startProject="${belongsToProject}" startAdministration="${true}"/>

    BS.Navigation.items.push(<forms:cameBackNav cameFromSupport="${vcsPropertiesBean.cameFromSupport}"/>);
    BS.Navigation.items.push({title: "${pageTitle}", selected:true});

    /*
    * TODO: Temporary solution to handle the case when the user clicks on the "Add connection" button
    * Task: TW-93452 Improve VCS selection on the create Pipeline page, and provide a convenient way to add extra VCS connections.
    */
    var urlParams = new URLSearchParams(window.location.search);
    var selectedVcsProvider = urlParams.get('selectedVcsProvider');

    if (!!selectedVcsProvider) {
      window['isPageShouldCloseAfterSubmitConnection'] = !!selectedVcsProvider;

      urlParams.delete('selectedVcsProvider');
      var newUrl = window.location.pathname;

      if (urlParams.toString()) {
        newUrl += '?' + urlParams.toString();
      }

      window.history.replaceState({}, document.title, newUrl);

      function onFormSubmitHandler() {
        const locationSearch = location.search;
        const projectId = new URLSearchParams(locationSearch).get('projectId');

        if (projectId) location.href =  window['base_uri'] + '/pipelines/create?projectId=' + projectId;
      }
    }
    /*
    * End of temporary solution.
    */

    <c:if test="${not vcsPropertiesBean.newRoot and not readOnly}">
    $j(document).ready(function() {
      BS.VcsSettingsForm.setupEventHandlers();
    });
    </c:if>
  </script>
</jsp:attribute>
<jsp:attribute name="quickLinks_include">
  <c:if test="${not vcsPropertiesBean.newRoot}">
    <c:set var="showDelete" value="${((totalUsages + inaccessibleNum) == 0 or (fn:length(moveToProjects) > 0)) and not readOnly}"/>
    <c:set var="showMove" value="${fn:length(moveToProjects) > 0 and not readOnly and belongsToProject.moveEntitiesSupported}"/>
    <div class="toolbarItem">
      <c:set var="menuItems">
          <c:if test="${showMove}">
            <l:li><a href="#" onclick="return BS.MoveVcsRootForm.showDialog('${vcsPropertiesBean.vcsRootId}')">Move this VCS root...</a></l:li>
          </c:if>
          <c:if test="${showDelete and (totalUsages + inaccessibleNum) == 0 and afn:canEditVcsRoot(vcsPropertiesBean.originalVcsRoot)}">
            <l:li><a href="#" onclick="return BS.AdminActions.deleteVcsRoot('${vcsPropertiesBean.vcsRootId}', '${util:forJS(vcsPropertiesBean.vcsRootName, true, true)}', function() { document.location.href = BS.ensureLocalUrl('${util:forJS(vcsPropertiesBean.cameFromSupport.cameFromUrl, true, true)}'); })">Delete...</a></l:li>
          </c:if>
          <jsp:include page="/admin/editVcsRootNavExtensions.html?vcsRootId=${vcsPropertiesBean.vcsRootId}"/>
      </c:set>
      <c:if test="${not empty fn:trim(menuItems)}">
        <bs:actionsPopup controlId="prjActions"
                               popup_options="shift: {x: -100, y: 20}, width: '10em', className: 'quickLinksMenuPopup'">
          <jsp:attribute name="content">
            <div>
              <ul class="menuList">
                ${menuItems}
              </ul>
            </div>
          </jsp:attribute>
        <jsp:body>Actions</jsp:body>
      </bs:actionsPopup>
      </c:if>
    </div>
  </c:if>
</jsp:attribute>

<jsp:attribute name="toolbar_include">
    <c:if test="${not vcsPropertiesBean.newRoot}">
      <div class="healthItemIndicatorContainer" style="display: none">
        <c:set var="vcsRootId" scope="request" value="${vcsPropertiesBean.vcsRootId}" />
        <jsp:include page="/admin/vcsRootHealthStatusItems.html">
          <jsp:param name="originUrl" value="${pageUrl}"/>
        </jsp:include>
      </div>
    </c:if>
</jsp:attribute>

<jsp:attribute name="body_include">

  <forms:modified/>

  <bs:unprocessedMessages/>

  <div id="container" class="clearfix">

    <div class="editVcsRootPage">
      <c:set var="autoDetectName" value="<%=VcsPropertiesBean.AUTO_DETECT_NAME%>"/>
      <c:set var="targetSettingsId"><c:out value="${not empty vcsPropertiesBean.targetSettingsId ? vcsPropertiesBean.targetSettingsId : ''}"/></c:set>
      <form id="vcsSettingsForm" action="<c:url value='/admin/editVcsRoot.html?action=${vcsPropertiesBean.newRoot ? "addVcsRoot" : "editVcsRoot"}'/>"
            method="post" onsubmit="return BS.VcsSettingsForm.submitVcsSettings(${vcsPropertiesBean.newRoot}, '${targetSettingsId}', onFormSubmitHandler);" autocomplete="off">

      <div class="vcsSettings clearfix">
        <table class="runnerFormTable">
          <l:settingsGroup title="Type of VCS">
            <tr>
              <th class="noBorder"><label for="vcsName">Type of VCS:</label></th>
              <td class="noBorder"><forms:select name="vcsName" onchange="BS.VcsSettingsForm.setSelectedVcs(this.options[this.selectedIndex].value)" enableFilter="true" className="mediumField">
                <c:if test="${not vcsPropertiesBean.newRoot}">
                  <forms:option value="">-- Choose type of VCS --</forms:option>
                </c:if>
                <c:if test="${vcsPropertiesBean.newRoot}">
                  <forms:option value="${autoDetectName}" selected="${autoDetectName == vcsPropertiesBean.vcsName}">&lt;Guess from repository URL&gt;</forms:option>
                </c:if>
                <c:forEach items="${vcsPropertiesBean.availableVcsTypes}" var="vcs">
                  <forms:option value="${vcs.name}" selected="${vcs.name == vcsPropertiesBean.vcsName}"><c:out value="${vcs.displayName}"/></forms:option>
                </c:forEach>
              </forms:select><forms:saving id="chooseVcsTypeProgress" className="progressRingInline"/></td>
            </tr>
          </l:settingsGroup>
        </table>
      </div>

      <bs:refreshable containerId="vcsRootProperties" pageUrl="${pageUrl}">
        <script type="text/javascript">
          BS.MultilineProperties.clearProperties();
        </script>
        <c:if test="${vcsPropertiesBean.vcsTypeSelected}">
          <div class="vcsSettings clearfix">
            <table class="runnerFormTable ${vcsPropertiesBean.autoDetectMode ? 'advancedSetting' : ''}">
            <l:settingsGroup title="VCS Root">
              <tr>
                <th class="noBorder"><label for="vcsRootName">VCS root name:<c:if test="${not vcsPropertiesBean.autoDetectMode}"><l:star/></c:if></label><bs:help file="ConfiguringVCSRoots-CommonVCSRootProps"/></th>
                <td class="noBorder">
                  <forms:textField name="vcsRootName" value="${vcsPropertiesBean.vcsRootName}" maxlength="256" className="textProperty disableBuildTypeParams longField"/>
                  <span class="error" id="errorVcsRootName"></span>
                  <span class="smallNote">A unique name to distinguish this VCS root from other roots.</span>
                </td>
              </tr>
              <tr>
                <th><label for="externalId">VCS root ID:<c:if test="${not vcsPropertiesBean.autoDetectMode}"><l:star/></c:if><bs:help file="Entity+IDs"/></label></th>
                <td>
                  <forms:textField name="externalId" value="${vcsPropertiesBean.externalId}" maxlength="225" disabled="${readOnly or !extIdChangeSupported}" className="textProperty disableBuildTypeParams longField"/>
                  <span class="error" id="errorExternalId"></span>
                  <span class="smallNote">VCS root ID must be unique across all VCS roots. VCS root ID can be used in parameter references to VCS root parameters and REST API.</span>
                </td>
              </tr>
            </l:settingsGroup>
            </table>

            <c:set var="propertiesBean" value="${vcsPropertiesBean.propertiesBean}" scope="request"/>
            <c:set var="parentProject" value="${belongsToProject}" scope="request"/>
            <jsp:include page="${vcsPropertiesBean.vcsSettingsJspPath}"/>

            <table class="runnerFormTable advancedSetting">
              <l:settingsGroup title="Changes Checking">

                <tr>
                  <td colspan="2">

                      <c:choose>

                        <c:when test="${vcsPropertiesBean.instanceCountWithCommitHooks > 0 and vcsPropertiesBean.instanceCount > 1}">
                          There <bs:are_is val="${vcsPropertiesBean.instanceCount}"/>
                          <admin:vcsRootUsagesLink vcsRoot="${vcsPropertiesBean.originalVcsRoot}"><strong>${vcsPropertiesBean.instanceCount}</strong> instance<bs:s val="${vcsPropertiesBean.instanceCount}"/></admin:vcsRootUsagesLink> of this VCS root in the system,
                          ${vcsPropertiesBean.instanceCountWithCommitHooks} of them use <strong>commit hooks</strong><bs:help file="Configuring VCS Post-Commit Hooks for TeamCity"
                        /><c:if test="${vcsPropertiesBean.instanceCount > vcsPropertiesBean.instanceCountWithCommitHooks}">, others use polling</c:if>
                        </c:when>

                        <c:when test="${vcsPropertiesBean.instanceCountWithCommitHooks == 1 and vcsPropertiesBean.instanceCount == 1}">
                          This VCS Root is configured to use a commit hook <bs:help file="Configuring VCS Post-Commit Hooks for TeamCity"/>
                        </c:when>

                        <c:otherwise>

                          By default, TeamCity uses <strong>polling</strong> to collect changes.<br>
                          You can also configure a <strong>commit hook</strong><bs:help file="Configuring VCS Post-Commit Hooks for TeamCity"/>
                          for faster detection of changes and to avoid VCS server overload.

                          <c:if test="${vcsPropertiesBean.instanceCount > 1}">
                            <br>
                            There <bs:are_is val="${vcsPropertiesBean.instanceCount}"/>
                            <admin:vcsRootUsagesLink vcsRoot="${vcsPropertiesBean.originalVcsRoot}"><strong>${vcsPropertiesBean.instanceCount}</strong> instance<bs:s val="${vcsPropertiesBean.instanceCount}"/></admin:vcsRootUsagesLink>
                            of this VCS root in the system.
                          </c:if>
                        </c:otherwise>
                      </c:choose>

                  </td>
                </tr>

                <c:set var="defaultCheckInterval" value="${vcsPropertiesBean.useDefaultModificationCheckInterval}"/>
                <tr>
                  <th><label for="mod-check-interval-default">Minimum polling interval:</label><bs:help file="ConfiguringVCSRoots-CommonVCSRootProps"/></th>
                  <td>
                    <forms:radioButton name="modificationCheckIntervalMode"
                                       id="mod-check-interval-default"
                                       checked="${defaultCheckInterval}"
                                       value="DEFAULT"
                                       onclick="BS.VcsSettingsForm.updateCheckingIntervalState();"
                                       className="${not defaultCheckInterval ? 'valueChanged' : ''}"/>
                    <label for="mod-check-interval-default">use global server setting
                      (${vcsPropertiesBean.defaultModificationCheckInterval} seconds${vcsPropertiesBean.minimumIntervalEnforced ? ", enforced as a minimum value" : ""})</label>
                </tr>

                <tr>
                  <c:set var="onclick">
                    $('modificationCheckInterval').focus();
                  </c:set>
                  <td>&nbsp;</td>
                  <td>
                    <forms:radioButton name="modificationCheckIntervalMode"
                                       value="SPECIFIED"
                                       id="mod-check-interval-specified"
                                       checked="${not defaultCheckInterval}"
                                       onclick="BS.VcsSettingsForm.updateCheckingIntervalState();${onclick}"
                                       className="${not defaultCheckInterval ? 'valueChanged' : ''}"/>
                    <label for="mod-check-interval-specified">custom:
                    <forms:textField name="modificationCheckInterval" size="4" maxlength="8"
                                     value="${vcsPropertiesBean.modificationCheckInterval}"
                                     disabled="${defaultCheckInterval}" className="smallField"
                                     onchange="BS.VcsSettingsForm.updateCheckingIntervalState();"
                                     onkeyup="BS.VcsSettingsForm.updateCheckingIntervalState();"
                    />
                    seconds</label><span class="error" id="invalidModificationCheckInterval"></span>

                    <c:if test="${vcsPropertiesBean.minimumIntervalEnforced}">
                        <span class="attentionComment attentionComment--underField" style="display: none;"
                              id="checkingIntervalWarning">
                          The enforced minimum for the whole server is
                          <span class="checkingIntervalWarning__default">${vcsPropertiesBean.defaultModificationCheckInterval}</span> seconds,
                          so it will be used instead of the value above.
                        </span>
                    </c:if>

                  </td>
                </tr>
                <tr><td colspan="2"><span class="smallNote">Please note that certain servers can refuse access if polled too frequently.
                  Consider intervals greater than 1800 seconds (30 minutes) for public servers.</span></td></tr>
              </l:settingsGroup>

            </table>

            <table class="runnerFormTable ${vcsPropertiesBean.newRoot ? 'advancedSetting' : ''}">
            <l:settingsGroup title="VCS Root Project">
              <tr>
                <th>
                  <label for="ownerProjectId">Belongs to project:</label>
                </th>
                <td>
                    ${belongsToProjectLink}
                    <c:if test="${showMove}">
                      <input type="button" class="btn btn_mini action" style="margin-left: 2em;" value="Move" onclick="BS.MoveVcsRootForm.showDialog('${vcsPropertiesBean.vcsRootId}')"/>
                    </c:if>
                </td>
              </tr>
            </l:settingsGroup>
            </table>
          </div>

          <admin:showHideAdvancedOpts containerId="vcsSettingsForm" optsKey="vcsRootSettings_${vcsPropertiesBean.vcsName}"/>
          <admin:highlightChangedFields containerId="vcsSettingsForm"/>

          <div>
            <c:if test="${not vcsPropertiesBean.newRoot}">
            <c:set var="allProjectsOptionShown" value="${false}"/>
            <c:if test="${vcsPropertiesBean.editTemplateMode}">
              <c:set var="tplUsageCount" value="${vcsPropertiesBean.targetSettings.numberOfUsages}"/>
              <c:set var="tplUsagesSuffix"><c:if test="${tplUsageCount ge 0}"> and ${tplUsageCount} inherited configuration<bs:s val="${tplUsageCount}"/></c:if></c:set>
            </c:if>
            <c:set var="targetName" value=""/>
            <c:choose>
              <c:when test="${vcsPropertiesBean.createBuildTypeMode}"><c:set var="targetName" value="newly created build configuration"/></c:when>
              <c:when test="${vcsPropertiesBean.createTemplateMode}"><c:set var="targetName" value="newly created template"/></c:when>
              <c:when test="${vcsPropertiesBean.editBuildTypeMode}"><c:set var="targetName">${vcsPropertiesBean.targetSettings.name} only</c:set></c:when>
              <c:when test="${vcsPropertiesBean.editTemplateMode}"><c:set var="targetName">${vcsPropertiesBean.targetSettings.name} ${tplUsagesSuffix}</c:set></c:when>
              <c:when test="${vcsPropertiesBean.editPipelineMode}"><c:set var="targetName">${vcsPropertiesBean.targetPipeline.name} only</c:set></c:when>
            </c:choose>
            <c:if test="${(vcsPropertiesBean.numberOfProjectUsages > 1 and vcsPropertiesBean.usedInTargetProject)
                          or ((vcsPropertiesBean.createBuildTypeOrTemplateMode or vcsPropertiesBean.editBuildTypeOrTemplateMode) and (fn:length(btUsages) + fn:length(tplUsages) > 1))}">
              <c:set var="saveOptionsShown" value="false"/>
              <div class="attentionComment">
                <bs:buildStatusIcon type="red-sign" className="warningIcon"/>
                <c:if test="${vcsPropertiesBean.numberOfProjectUsages > 1}">
                  This VCS root is used in more than one project. Changes to this VCS root may affect all of them. Please choose corresponding option for applying changes in this VCS root.
                </c:if>
                <c:if test="${vcsPropertiesBean.numberOfProjectUsages == 1 and (fn:length(btUsages) + fn:length(tplUsages) > 1)}">
                  This VCS root is used in several places. Changes to this VCS root may affect all of them. Please choose corresponding option for applying changes in this VCS root.
                </c:if>
              </div>
              <table class="saveVcsRootOptions">
                <c:if test="${vcsPropertiesBean.createBuildTypeOrTemplateMode or vcsPropertiesBean.editBuildTypeOrTemplateMode}">
                <c:set var="saveOptionsShown" value="true"/>
                <tr>
                  <td>
                    <forms:radioButton name="saveOption" value="<%=EditVcsRootsController.SaveOptions.COPY_TO_TARGET_BUILD_TYPE.name()%>" id="saveOptionCopyToTargetConf"/>
                    <label for="saveOptionCopyToTargetConf">Apply to <strong><c:out value="${targetName}"/></strong> (a copy of this VCS root will be created)</label>
                  </td>
                </tr>
                </c:if>
                <c:if test="${vcsPropertiesBean.numberOfProjectUsages > 1 and vcsPropertiesBean.usedInTargetProject}">
                <c:set var="saveOptionsShown" value="true"/>
                <tr>
                  <td>
                  <forms:radioButton name="saveOption" value="<%=EditVcsRootsController.SaveOptions.COPY_TO_PROJECT_BUILD_TYPES.name()%>" id="saveOptionCopyToProjectConfs"/>
                  <label for="saveOptionCopyToProjectConfs">Apply to all templates <c:if test="${not vcsPropertiesBean.targetProject.rootProject}">& configurations</c:if> of <strong><c:out value="${vcsPropertiesBean.targetProject.fullName}"/></strong> project where this VCS root is used (a copy of this VCS root will be created)</label>
                  </td>
                </tr>
                </c:if>
                <c:if test="${saveOptionsShown}">
                <tr>
                  <td>
                    <c:set var="allProjectsOptionShown" value="${true}"/>
                  <forms:radioButton name="saveOption" value="<%=EditVcsRootsController.SaveOptions.SAVE_FOR_ALL.name()%>" id="saveOptionSave"/>
                  <label for="saveOptionSave">Apply to all ${vcsPropertiesBean.numberOfProjectUsages > 1 ? 'projects' : 'usages'}</label>
                  </td>
                </tr>
                </c:if>
              </table>
            </c:if>
            </c:if>
            <div class="saveButtonsBlock">
              <c:if test="${not readOnly}">
              <forms:submit label="${vcsPropertiesBean.newRoot ? 'Create' : 'Save'}"/>
              </c:if>
              <c:if test="${vcsPropertiesBean.testConnectionSupported}">
                <forms:submit id="testConnectionButton" type="button" label="Test connection" onclick="BS.VcsSettingsForm.submitTestConnection(${vcsPropertiesBean.newRoot}, ${readOnly});"/>
              </c:if>
              <c:if test="${not readOnly}">
              <forms:cancel cameFromSupport="${vcsPropertiesBean.cameFromSupport}" label="${empty param['showSkip'] ? 'Cancel' : 'Skip'}"/>
              </c:if>
              <forms:saving/>
              <c:if test="${not allProjectsOptionShown}">
                <input type="hidden" name="saveOption" value="SAVE_FOR_ALL"/>
              </c:if>
            </div>
          </div>

        </c:if>

        <input type="hidden" name="submitVcsRoot" id="submitVcsRoot" value="store"/>
        <input type="hidden" name="publicKey" id="publicKey" value="${vcsPropertiesBean.publicKey}"/>
        <input type="hidden" name="editingScope" id="editingScope" value="<c:out value="${vcsPropertiesBean.editingScope}"/>"/>
        <input type="hidden" name="vcsRootId" id="vcsRootId" value="${vcsPropertiesBean.vcsRootId}"/>
        <input type="hidden" name="skipDuplicatesCheck" id="skipDuplicatesCheck" value="false"/>

        <script type="text/javascript">
          <c:choose>
          <c:when test="${not vcsPropertiesBean.newRoot}">
          BS.VcsSettingsForm.setModified(${vcsPropertiesBean.stateModified});
          BS.AvailableParams.attachPopups('vcsRootId=${vcsPropertiesBean.vcsRootId}', 'textProperty', 'multilineProperty');
          </c:when>
          <c:otherwise>
          BS.AvailableParams.attachPopups('projectId=${belongsToProject.externalId}', 'textProperty', 'multilineProperty');
          </c:otherwise>
          </c:choose>
          BS.VisibilityHandlers.updateVisibility('vcsRootProperties');
        </script>

        <bs:dialog dialogId="testConnectionDialog" dialogClass="vcsRootTestConnectionDialog" title="Test Connection" closeCommand="BS.TestConnectionDialog.close();"
          closeAttrs="showdiscardchangesmessage='false'">
          <div id="testConnectionStatus"></div>
          <div id="testConnectionDetails" class="mono"></div>
        </bs:dialog>

        <c:if test="${not readOnly and extIdChangeSupported}">
        <script type="text/javascript">
          BS.AdminActions.prepareVcsRootIdGenerator("externalId", "vcsRootName", '${vcsPropertiesBean.belongsToProject.externalId}', ${not vcsPropertiesBean.newRoot});
        </script>
        </c:if>
      </bs:refreshable>

    </form>

    </div>

    <div id="sidebarAdmin">
      <div>
      <c:if test="${not empty vcsPropertiesBean.originalVcsRoot and totalUsages gt 0}">
        <admin:vcsRootUsagesLink vcsRoot="${vcsPropertiesBean.originalVcsRoot}">View usages</admin:vcsRootUsagesLink>
      </c:if>
      </div>

      <admin:configModificationInfo project="${belongsToProject}" auditLogAction="${vcsPropertiesBean.lastConfigModificationAction}"/>
    </div>

  </div>

  <admin:moveVcsRootForm availableProjects="${moveToProjects}" projectExternalId="belongsToProject.externalId"/>
  <admin:duplicateVcsRootsDialog/>
</jsp:attribute>
</bs:page>
