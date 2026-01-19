<%@ page import="jetbrains.buildServer.web.util.WebUtil" %>
<%@include file="/include-internal.jsp" %>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<%@ taglib prefix="l" tagdir="/WEB-INF/tags/layout" %>
<%@ taglib prefix="forms" tagdir="/WEB-INF/tags/forms" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="clouds" tagdir="/WEB-INF/tags/clouds" %>
<%@ taglib prefix="util" uri="/WEB-INF/functions/util" %>

<jsp:useBean id="cons" class="jetbrains.buildServer.clouds.server.web.CloudWebConstants"/>
<jsp:useBean id="form" type="jetbrains.buildServer.clouds.server.web.beans.CloudTabForm" scope="request"/>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="pageUrl" scope="request" type="java.lang.String"/>
<jsp:useBean id="currentIntegrationStatus" scope="request" type="jetbrains.buildServer.clouds.server.ProjectCloudIntegrationStatus"/>

<jsp:useBean id="agentsTabEnabled" scope="request" type="java.lang.Boolean"/>
<c:set var="usedImageAjaxUrl"><c:url value="/clouds/admin/projectImages.html"/></c:set>

<c:set var="escapedPageUrl" value="<%=WebUtil.encode(pageUrl)%>"/>
<c:set var="profileAjaxUrl"><c:url value="/clouds/admin/cloudAdminProfile.html"/></c:set>
<c:set var="ajaxUrl"><c:url value="/clouds/admin/cloudAdmin.html?projectId=${project.externalId}"/></c:set>
<c:set var="numProfiles" value="${fn:length(form.selfProfiles)}"/>
<c:set var="numSubprojectsProfiles" value="${fn:length(form.subProjectsProfiles)}"/>
<c:set var="numExecutors" value="${fn:length(form.executorsGrouped)}"/>

<script type="text/javascript">
  BS.Clouds.Admin.registerRefresh();
</script>

<bs:refreshable containerId="cloudRefreshable" pageUrl="${pageUrl}">
  <c:if test="${form.configurationEnabled}">
    <div class="right_info_pane">
      <c:if test="${currentIntegrationStatus.enabled}">
        <div class="statusInfo">Cloud integration <strong>is enabled</strong> in this project</div>
      </c:if>
      <c:if test="${not currentIntegrationStatus.enabled}">
        <div class="statusInfo">Cloud integration <span class="red-text">is disabled</span> in this project</div>
      </c:if>
      <c:if test="${currentIntegrationStatus.subprojectsEnabled}">
        <div class="statusInfo">Cloud integration <strong>is enabled</strong> in subprojects</div>
      </c:if>
      <c:if test="${not currentIntegrationStatus.subprojectsEnabled}">
        <div class="statusInfo">Cloud integration <span class="red-text">is disabled</span> in subprojects</div>
      </c:if>

      <c:if test="${not project.readOnly}">
        <div>
          <input class="btn btn_mini" type="submit" value="Change cloud integration status" onclick="BS.Clouds.Admin.ConfirmShutdownDialog.showConfirmDisableDialog()">
        </div>
      </c:if>
    </div>
  </c:if>

  <c:if test="${agentsTabEnabled}">
    <h2 class="noBorder">Agent Cloud</h2>
    <bs:smallNote>Cloud images used in project.</bs:smallNote>

    <p><forms:addButton onclick="BS.Clouds.Admin.Images.showAddDialog('${form.projectExtId}'); return false;">Add cloud image...</forms:addButton></p>

    <c:choose>
      <c:when test="${empty form.usedImages}">
        There are no cloud images used in project.
      </c:when>
      <c:otherwise>
        <table class="settings installed-versions">
          <tr>
            <th class="name">Image</th>
            <th class="name" colspan="2"></th>
          </tr>

          <c:forEach items="${form.usedImages}" var="image">
            <tr>
              <td><c:out value="${image.name}"/></td>
              <td><a onclick="BS.Cloud.Admin.Images.showEditDialog('${image.id}')">edit</a></td>
              <td><a onclick="BS.Cloud.Admin.Images.showRemoveDialog('${image.id}')">remove</a></td>
            </tr>
          </c:forEach>

        </table>
      </c:otherwise>
    </c:choose>
  </c:if>

  <h2 class="noBorder">Cloud Profiles</h2>
  <bs:smallNote>
    Images and running instances of configured cloud profiles are shown on the <a href="<c:url value="/agents.html?tab=clouds"/>">Clouds tab</a>.
  </bs:smallNote>

  <c:if test="${not project.readOnly}">
    <c:set var="addUrl"><c:url value="/admin/editProject.html?projectId=${project.externalId}&tab=clouds&action=new&showEditor=true"/></c:set>
    <p><forms:addButton href="${addUrl}">Create new profile</forms:addButton></p>
  </c:if>

  <div class="cloudProfile cloudAdminProfile">
    <clouds:disabledWarning disabled="${form.disabled}"/>
    <script type="text/javascript">
      BS.Clouds.Admin.setRunningInstancesCount(${form.runningInstancesCount});
      BS.Clouds.Problems = BS.Clouds.Problems || {};
    </script>
    <div>
      <forms:checkbox name="showSubProjects" checked="${form.showSubProjects}"
                      onclick="BS.Clouds.Admin.submitFilter('${form.projectExtId}', this.checked)"/> <label for="showSubProjects">Show cloud profiles from subproject(s)</label>
    </div>

    <c:choose>
      <c:when test="${numProfiles + numSubprojectsProfiles + numExecutors == 0}">
        <div id="noCloudProfilesInfo">There are no cloud profiles configured in current project.</div>
      </c:when>
      <c:when test="${numProfiles + numSubprojectsProfiles != 0}">
        <c:set var="profileNameColsSpan" value="${form.resetActionEnabled ? 5 : 4}"/>
        <l:tableWithHighlighting className="highlightable parametersTable" highlightImmediately="true">
          <tr class="header">
            <c:if test="${form.showSubProjects}"><th>Project</th></c:if>
            <th colspan="${project.readOnly ? 3 : profileNameColsSpan}">Profile Name</th>
          </tr>
          <c:set var="currentProjectNamePrinted" value="${false}"/>
          <c:forEach var="profileInfo" items="${form.selfProfiles}">
            <clouds:cloudProblemContent controlId="error_${profileInfo.id}" problems="${profileInfo.problems}" />
            <c:set var="editUrl"><c:url value="/admin/editProject.html?projectId=${project.externalId}&tab=clouds&action=edit&profileId=${profileInfo.profile.profileId}&showEditor=true"/></c:set>
            <c:set var="disable_profile_class"><c:if test="${not profileInfo.profile.enabled}">disabledProfile</c:if></c:set>
            <c:set value="${util:forJS(profileInfo.profile.profileName, true, true)}" var="escapedName"/>
            <c:set var="disable_actions_popup"
                   value="${not (profileInfo.profile.enabled and form.resetActionEnabled) and profileInfo.project.readOnly}"/>
            <tr>
              <c:if test="${form.showSubProjects and not currentProjectNamePrinted}">
                <td rowspan="${form.selfProfiles.size()}" class="subprojectsName">
                  <bs:projectLinkFull project="${profileInfo.project}" contextProject="${project}"/>
                </td>
                <c:set var="currentProjectNamePrinted" value="${true}"/>
              </c:if>
              <c:if test="${profileInfo.cloudTypeLoaded}">
                <td class="highlight ${disable_profile_class} beforeActions" onclick="BS.openUrl(event, '${editUrl}');">
                  <clouds:profile profile="${profileInfo}"
                                  editUrl="${editUrl}"
                                  enabled="${not form.disabled and profileInfo.profile.enabled}"/></td>
                <td class="highlight edit">
                  <a href="${editUrl}&mode=view">${project.readOnly ? 'View' : 'Edit'}</a>
                </td>
                <c:if test="${not disable_actions_popup}">
                  <td class="highlight edit">
                    <clouds:cloudProfileActions profileInfo="${profileInfo}" resetActionEnabled="${form.resetActionEnabled}"/>
                  </td>
                </c:if>
              </c:if>
            </tr>
          </c:forEach>
          <c:forEach var="profileInfoGroup" items="${form.subprojectProfilesGrouped}">
            <c:set var="currentProjectNamePrinted" value="${false}"/>
            <c:forEach var="profileInfo" items="${profileInfoGroup.second}">
              <c:if test="${profileInfo.project != null}">
                <clouds:cloudProblemContent controlId="error_${profileInfo.id}" problems="${profileInfo.problems}"/>
                <c:set var="editUrl"><c:url
                    value="/admin/editProject.html?projectId=${profileInfo.project.externalId}&tab=clouds&action=edit&profileId=${profileInfo.profile.profileId}&showEditor=true&cameFromUrl=${escapedPageUrl}"/></c:set>
                <%--<c:set var="edit_onlick">document.location.href='<bs:forJs>${editUrl}</bs:forJs>'; return false;</c:set>--%>
                <c:set var="disable_profile_class"><c:if test="${not profileInfo.profile.enabled or not profileInfo.projectIntegrationEnabled}">disabledProfile</c:if></c:set>
                <c:set var="disable_project_class"><c:if test="${not profileInfo.projectIntegrationEnabled}">disabledProfile</c:if></c:set>
                <c:set value="${util:forJS(profileInfo.profile.profileName, true, true)}" var="escapedName"/>
                <c:set var="disable_actions_popup"
                       value="${not (profileInfo.profile.enabled and form.resetActionEnabled) and profileInfo.project.readOnly}"/>
                <tr>
                  <c:if test="${not currentProjectNamePrinted}">
                    <td class="${disable_project_class}" rowspan="${profileInfoGroup.second.size()}">
                      <bs:projectLinkFull project="${profileInfoGroup.first}" contextProject="${project}"/>
                      <c:if test="${not profileInfo.projectIntegrationEnabled}">
                        (cloud integration disabled)
                      </c:if>
                    </td>
                    <c:set var="currentProjectNamePrinted" value="${true}"/>
                  </c:if>
                  <c:if test="${profileInfo.cloudTypeLoaded}">
                    <td class="highlight ${disable_profile_class} beforeActions" onclick="BS.openUrl(event, '${editUrl}');"><clouds:profile profile="${profileInfo}"
                                                                                                                                            editUrl="${editUrl}"
                                                                                                                                            enabled="${profileInfo.projectIntegrationEnabled and profileInfo.profile.enabled}"/></td>
                    <td class="highlight edit">
                      <a href="${editUrl}">${profileInfo.project.readOnly ? 'View' : 'Edit'}</a>
                    </td>
                  </c:if>
                  <c:if test="${!disable_actions_popup}">
                    <td class="highlight edit">
                      <clouds:cloudProfileActions profileInfo="${profileInfo}" resetActionEnabled="${form.resetActionEnabled}"/>
                    </td>
                  </c:if>
                </tr>
              </c:if>
            </c:forEach>
          </c:forEach>
        </l:tableWithHighlighting>
      </c:when>
    </c:choose>

    <!-- Executors Section -->
    <c:if test="${not empty form.executorsGrouped}">
      <l:tableWithHighlighting className="highlightable parametersTable" highlightImmediately="true">
        <tr class="header">
          <c:if test="${form.showSubProjects}"><th>Project</th></c:if>
          <th colspan="${project.readOnly ? 2 : 4}">Executor Name</th>
        </tr>
        <c:forEach var="executorGroup" items="${form.executorsGrouped}">
          <c:set var="currentProjectNamePrinted" value="${false}"/>
          <c:forEach var="executorTabInfo" items="${executorGroup.second}">
            <c:set var="executorInfo" value="${executorTabInfo.descriptor}"/>
            <c:set var="editUrl"><c:url value="/admin/editProject.html?projectId=${executorTabInfo.project.externalId}&tab=clouds&action=edit&profileId=${executorInfo.id}&showEditor=true"/></c:set>
            <c:set var="disable_profile_class"><c:if test="${not executorInfo.enabled}">disabledProfile</c:if></c:set>
            <c:set value="${util:forJS(executorInfo.displayName, true, true)}" var="escapedName"/>
            <tr>
              <c:if test="${form.showSubProjects and not currentProjectNamePrinted}">
                <td rowspan="${executorGroup.second.size()}" class="subprojectsName">
                  <bs:projectLinkFull project="${executorTabInfo.project}" contextProject="${project}"/>
                </td>
                <c:set var="currentProjectNamePrinted" value="${true}"/>
              </c:if>
              <td class="highlight ${disable_profile_class} beforeActions" onclick="BS.openUrl(event, '${editUrl}');">
                <c:choose>
                  <c:when test="${editUrl != null}"><a href="${editUrl}"><c:out value="${executorInfo.displayName}"/></a></c:when>
                  <c:otherwise>
                    <c:out value="${executorInfo.displayName}"/>
                  </c:otherwise>
                </c:choose>
                <c:if test="${not empty executorInfo.description}">
                  <div class="smallNote" style="margin-left: 0;"><c:out value="${executorInfo.description}"/></div>
                </c:if>
              </td>
              <td class="highlight edit">
                <a href="${editUrl}&mode=view">${project.readOnly ? 'View' : 'Edit'}</a>
              </td>
              <c:if test="${not executorTabInfo.project.readOnly}">
                <td class="highlight edit">
                  <clouds:executorActions executorInfo="${executorTabInfo}" project="${project}"/>
                </td>
              </c:if>
            </tr>
          </c:forEach>
        </c:forEach>
      </l:tableWithHighlighting>
    </c:if>

    <script>BS.Clouds.GCProblems();</script>
  </div>
</bs:refreshable>

<bs:modalDialog formId="newProfileForm"
                title="Create Cloud Profile"
                action="${profileAjaxUrl}"
                closeCommand="BS.Clouds.Admin.CreateProfileDialog.close()"
                saveCommand="BS.Clouds.Admin.CreateProfileDialog.submit()">
  <bs:refreshable containerId="newProfileFormMainRefresh" pageUrl="${profileAjaxUrl}"/>
</bs:modalDialog>


<bs:modalDialog formId="confirmShutdown"
                title="Disable cloud integration"
                action="${ajaxUrl}"
                closeCommand="BS.Clouds.Admin.ConfirmDialog.close();"
                saveCommand="BS.Clouds.Admin.ConfirmDialog.submit();"
                dialogClass="modalDialog_small">
  <input type="hidden" name="projectId" id="projectId" value="${project.externalId}"/>
  <input type="hidden" id="projectInstancesCount" value="${form.runningInstancesCount}"/>
  <input type="hidden" id="subprojectsInstancesCount" value="${form.subprojectsInstancesCount}"/>
  <input type="hidden" id="initiallyEnabled" value="${currentIntegrationStatus.enabled}"/>
  <input type="hidden" id="initiallySubprojectsEnabled" value="${currentIntegrationStatus.subprojectsEnabled}"/>
  <span id="confirmShutdown_action"></span>
  <div id="enableCheckbox" class="hidden">
    <forms:checkbox name="enableProject"
                    checked="${currentIntegrationStatus.enabled}"
                    onclick="BS.Clouds.Admin.updateDependentCheckboxes();"
    />
    <label for="enableProject" id="enable_message">
      Enable cloud integration in this project
    </label>
  </div>
  <div id="enableSubprojectsCheckbox">
    <forms:checkbox name="enableSubprojects"
                    checked="${currentIntegrationStatus.subprojectsEnabled && currentIntegrationStatus.enabled}"
                    onclick="BS.Clouds.Admin.updateDependentCheckboxes();"
    />
    <label for="enableSubprojects" id="enableSubprojects_message">
      Enable cloud integration in subprojects
    </label>
  </div>
  <div id="terminateInstancesCheckbox" class="hidden">
    <forms:checkbox name="terminateInstances" checked="${false}"/>
    <label for="terminateInstances" id="confirmShutdown_instances_message">
      Terminate <span id="confirmShutdown_instanceCount"></span> running instance<bs:s val="${form.runningInstancesCount}"/>
    </label>
  </div>
  <c:if test="${cons.allowOverrideStatusInSubprojectsProp()}">
    <div id="allowSubprojectsOverwriteCheckbox">
      <forms:checkbox name="allowSubprojectsOverwrite" checked="${currentIntegrationStatus.allowOverride}"/>
      <label for="allowSubprojectsOverwrite" id="allowSubprojectsOverwrite_message">
        Allow overriding of status in subprojects (experimental)
      </label>
    </div>
  </c:if>
  <div class="popupSaveButtonsBlock">
    <forms:submit label="Agree" id="confirmShutdown_submit"/>
    <forms:cancel onclick="BS.Clouds.Admin.ConfirmShutdownDialog.close()"/>
    <forms:saving id="confirmShutdownDialog_loader"/>
  </div>
</bs:modalDialog>

<bs:modalDialog formId="EditImageDialogForm"
                title="Add cloud agent"
                action="${usedImageAjaxUrl}"
                closeCommand="BS.Clouds.Admin.Images.EditDialog.close()"
                saveCommand="BS.Clouds.Admin.Images.EditDialog.submit('${form.projectExtId}')">

  <div id="editImageDialogBody"></div>

  <div class="popupSaveButtonsBlock">
    <forms:submit label="Add" id="editImages_submit"/>
    <forms:cancel onclick="BS.Clouds.Admin.Images.EditDialog.close()"/>
    <forms:saving id="editImagesDialog_loader"/>
  </div>
</bs:modalDialog>

<bs:modalDialog formId="RemoveImageDialogForm"
                title="Remove Cloud Agent"
                action="${usedImageAjaxUrl}"
                closeCommand="BS.Clouds.Admin.Images.RemoveDialog.close()"
                saveCommand="BS.Clouds.Admin.Images.RemoveDialog.submit()">
  <span id="removeImageDialog_message"></span>
  <div class="popupSaveButtonsBlock">
    <forms:submit label="Remove" id="removeImages_submit"/>
    <forms:cancel onclick="BS.Clouds.Admin.Images.RemoveDialog.close()"/>
    <forms:saving id="removeImagesDialog_loader"/>
  </div>
</bs:modalDialog>
