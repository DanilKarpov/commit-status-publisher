<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="intprop" uri="/WEB-INF/functions/intprop"%>
<%@ taglib prefix="projectsImport" tagdir="/WEB-INF/tags/admin/projectsImport" %>

<%--@elvariable id="configureImportStep" type="jetbrains.buildServer.controllers.admin.projectsImport.ConfigureImportStepBean"--%>

<c:set value="${fn:length(configureImportStep.usersWithSameVerifiedEmail)}" var="conflictingUsersWithSameVerifiedEmailCount"/>
<c:set value="${fn:length(configureImportStep.usersWithSameNotVerifiedEmail)}" var="conflictingUsersWithSameNotVerifiedEmailCount"/>
<c:set value="${fn:length(configureImportStep.usersWithDifferentEmail)}" var="conflictingUsersWithDifferentEmailCount"/>

<c:set value="${fn:length(configureImportStep.conflictingGroups)}" var="conflictingGroupsCount"/>

<h2>Configure Import Scope</h2>
<form id="configureImportForm" onsubmit="return BS.ProjectsImport.ConfigureImportForm.submit()" method="post">

  <c:choose>
    <c:when test="${!configureImportStep.configsAvailable && !configureImportStep.dbDataAvailable}">
      Selected backup file contains no projects configurations, no data.<br/>
      If you need to import projects, create a backup with scope including projects.
    </c:when>
    <c:when test="${!configureImportStep.allEncryptionKeysAvailable}">
      Failed to import encrypted projects: this server is missing required encryption keys.<br>
      Please add all TeamCity encryption keys from the source server to the current one. <bs:help file="Encryption+Settings"/>
    </c:when>
    <c:otherwise>
      <p>Please select projects to be imported and import scope. <bs:helpLink file="ProjectImport-ImportingProjects"><bs:helpIcon/></bs:helpLink></p>


      <table class="runnerFormTable">
        <tr>
          <th><label>Projects for import:</label></th>
          <td>
            <c:choose>
              <c:when test="${!configureImportStep.configsAvailable}">
                Selected backup file doesn't contain projects configurations.<br/>
                If you need to import projects, create a backup with scope including projects.
              </c:when>
              <c:otherwise>
                <bs:inplaceFilter containerId="projectSelect" activate="true" filterText="&lt;filter projects>"
                                  afterApplyFunc="function(filterField) { BS.MultiSelect.update('#projectSelect', filterField); }"/>
                <div id="projectSelect" class="projectTree multi-select">
                  <c:forEach items="${configureImportStep.availableProjects}" var="bean">
                    <%--@elvariable id="bean" type="jetbrains.buildServer.web.util.HierarchyBean"--%>
                    <c:set var="project" value="${bean.node}"/>
                    <%--@elvariable id="project" type="jetbrains.buildServer.serverSide.projectsImport.ImportedProject"--%>

                    <c:set var="fullPath"><c:forEach items="${project.parentPath}" var="parent"> <bs:escapeForJs forHTMLAttribute="true" text="${parent.name}"/></c:forEach></c:set>

                    <div class="inplaceFiltered user-depth-${bean.limitedDepth} disabled group" data-title="${fullPath}" data-depth="${bean.limitedDepth}">
                      <label>
                        <input type="checkbox" id="selectToImport_${project.extId}" value="${project.extId}" name="selectedProjectsExternalIds" class="group"/>
                        <label for="selectToImport_${project.extId}"><c:out value="${project.name}"/></label>
                      </label>
                    </div>
                  </c:forEach>
                </div>

                <c:if test="${configureImportStep.unresolvableConflictsCount > 0}">
                  <p class="attentionComment" style="margin-top: 1em">
                    <bs:buildStatusIcon type="red-sign" className="warningIcon"/>${configureImportStep.unresolvableConflictsCount} conflict<bs:s val="${configureImportStep.unresolvableConflictsCount}"/> in
                    ${configureImportStep.countOfProjectsWithConflicts} project<bs:s val="${configureImportStep.countOfProjectsWithConflicts}"/>
                    found.
                    <a href="#" title='View conflicts' onclick="BS.ProjectsImport.ProjectsConflictsDialog.showCentered(); return false;">Show details &raquo;</a>
                  </p>
                </c:if>

                <script>
                  BS.MultiSelect.init("#projectSelect", BS.ProjectsImport.ConfigureImportForm.scopeChanged);
                </script>
              </c:otherwise>
            </c:choose>
          </td>
        </tr>

        <tr>
          <th><label>Import scope:</label></th>
          <td>
            <div class="importScope">
              <c:if test="${not configureImportStep.dbDataAvailable}">
                <p>
                  Selected backup file doesn't contain database dump.<br/>
                  If you need to import data, create a backup with scope including database.
                </p>
              </c:if>
              <div>
                <forms:checkbox name="includeConfigs"/>
                <label for="includeConfigs">Project settings</label>
                <span class="smallNote">Configuration files of selected projects and their parents will be included.</span>
              </div>
              <div class="nested">
                <forms:checkbox name="includeBuildsData"/>
                <label for="includeBuildsData" >Builds and changes history</label>
                <span class="smallNote">Builds and changes history as well as all build-related data will be included.</span>
              </div>
              <div>
                <label>Users <bs:helpLink file="ProjectImport-ImportUsersAndGroups"><bs:helpIcon/></bs:helpLink></label>
                <span class="smallNote">Users, audit records and other user-related data will be included.</span>

                <div class="nested">
                  <forms:checkbox name="importNewUsers"/>
                  <label for="importNewUsers" >Import new users</label>
                </div>

                <div class="nested">
                  <forms:checkbox name="importConflictingUsersWithSameVerifiedEmail"/>
                  <label for="importConflictingUsersWithSameVerifiedEmail" >
                    Merge users with the same username and the same verified email
                    <c:if test="${conflictingUsersWithSameVerifiedEmailCount > 0}">
                      (<a href="#" title='Show users' onclick="BS.ProjectsImport.ConflictingUsersWithSameVerifiedEmailDialog.showCentered(); return false;">${conflictingUsersWithSameVerifiedEmailCount} user<bs:s val="${conflictingUsersWithSameVerifiedEmailCount}"/>)</a>
                    </c:if>
                  </label>
                </div>

                <div class="nested">
                  <forms:checkbox name="importConflictingUsersWithSameNotVerifiedEmail"/>
                  <label for="importConflictingUsersWithSameNotVerifiedEmail" >
                    Merge users with the same username and the same not verified email
                    <c:if test="${conflictingUsersWithSameNotVerifiedEmailCount > 0}">
                      (<a href="#" title='Show users' onclick="BS.ProjectsImport.ConflictingUsersWithSameNotVerifiedEmailDialog.showCentered(); return false;">${conflictingUsersWithSameNotVerifiedEmailCount} user<bs:s val="${conflictingUsersWithSameNotVerifiedEmailCount}"/>)</a>
                    </c:if>
                  </label>
                </div>

                <div class="nested">
                  <forms:checkbox name="importConflictingUsersWithDifferentEmail"/>
                  <label for="importConflictingUsersWithDifferentEmail" >
                    Merge users with the same username but different email
                    <c:if test="${conflictingUsersWithDifferentEmailCount > 0}">
                      (<a href="#" title='Show users' onclick="BS.ProjectsImport.ConflictingUsersWithDifferentEmailDialog.showCentered(); return false;">${conflictingUsersWithDifferentEmailCount} user<bs:s val="${conflictingUsersWithDifferentEmailCount}"/>)</a>
                    </c:if>
                  </label>
                </div>

              </div>
              <div>
                <label>Groups <bs:helpLink file="ProjectImport-ImportUsersAndGroups"><bs:helpIcon/></bs:helpLink></label>
                <span class="smallNote">User groups with related data will be included.</span>

                <div class="nested">
                  <forms:checkbox name="importNewGroups"/>
                  <label for="importNewGroups" >Import new groups</label>
                </div>

                <div class="nested">
                  <forms:checkbox name="mergeExistingGroups"/>
                  <label for="mergeExistingGroups" >
                    Merge groups with the same group key
                    <c:if test="${conflictingGroupsCount > 0}">
                      (<a href="#" title='Show groups' onclick="BS.ProjectsImport.ConflictingGroupsDialog.showCentered(); return false;">${conflictingGroupsCount} group<bs:s val="${conflictingGroupsCount}"/>)</a>
                    </c:if>
                  </label>
                </div>
              </div>

            </div>
            <span class="error" id="projectImportUnexpectedError"></span>
          </td>
        </tr>
      </table>

    </c:otherwise>
  </c:choose>

  <div class="saveButtonsBlock">
    <input type="hidden" name="selectedScope" value="true"/>
    <input type="hidden" name="selectedUsernames"/>
    <forms:submit id="startImportButton" label="Start Import" disabled="true"/>
    <forms:cancel label="Cancel" onclick="BS.ProjectsImport.cancelCurrentTask()"/>
    <forms:saving id="startImportProgress" savingTitle="Preparing to import..."/>
  </div>
</form>


<script type="text/javascript">
  BS.ProjectsImport.ConfigureImportForm.init(${configureImportStep.dbDataAvailable}, ${configureImportStep.configsAvailable}, ${conflictingUsersWithSameVerifiedEmailCount}, ${conflictingUsersWithSameNotVerifiedEmailCount}, ${conflictingUsersWithDifferentEmailCount});
</script>



<%--Conflicting users modal dialogs--%>
<bs:dialog dialogClass="conflictsDialog" dialogId="conflictingUsersWithSameVerifiedEmailDialog" title="Users with same verified email and username" closeCommand="BS.ProjectsImport.ConflictingUsersWithSameVerifiedEmailDialog.close()">
  <p>List of users from the backup file who have the same username and verified email as existing user: </p>

  <projectsImport:conflictingUsers conflictingUsers="${configureImportStep.usersWithSameVerifiedEmail}"/>

  <div class="popupSaveButtonsBlock">
    <forms:submit type="button" label="Close" onclick="BS.ProjectsImport.ConflictingUsersWithSameVerifiedEmailDialog.close()"/>
  </div>
</bs:dialog>

<bs:dialog dialogClass="conflictsDialog" dialogId="conflictingUsersWithSameNotVerifiedEmailDialog" title="Users with same not verified email and username" closeCommand="BS.ProjectsImport.ConflictingUsersWithSameNotVerifiedEmailDialog.close()">
  <p>List of users from the backup file who have the same username and not verified email as existing user: </p>

  <projectsImport:conflictingUsers conflictingUsers="${configureImportStep.usersWithSameNotVerifiedEmail}"/>

  <div class="popupSaveButtonsBlock">
    <forms:submit type="button" label="Close" onclick="BS.ProjectsImport.ConflictingUsersWithSameNotVerifiedEmailDialog.close()"/>
  </div>
</bs:dialog>


<bs:dialog dialogClass="conflictsDialog" dialogId="conflictingUsersWithDifferentEmailDialog" title="Users with same username but different email" closeCommand="BS.ProjectsImport.ConflictingUsersWithDifferentEmailDialog.close()">
  <p>List of users from the backup file who have the same username as existing user but different email:</p>

  <projectsImport:conflictingUsers conflictingUsers="${configureImportStep.usersWithDifferentEmail}"/>

  <div class="popupSaveButtonsBlock">
    <forms:submit type="button" label="Close" onclick="BS.ProjectsImport.ConflictingUsersWithDifferentEmailDialog.close()"/>
  </div>
</bs:dialog>

<%--Conflicting groups modal dialog--%>
<bs:dialog dialogClass="conflictsDialog" dialogId="conflictingGroupsDialog" title="Conflicting groups" closeCommand="BS.ProjectsImport.ConflictingGroupsDialog.close()">
  <p>List of groups from the backup file having the same key as existing group:</p>

  <table class="dark conflictingUsersTable">
    <tr>
      <th>Group Key</th>
      <th>Group from the backup file</th>
      <th>Group from this TeamCity server</th>
    </tr>
  </table>
  <div class="conflictsList">
    <table class="dark conflictingUsersTable borderBottom">
      <c:forEach items="${configureImportStep.conflictingGroups}" var="conflictingGroup">

        <tr>
          <td><c:out value="${conflictingGroup.key}"/></td>
          <td>
            Name: <bs:defaultIfEmpty><c:out value="${conflictingGroup.importedGroup.name}"/></bs:defaultIfEmpty> <br/>
            Description: <bs:defaultIfEmpty><c:out value="${conflictingGroup.importedGroup.description}"/></bs:defaultIfEmpty> <br/>
          </td>
          <td>
            Name: <bs:defaultIfEmpty><c:out value="${conflictingGroup.existingGroup.name}"/></bs:defaultIfEmpty> <br/>
            Description: <bs:defaultIfEmpty><c:out value="${conflictingGroup.existingGroup.description}"/></bs:defaultIfEmpty><br/>
          </td>
        </tr>
      </c:forEach>
    </table>
  </div>

  <div class="popupSaveButtonsBlock">
    <forms:submit type="button" label="Close" onclick="BS.ProjectsImport.ConflictingGroupsDialog.close()"/>
  </div>
</bs:dialog>

<%--Conflicts in projects modal dialog--%>
<bs:dialog dialogClass="conflictsDialog" dialogId="projectsConflictsDialog" title="Conflicts" closeCommand="BS.ProjectsImport.ProjectsConflictsDialog.close()">
  <p>
    TeamCity founds ${configureImportStep.unresolvableConflictsCount} conflict<bs:s val="${configureImportStep.unresolvableConflictsCount}"/>.
    It is highly recommended to resolve <c:choose><c:when test="${configureImportStep.unresolvableConflictsCount > 1}">them</c:when><c:otherwise>it</c:otherwise></c:choose> before proceeding with import.<bs:help file="Projects+Import+Conflicts"/>
  </p>
  <div class="conflictsList">
    <c:forEach items="${configureImportStep.unresolvableConflictsPerProject}" var="entry">Conflicts for '<c:out value="${entry.key.fullName}"/>' project:
      <ul><c:forEach items="${entry.value}" var="conflict"><li><c:out value="${conflict.description}"/></li></c:forEach></ul>
    </c:forEach>
  </div>

  <div class="popupSaveButtonsBlock">
    <forms:submit type="button" label="Close" onclick="BS.ProjectsImport.ProjectsConflictsDialog.close()"/>
  </div>

</bs:dialog>
