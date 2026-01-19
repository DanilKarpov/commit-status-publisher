<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>

<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>
<c:set var="buildTriggersBean" value="${buildForm.buildTriggerDescriptorBean}"/>
<admin:editBuildTypePage selectedStep="buildTriggers">
  <jsp:attribute name="head_include">
    <bs:linkCSS>
      /css/admin/editTriggers.css
    </bs:linkCSS>
    <script type="text/javascript">
      <c:forEach items="${buildTriggersBean.allTriggerServices}" var="tr">
        BS.EditTriggersDialog.allTriggerServicesDisplayNames['${tr.name}'] = '<bs:escapeForJs text="${tr.displayName}"/>';
      </c:forEach>
      <c:forEach items="${buildTriggersBean.triggers}" var="tr">
        BS.EditTriggersDialog.allTriggersNames['${tr.id}'] = '<bs:escapeForJs text="${tr.triggerName}"/>';
      </c:forEach>
    </script>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <div class="section noMargin">
      <h2 class="noBorder">Triggers</h2>
      <bs:smallNote>
        Triggers are used to add builds to the queue either when an event occurs (like a VCS check-in) or periodically with some configurable interval.<bs:help file="Configuring+Build+Triggers"/>
      </bs:smallNote>

      <c:if test="${not buildForm.readOnly}">
      <div>
        <forms:addButton onclick="return BS.EditTriggersDialog.showAddDialog();" showdiscardchangesmessage="false">Add new trigger</forms:addButton>
      </div>
      </c:if>

      <c:if test="${not empty buildTriggersBean.triggers}">
        <l:tableWithHighlighting highlightImmediately="true" id="buildTriggersTable" className="parametersTable">
          <tr>
            <th class="buildTriggersTable__first-column">Trigger</th>
            <th colspan="${buildForm.readOnly ? 2 : 3}">Parameters Description</th>
          </tr>
          <c:forEach items="${buildTriggersBean.triggers}" var="trigger">
            <c:set var="onclick">onclick="BS.EditTriggersDialog.showEditDialog('${trigger.id}'); Event.stop(event)"</c:set>
            <tr>
              <td class="highlight" ${onclick}>
                <admin:triggerInfo trigger="${trigger}" showDescription="false" showInheritanceDescription="${buildTriggersBean.numberOfTemplates > 1}"/>
              </td>
              <td class="highlight beforeActions" ${onclick}>
                <admin:triggerInfo trigger="${trigger}" showName="false"/>
              </td>
              <c:choose>
                <c:when test="${buildForm.readOnly}">
                  <td class="highlight edit" ${onclick}><a href="#" ${onclick}>View</a></td>
                </c:when>
                <c:otherwise>
                  <td class="highlight edit" ${onclick}><a href="#" ${onclick}>Edit</a></td>
                </c:otherwise>
              </c:choose>
              <c:if test="${not buildForm.readOnly}">
              <td class="edit highlight">
                <c:set var="triggerId" value="${fn:replace(trigger.id, '.', '_')}"/>
                <bs:actionsPopup controlId="triggerActions${triggerId}"
                                 popup_options="shift: {x: -150, y: 20}, className: 'quickLinksMenuPopup'">
              <jsp:attribute name="content">
                <div>
                  <ul class="menuList">
                    <c:if test="${trigger.enabled}">
                      <l:li>
                        <a href="#" onclick="BS.AdminActions.setParametersDescriptorEnabled('${buildForm.settingsId}', '${trigger.id}', false, 'Trigger'); return false">Disable trigger</a>
                      </l:li>
                    </c:if>
                    <c:if test="${not trigger.enabled}">
                      <l:li>
                        <a href="#" onclick="BS.AdminActions.setParametersDescriptorEnabled('${buildForm.settingsId}', '${trigger.id}', true, 'Trigger'); return false">Enable trigger</a>
                      </l:li>
                    </c:if>
                    <c:if test="${trigger.inherited and trigger.overridden}">
                      <l:li>
                        <a href="#" onclick="BS.EditTriggersDialog.resetTrigger('${trigger.id}'); return false">Reset</a>
                      </l:li>
                    </c:if>
                    <c:if test="${not trigger.inherited}">
                      <l:li>
                        <a href="#" onclick="BS.EditTriggersDialog.removeTrigger('${trigger.id}'); return false">Delete</a>
                      </l:li>
                    </c:if>
                  </ul>
                </div>
              </jsp:attribute>
                  <jsp:body></jsp:body>
                </bs:actionsPopup>
              </td>
              </c:if>
            </tr>
          </c:forEach>
        </l:tableWithHighlighting>
      </c:if>

      <bs:modalDialog formId="disablingTriggerForm"
                      action=""
                      title=""
                      closeCommand="BS.DisablingTriggerDialog.close()"
                      saveCommand="BS.DisablingTriggerDialog.submitForm()">
        <div class="dialog_content"></div>
        <div style="margin: 5px 0">
          <forms:checkbox name="removeQueued" title="Remove queued builds produced by this trigger" style="vertical-align:middle"/>
          <label style="vertical-align:middle" for="removeQueued">Remove queued builds produced by this trigger</label>
        </div>
        <div class="popupSaveButtonsBlock">
          <forms:submit name="disableTrigger" id="disableTriggerSubmit" label="Disable"/>
          <forms:cancel onclick="BS.DisablingTriggerDialog.close()"/>
        </div>
      </bs:modalDialog>

      <c:url var="actionUrl" value="/admin/editTriggers.html?id=${buildForm.settingsId}"/>
      <bs:modalDialog formId="editTrigger"
                      action="${actionUrl}"
                      title=""
                      closeCommand="BS.EditDsl.closeEditDsl('dialogDslButtons'); BS.EditTriggersDialog.close()"
                      saveCommand="BS.EditTriggersDialog.submitForm()">
        <div class="fragmentEditDsl">
          <div id="dslModeDialog"></div>
        </div>
        <div id="uiModeDialog">
          <div class="edit-trigger-progress-wrapper hidden"><forms:progressRing className="progressRingInline"/>&nbsp;Loading...</div>
          <table class="runnerFormTable">
            <tr>
              <td>
                <forms:select name="triggerNameSelector"
                              enableFilter="true"
                              onchange="BS.EditTriggersDialog.triggerChanged($('triggerNameSelector').options[$('triggerNameSelector').selectedIndex].value);">
                  <option value="">-- Please choose a trigger --</option>
                  <c:forEach items="${buildTriggersBean.availableTriggerServices}" var="triggerService">
                    <forms:option value="${triggerService.name}"><c:out value="${triggerService.displayName}"/></forms:option>
                  </c:forEach>
                </forms:select><forms:saving id="loadParamsProgress" className="progressRingInline"/>
                <div class="error" id="errorBuildTriggerExists"></div>
              </td>
            </tr>
          </table>

          <div id="triggerParams"></div>
          </div>
          <div class="popupSaveButtonsBlock withDslButton" id="triggerSaveButtonsBlock">
            <forms:submit name="editTrigger" id="editTriggerSubmit" label="Save"/>
            <span id="editTriggerAdditionalButtons"></span>
            <forms:cancel onclick="BS.EditDsl.closeEditDsl('dialogDslButtons'); BS.EditTriggersDialog.close()"/>
            <forms:saving id="savingTrigger"/>
            <authz:authorize projectId="${buildForm.project.projectId}" allPermissions="EDIT_PROJECT">
              <input type="hidden" name="showDSL" id="showDSL" value=""/>
              <input type="hidden" name="showDSLVersion" id="showDSLVersion" value=""/>
              <input type="hidden" name="showDSLPortable" id="showDSLPortable" value=""/>
              <div class="dialogDslButtons">
                <div id="dialogDslButtons"></div>
              </div>
              <script type="application/javascript">
                ReactUI.renderShowDslButton('dialogDslButtons', {
                  controlId: 'dialogDslButtons',
                  onShowDsl: function(){
                    ReactUI.renderFragmentDslEditor('dslModeDialog', {
                      currentZindex: BS.Hider._currentZindex(),
                      controlId: 'dialogDslButtons',
                      onFetch: function(version, portable) {
                        BS.EditTriggersDialog.showItemDslWithValues(version, portable, 'BS.EditTriggersDialog', 'dialogDslButtons')
                      }
                    })
                  },
                  onHideDsl: BS.EditDsl.hideEditDslPanel,
                })
              </script>
            </authz:authorize>
            <input type="hidden" name="editMode" value=""/>
            <input type="hidden" name="triggerId" value=""/>
            <input type="hidden" name="triggerName" value=""/>
            <input type="hidden" name="publicKey" id="publicKey" value="${buildForm.publicKey}"/>
        </div>
      </bs:modalDialog>
    </div>

    <script type="text/javascript">
      (function() {
        var parsedHash = BS.Util.paramsFromHash('&');
        if (parsedHash['addTrigger']) {
          BS.Util.setParamsInHash({}, '&', true);
          BS.EditTriggersDialog.showAddDialog(parsedHash['addTrigger']);
        }
        if (parsedHash['editTrigger']) {
          BS.Util.setParamsInHash({}, '&', true);
          BS.EditTriggersDialog.showEditDialog(parsedHash['editTrigger']);
        }
      })();
    </script>
  </jsp:attribute>
</admin:editBuildTypePage>
