<%@include file="/include-internal.jsp"%>
<jsp:useBean id="triggerService" type="jetbrains.buildServer.buildTriggers.BuildTriggerService" scope="request"/>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>

<c:set var="showBuildCustomizationTab" value="${triggerService.supportsBuildCustomization()}"/>

<c:if test="${showBuildCustomizationTab}">
  <script type="text/javascript">
    var tabs = new TabbedPane("triggerTabs");
    tabs.addTab('triggerSettings', {
      caption: 'Triggering Settings',
      url: '#',
      onselect: function () {
        $j('#triggerSettings').show();
        $j('#buildCustomization').hide();
        return false;
      }
    });
    tabs.addTab('buildCustomization', {
      caption: 'Build Customization',
      url: '#',
      onselect: function () {
        $j('#triggerSettings').hide();
        $j('#buildCustomization').show();
        return false;
      }
    });
    tabs.showIn('triggerSettingsTabs');
    tabs.setActiveCaption('triggerSettings');
  </script>

  <div id="triggerSettingsTabs" class="simpleTabs clearfix"></div>
</c:if>

<div id="triggerSettings">
  <div id="triggerParamsTable">
    <table class="runnerFormTable" style="width: 99%;">
      <c:if test="${not empty triggerService.editParametersUrl}">
        <jsp:include page="${triggerService.editParametersUrl}"/>
      </c:if>
    </table>
  </div>

  <admin:showHideAdvancedOpts containerId="editTriggerDialog" optsKey="buildTriggers"/>
  <admin:highlightChangedFields containerId="editTriggerDialog"/>
</div>

<c:if test="${showBuildCustomizationTab}">
  <%--@elvariable id="triggerDescriptorBean" type="jetbrains.buildServer.controllers.admin.projects.BuildTriggerDescriptorBean"--%>
  <div id="buildCustomization" style="width: 99%; display: none;">
    <table class="runnerFormTable">
      <tr>
        <td colspan="3" class="noBorder">
          <span class="grayNote">Specify settings that are applied to builds started by this trigger</span>
        </td>
      </tr>
      <tr class="groupingTitle">
        <td colspan="3">General settings</td>
      </tr>
      <tr>
          <c:choose>
            <c:when test="${buildForm.compositeBuild}">
              <tr>
                <td colspan="3" class="noBorder">
                  <forms:checkbox name="enforceCleanCheckoutForDependencies" checked="${triggerDescriptorBean.enforceCleanCheckoutForDependencies}"/>
                              <label for="enforceCleanCheckoutForDependencies">Delete all files in checkout directory before each snapshot dependency build</label>
                </td>
              </tr>
            </c:when>
            <c:otherwise>
              <tr>
                <td colspan="3" class="noBorder">
                  <forms:checkbox name="enforceCleanCheckout" checked="${triggerDescriptorBean.enforceCleanCheckout}" onclick="if (!this.checked) $j('#enforceCleanCheckoutForDependencies').prop('checked', false)"/>
                  <label for="enforceCleanCheckout">Delete all files in the checkout directory before the build</label>
                </td>
              </tr>
              <tr>
                <td colspan="3" class="noBorder">
                  <div style="padding-left: 1.5em; margin-top: -0.5em">
                    <forms:checkbox name="enforceCleanCheckoutForDependencies" checked="${triggerDescriptorBean.enforceCleanCheckoutForDependencies}" onclick="if (this.checked) $j('#enforceCleanCheckout').prop('checked', true)"/>
                    <label for="enforceCleanCheckoutForDependencies">apply to all snapshot dependencies</label>
                  </div>
                </td>
              </tr>
            </c:otherwise>
          </c:choose>


    </table>
    <table id="customParametersTable" class="runnerFormTable buildParameters non_serializable_form_elements_container">
      <tr class="groupingTitle">
        <td colspan="3">Build parameters</td>
      </tr>

      <tr id="newCustomParameterRow">
        <td class="addParameterCell paramName">
          <label for="customParameterSelector">Add parameter:</label>
        </td>
        <td class="addParameterCell" >
          <div>
            <forms:select name="customParameterSelector"
                          enableFilter="true"
                          style="width: 300px"
                          onchange="BS.EditTriggersDialog.customParameterSelected($('customParameterSelector').options[$('customParameterSelector').selectedIndex].value);">
              <option value="">-- Choose a parameter --</option>
              <option>&lt;Add new&gt;</option>
              <c:forEach items="${triggerDescriptorBean.buildParameters}" var="parameter">
                <forms:option value="${parameter.id}"><c:out value="${parameter.label}"/></forms:option>
              </c:forEach>
            </forms:select>
          </div>
        </td>
        <td class="edit"/>
      </tr>
      <tr id="selectedParametersHeader" hidden>
        <th colspan="3" class="noBorder">
          Selected parameters
        </th>
      </tr>
    </table>

    <script type="text/javascript">
      BS.EditTriggersDialog.customBuildParametersIds = [];
      <c:forEach var="p" items="${triggerDescriptorBean.buildParameters}">
        <c:if test="${p.custom}">
            BS.EditTriggersDialog.customBuildParametersIds.push("${p.id}");
        </c:if>
      </c:forEach>
    </script>

    <div id="hiddenParamsContainer" class="non_serializable_form_elements_container" hidden>
      <c:forEach items="${triggerDescriptorBean.buildParameters}" var="parameter">
        <forms:option className="buildParameterOption_${parameter.id}" value="${parameter.id}"><c:out value="${parameter.label}"/></forms:option>
      </c:forEach>

      <table>
        <c:forEach var="p" items="${triggerDescriptorBean.buildParameters}">
          <tr id="customParam_${p.id}">
            <td class="paramName">
              <c:set var="safeName"><c:out value="${p.parameter.name}" /></c:set>
              <label class="paramName__label" for="${p.id}" title="parameter name: ${safeName}"><bs:trim maxlength="25"><c:out value="${p.label}"/></bs:trim></label>
            </td>
            <td class="paramValue">
              <div class="completionIconWrapper">
                <c:set var="jsObject">BS.EditTriggersDialog.CustomControls['<bs:forJs>${p.id}</bs:forJs>']</c:set>
                <c:set var="isCustom" value="${not empty p.parameter.controlDescription}"/>
                <script type="text/javascript">
                  ${jsObject} = BS.EditTriggersDialog.getAddControlFunction('container_${p.id}_div', '${p.id}');
                </script>
                <c:choose>
                  <c:when test="${isCustom}">
                    <ext:typedParameter context="${p.renderContext}" js="${jsObject}"/>
                  </c:when>
                  <c:otherwise>
                    <forms:textField expandable="true" style="width: 100%;" name="${p.id}" id="${p.id}" value="${p.parameter.value}" className="buildTypeParams"/>
                  </c:otherwise>
                </c:choose>
                <c:if test="${not empty p.description}"><span class="smallNote"><c:out value="${p.description}"/></span></c:if>
                <span class="error" id="error_${p.id}"></span>
              </div>
            </td>
            <td class="edit">
              <a href="#" onclick="BS.EditTriggersDialog.removeBuildParameter('${p.id}'); return false;">Remove</a>
            </td>
          </tr>

        </c:forEach>
        <tr id="customParam_new" class="customParam_new">
          <td class="paramName">
            <forms:textField name="new-parameter-name" value="" style="width: 100%;"/>
          </td>
          <td class="paramValue">
            <div class="completionIconWrapper">
              <forms:textField expandable="true" style="width: 100%;" name="new-parameter-value" className="disableBuildTypeParams"/>
            </div>
          </td>
          <td class="edit">
            <a href="#" onclick="BS.EditTriggersDialog.removeNewParameter(this); return false;">Remove</a>
          </td>
        </tr>
      </table>
    </div>

  </div>

  <script type="text/javascript">
    BS.EditTriggersDialog.initBuildParametersView();
  </script>
</c:if>

<c:choose>
  <c:when test="${buildForm.readOnly}">
    <script type="text/javascript">$('triggerSaveButtonsBlock').hide(); BS.EditTriggersDialog.setReadOnly([{name: 'triggerNameSelector'}, {className: 'submitButton'}])</script>
  </c:when>
  <c:otherwise><script type="text/javascript">$('triggerSaveButtonsBlock').show()</script></c:otherwise>
</c:choose>

