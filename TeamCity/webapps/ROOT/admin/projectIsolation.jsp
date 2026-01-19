<%@include file="/include-internal.jsp" %>
<jsp:useBean id="projectIsolationBean" type="jetbrains.buildServer.controllers.admin.projects.ProjectIsolationBean" scope="request"/>

<c:url var="projectIsolationActionUrl" value="/admin/projectIsolation.html"/>

<bs:refreshable containerId="trustedDependenciesList" pageUrl="${pageUrl}">
  <h2 class="noBorder">Project Isolation</h2>
  <bs:smallNote>
    Other TeamCity projects can depend on your project's configurations, triggering upstream builds and importing their artifacts.
    Use this page to restrict dependencies to trusted projects only. <bs:help file="project-isolation"/>
  </bs:smallNote>

  <c:set var="userShowInheritedPropName" value="showInheritedExemptions"/>
  <c:set var="userShowSubprojectsPropName" value="showSubprojectsExemptions"/>
  <c:set var="userShowArchivedSubprojectsPropName" value="showArchivedSubprojectsExemptions"/>
  <c:set var="showInherited" value="${ufn:booleanPropertyValue(currentUser, userShowInheritedPropName)}"/>
  <c:set var="showArchivedSubprojects" value="${ufn:booleanPropertyValue(currentUser, userShowArchivedSubprojectsPropName)}"/>
  <c:set var="showSubprojects" value="${ufn:booleanPropertyValue(currentUser, userShowSubprojectsPropName) or showArchivedSubprojects}"/>
  <c:set var="numInherited" value="${projectIsolationBean.inheritedTrustedProjects.size()}"/>
  <c:set var="ownTrustedProjects" value="${projectIsolationBean.ownTrustedProjects.get(currentProject)}"/>
  <c:set var="visibleTrustedProjects" value="${showSubprojects ? projectIsolationBean.trustedProjectsFromSubprojects : projectIsolationBean.ownTrustedProjects}"/>
  <c:set var="inheritedTrustedProjectsList" value="${projectIsolationBean.inheritedTrustedProjects}"/>
  <c:set var="canEditProject" value="${projectIsolationBean.canEditProject}"/>
  <c:set var="dependencyCheckMode" value="${projectIsolationBean.dependencyCheckMode}"/>
  <c:set var="modeProhibitedFromEditing" value="${projectIsolationBean.modeProhibitedFromEditing}"/>
  <c:set var="nearestHardModeParent" value="${projectIsolationBean.projectDependencyCheckSettings.nearestHardModeParent}"/>
  <c:set var="tableStyle" value="${(dependencyCheckMode eq 'SOFT_MODE' and empty nearestHardModeParent) ? 'color: #A8ADBD;' : ''}"/>

  <br/>
  <label>Projects that can depend on this project's configurations</label>
  <form id="projectDependencyCheckModeForm">
    <div class="projectDependencyCheckModeRadioBlock" style="padding-top: 0.5em">
      <label class="ring-radio-radio" for="softMode">
        <input id="softMode"
               name="projectDependencyCheckModeRadio"
               type="radio"
               value="SOFT_MODE"
               <c:if test="${dependencyCheckMode eq 'SOFT_MODE'}" >checked</c:if>
               <c:if test="${modeProhibitedFromEditing}" >disabled</c:if>
               class="ring-radio-input"/>
        <span class="ring-radio-circle"></span>
        <span class="ring-radio-label">
          <c:choose>
            <c:when test="${not empty nearestHardModeParent}">
              Inherit settings from a parent project
            </c:when>
            <c:otherwise>
              All projects
            </c:otherwise>
          </c:choose>
        </span>
      </label>
      <div style="margin-left: calc(var(--ring-unit) * 3); margin-bottom: var(--ring-unit)">
        <bs:smallNote>
          <c:choose>
            <c:when test="${not empty nearestHardModeParent}">
              Inherit the list of trusted projects from the closest parent with the "Only trusted projects" behavior
              <br/>
              (Project <admin:editProjectLinkFull project="${nearestHardModeParent}" contextProject="${currentProject}" addToUrl="&tab=projectIsolation"/>)
            </c:when>
            <c:otherwise>
              Any TeamCity configuration can have a snapshot or artifact dependency on this project's configurations.
            </c:otherwise>
          </c:choose>
        </bs:smallNote>
      </div>
      <label class="ring-radio-radio" for="hardMode">
        <input id="hardMode"
               name="projectDependencyCheckModeRadio"
               type="radio"
               value="HARD_MODE"
               <c:if test="${dependencyCheckMode eq 'HARD_MODE'}" >checked</c:if>
               <c:if test="${modeProhibitedFromEditing}" >disabled</c:if>
               class="ring-radio-input"/>
        <span class="ring-radio-circle"></span>
        <span class="ring-radio-label">Only trusted projects</span>
      </label>
      <div style="margin-left: calc(var(--ring-unit) * 3); margin-bottom: var(--ring-unit)">
        <bs:smallNote>
          Only configurations from projects explicitly added to the list below can depend on this project's configurations.
          Other configurations will fail or be unable to retrieve the required artifacts.
        </bs:smallNote>
      </div>
    </div>
    <forms:submit type="button" label="Save" disabled="${modeProhibitedFromEditing}" onclick="BS.ProjectDependencyCheckModeForm.saveDependencyCheckMode()"/>
    <forms:saving id="saveModeProgress" style="float:none"/>
  </form>
  <bs:modalDialog formId="hardModeSelectionForm"
                  title="Confirmation"
                  action=""
                  closeCommand="BS.HardModeSelectionDialog.close()"
                  saveCommand="false">
    <div>
      <span>Switching to "Only trusted projects" may break builds of dependent projects that are not on the trusted list. Are you sure you want to proceed?</span>
      <br/>
      <div class='collectUsagesContainer' style='margin-top: 1em; margin-bottom: 1em'>
        <forms:checkbox id='collectUsagesCheckboxNew' name="collectUsagesCheckboxNew" checked="true"/>
        <label for='collectUsagesCheckboxNew'>Add currently dependent projects to the list</label>
        <bs:help file="project-isolation-trust-list"/>
        <forms:saving id="collectUsagesProgress" className="progressRingInline"/>
      </div>
    </div>
    <forms:submit label="OK" onclick="BS.HardModeSelectionDialog.confirm(); return false;"/>
    <forms:cancel onclick="BS.HardModeSelectionDialog.close()"/>
  </bs:modalDialog>
  <script type="text/javascript">
    BS.HardModeSelectionDialog = OO.extend(BS.AbstractModalDialog, {
      getContainer: function() {
        return $('hardModeSelectionFormDialog');
      },

      confirm: function() {
        BS.ProjectDependencyCheckModeForm.setDependencyCheckMode('HARD_MODE', $j('#collectUsagesCheckboxNew').is(':checked'));
      }
    });

    BS.ProjectDependencyCheckModeForm = OO.extend(BS.AbstractWebForm, {
      getFormElement: function () {
        return $('projectDependencyCheckModeForm');
      },

      saveDependencyCheckMode: function () {
        const radio = $j('input[name="projectDependencyCheckModeRadio"]');
        const mode = radio.filter(":checked").val();

        if (mode === 'SOFT_MODE') {
          this.setDependencyCheckMode(mode, false);
          return;
        }

        BS.HardModeSelectionDialog.showCentered();
      },

      setDependencyCheckMode: function (mode, collectUsages) {
        BS.Util.hideSuccessMessages();
        BS.Util.show('saveModeProgress');
        if (collectUsages) {
          BS.Util.show('collectUsagesProgress');
        }

        BS.ajaxRequest('${projectIsolationActionUrl}', {
          method: 'POST',
          parameters: {
            projectId: "<c:out value="${currentProject.projectId}"/>",
            dependencyCheckMode: mode,
            collectUsages: collectUsages
          },
          onComplete: function (transport) {
            BS.Util.hide('saveModeProgress');
            if (collectUsages) {
              BS.Util.hide('collectUsagesProgress');
            }
            if (transport.responseXML && transport.responseXML.firstChild) {
              var response = transport.responseXML.firstChild;
              var error = response.getElementsByTagName("error")[0];
              if (error) {
                alert("Cannot set behavior on adding untrusted dependency: " + error.firstChild.data);
              } else {
                if (collectUsages) {
                  alert("Currently dependent projects processed successfully")
                }
                reloadPage();
              }
            } else {
              reloadPage();
            }
          }
        });
      }
    });

    function reloadPage() {
      BS.HardModeSelectionDialog.close();
      BS.AddTrustedDependenciesForm.close();
      $('trustedDependenciesList').refresh();
    }
  </script>

  <div class="actionBar" style="margin-top: var(--ring-line-height)">
    <c:if test="${numInherited gt 0}">
      <profile:booleanPropertyCheckbox propertyKey="${userShowInheritedPropName}"
                                       labelText="Show ${numInherited} inherited trusted dependencies"
                                       afterComplete="BS.TrustedDependenciesActions.toggleInheritedDependencies($('${userShowInheritedPropName}').checked, 'trustedDependenciesList');"/>
    </c:if>
    <profile:booleanPropertyCheckbox propertyKey="${userShowSubprojectsPropName}" labelText="Show trusted dependencies from subprojects"
                                     onclick="if (!this.checked && $('showArchivedSubprojects').checked) $('showArchivedSubprojects').click()" afterComplete="reloadPage();" controlId="showSubprojects"/>
    (<profile:booleanPropertyCheckbox propertyKey="${userShowArchivedSubprojectsPropName}" labelText="show archived subprojects"
                                      onclick="if (this.checked && !$('showSubprojects').checked) $('showSubprojects').click()" afterComplete="reloadPage();" controlId="showArchivedSubprojects"/>)
  </div>

  <c:if test="${showSubprojects ? not empty visibleTrustedProjects : not empty ownTrustedProjects}">
    <br/>
    <c:set var="prevProject" value="${null}"/>
    <div class="ownTrustedProjectsBlock">
      <h3>Trusted dependencies</h3>
      <l:tableWithHighlighting className="parametersTable" id="ownTrustedProjectsTable" highlightImmediately="true" style="${tableStyle}">
        <tr>
          <c:choose>
            <c:when test="${showSubprojects}">
              <th>Project</th>
              <th colspan="3">Trusted project</th>
            </c:when>
            <c:otherwise>
              <th colspan="3">Trusted project</th>
            </c:otherwise>
          </c:choose>
        </tr>
        <c:forEach var="projectEntry" items="${visibleTrustedProjects.entrySet()}">
          <c:set var="projectHavingExemptions" value="${projectEntry.key}"/>
          <c:set var="exemptions" value="${projectEntry.value}"/>
          <c:if test="${not projectHavingExemptions.archived or showArchivedSubprojects}">
            <c:forEach var="exemption" items="${exemptions}">
              <c:set var="trustedProject" value="${exemption.project}"/>
              <c:set var="exemptionAccessible" value="${exemption.accessible}"/>
              <tr>
                <c:if test="${showSubprojects and projectHavingExemptions ne prevProject}">
                  <td rowspan="${exemptions.size()}">
                    <admin:editProjectLinkFull project="${projectHavingExemptions}" contextProject="${currentProject}" style="${tableStyle}"/>
                    <c:if test="${projectHavingExemptions.archived}"><i class="archived_project"> (archived)</i></c:if>
                  </td>
                  <c:set var="prevProject" value="${projectHavingExemptions}"/>
                </c:if>
                <td class="highlight beforeActions">
                  <c:choose>
                    <c:when test="${exemptionAccessible}">
                      <admin:editProjectLinkFull project="${trustedProject}" contextProject="${currentProject}" style="${tableStyle}"/>
                      <c:if test="${trustedProject.archived}"><i class="archived_project"> (archived)</i></c:if>
                    </c:when>
                    <c:otherwise>
                      <span class="greyNote">&lt;<c:out value="${exemption.inaccessibleReason}"/>&gt;</span>
                    </c:otherwise>
                  </c:choose>
                </td>
                <td class="edit highlight">
                  <c:if test="${exemptionAccessible}">
                    <c:url value='/admin/editProject.html?tab=usagesReport&projectId=${currentProject.externalId}&trustedProjectExternalId=${trustedProject.externalId}'
                           var="trustedDependencyUsagesUrl"/>
                    <a href="${trustedDependencyUsagesUrl}" style="white-space: nowrap">View usage</a>
                  </c:if>
                </td>
                <td class="edit highlight">
                  <c:choose>
                    <c:when test="${canEditProject}">
                      <c:set var="dialogDisplayProjectName">
                        <c:choose>
                          <c:when test="${exemptionAccessible}">${trustedProject.name}</c:when>
                          <c:otherwise>project with id ${exemption.internalId}</c:otherwise>
                        </c:choose>
                      </c:set>
                      <a href="#"
                         onclick="BS.TrustedDependenciesActions.removeTrustedDependency(
                             '${projectHavingExemptions.projectId}',
                             '${util:forJS(projectHavingExemptions.name, true, true)}',
                             '${exemption.internalId}',
                             '${util:forJS(dialogDisplayProjectName, true, true)}');
                             return false">Remove</a>
                    </c:when>
                    <c:otherwise>
                      undeletable
                    </c:otherwise>
                  </c:choose>
                </td>
              </tr>
            </c:forEach>
          </c:if>
        </c:forEach>
      </l:tableWithHighlighting>
    </div>
  </c:if>

  <c:if test="${not empty inheritedTrustedProjectsList}">
    <div class="inheritedTrustedProjectsBlock">
      <br/>
      <h3>Inherited trusted dependencies</h3>
      <l:tableWithHighlighting className="parametersTable" id="inheritedTrustedProjectsTable" highlightImmediately="true">
        <tr>
          <th colspan="2">Trusted project</th>
        </tr>
        <c:forEach var="inheritedTrustedProject" items="${inheritedTrustedProjectsList}">
          <tr class="inherited">
            <c:set var="trustedProject" value="${inheritedTrustedProject.trustedProject}"/>
            <c:set var="settingsViewable" value="${trustedProject.accessible and afn:permissionGrantedForProject(trustedProject.project, 'VIEW_BUILD_CONFIGURATION_SETTINGS')}"/>
            <td class="highlight beforeActions">
              <c:choose>
                <c:when test="${trustedProject.accessible}">
                  <c:choose>
                    <c:when test="${settingsViewable}">
                      <admin:editProjectLinkFull project="${trustedProject.project}" contextProject="${currentProject}" style="${tableStyle}"/>
                    </c:when>
                    <c:otherwise>
                      <c:out value="${trustedProject.project.name}"/>
                    </c:otherwise>
                  </c:choose>
                  (inherited from <admin:editProjectLinkFull project="${inheritedTrustedProject.inheritanceOrigin}" contextProject="${currentProject}" style="${tableStyle}"/>)
                </c:when>
                <c:otherwise>
                  <span class="greyNote">&lt;<c:out value="${trustedProject.inaccessibleReason}"/>&gt;
                    (inherited from <admin:editProjectLinkFull project="${inheritedTrustedProject.inheritanceOrigin}" contextProject="${currentProject}" style="${tableStyle}"/>)</span>
                </c:otherwise>
              </c:choose>
            </td>
            <td class="edit highlight">
              undeletable
            </td>
          </tr>
        </c:forEach>
      </l:tableWithHighlighting>
    </div>
  </c:if>
</bs:refreshable>

<c:if test="${canEditProject and currentProject.projectId ne '_Root'}">
  <div>
    <forms:addButton onclick="return BS.AddTrustedDependenciesForm.showDialog()">Add new trusted project</forms:addButton>
  </div>
</c:if>

<bs:refreshable containerId="addingTrustedDependenciesDialog" pageUrl="${pageUrl}&addTrustedDepsDialog=true">

  <bs:modalDialog formId="addTrustedDependenciesForm"
                  title="Add new trusted project"
                  action=""
                  closeCommand="BS.AddTrustedDependenciesForm.close()"
                  saveCommand="false">
    <p>Select projects to mark as trusted</p>

    <div id="projectsSelector"></div>
    <div id="projectsSelectorResult" style="visibility: hidden; height: 0px;"></div>

    <div class="popupSaveButtonsBlock">
      <forms:button id="addTrustedDependenciesButton" onclick="BS.AddTrustedDependenciesForm.submit(); return false;" className="btn_primary">Save</forms:button>
      <forms:button id="addTrustedDependenciesCloseButton" onclick="BS.AddTrustedDependenciesForm.close(); return false;">Close</forms:button>
      <forms:saving id="addTrustedDependenciesProgress"/>
    </div>

    <script type="text/javascript">
      {
        let checkedItems = null;

        BS.AddTrustedDependenciesForm = OO.extend(BS.AbstractModalDialog, {

          getContainer: function () {
            return $j('#addTrustedDependenciesFormDialog')[0];
          },

          showDialog: function () {
            this.showCentered();
            return false;
          },

          submit: function () {
            BS.ajaxRequest('${projectIsolationActionUrl}', {
              method: 'POST',
              parameters: {
                projectsToAdd: checkedItems == null ? '' : checkedItems.join(':'),
                projectId: "<c:out value="${currentProject.projectId}"/>"
              },
              onComplete: function (transport) {
                if (transport.responseXML && transport.responseXML.firstChild) {
                  var response = transport.responseXML.firstChild;
                  var error = response.getElementsByTagName("error")[0];
                  if (error) {
                    alert("Cannot add trusted dependencies: " + error.firstChild.data);
                  } else {
                    reloadPage();
                  }
                } else {
                  reloadPage();
                }
              }
            });

            return false;
          },

        });

        BS.TrustedDependenciesActions = {
          removeTrustedDependency: function (sourceProjectId, sourceProjectName, trustedProjectId, trustedProjectName) {
            BS.confirmDialog.show({
              title: "Remove trusted project",
              text: "Are you sure you want to remove trusted project " + trustedProjectName.escapeHTML() + " from " + sourceProjectName.escapeHTML() + "?",
              actionButtonText: "Remove",
              action: function () {
                this._removeTrustedDependency(sourceProjectId, trustedProjectId);
              }.bind(this)
            });
            return false;
          },

          _removeTrustedDependency: function (sourceProjectId, trustedProjectId) {
            BS.Util.hideSuccessMessages();
            BS.ajaxRequest('${projectIsolationActionUrl}', {
              method: 'POST',
              parameters: {
                projectId: sourceProjectId,
                projectToRemove: trustedProjectId
              },
              onComplete: function (transport) {
                if (transport.responseXML && transport.responseXML.firstChild) {
                  var response = transport.responseXML.firstChild;
                  var error = response.getElementsByTagName("error")[0];
                  if (error) {
                    alert("Cannot remove trusted dependency: " + error.firstChild.data);
                  } else {
                    reloadPage();
                  }
                } else {
                  reloadPage();
                }
              }
            })
          },

          toggleInheritedDependencies: function (show, containerId) {
            $j('#' + containerId + ' .inheritedTrustedProjectsBlock').each(function () {
              if (show) {
                this.show();
              } else {
                this.hide();
              }
            });
          }
        };

        ReactUI.renderConnected(document.getElementById('projectsSelector'), ReactUI.ProjectBuildTypeSelect, {
          buildTypesSelectable: false,
          projectsSelectable: true,
          multiselect: true,
          propagateCheck: false,
          includeRoot: false,
          disabledProjects: [
            "<c:out value="${currentProject.externalId}"/>",

            <c:forEach var="trustedProject" items="${ownTrustedProjects}">
            <c:if test="${trustedProject.accessible}">
            "${trustedProject.project.externalId}",
            </c:if>
            </c:forEach>

            <c:forEach var="inheritedTrustedProject" items="${inheritedTrustedProjectsList}">
            <c:set var="trustedProject" value="${inheritedTrustedProject.trustedProject}"/>
            <c:if test="${trustedProject.accessible}">
            "${trustedProject.project.externalId}",
            </c:if>
            </c:forEach>
          ],

          onCheck(items) {
            checkedItems = items.map((item) => item.internalId);
          }
        });

        <c:if test="${not showInherited and not empty inheritedTrustedProjectsList}">
        BS.TrustedDependenciesActions.toggleInheritedDependencies(false, 'trustedDependenciesList');
        </c:if>
      }
    </script>
  </bs:modalDialog>
</bs:refreshable>
