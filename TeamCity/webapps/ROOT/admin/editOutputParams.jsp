<%@ page import="jetbrains.buildServer.serverSide.BuildTypeOptions" %>
<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>
<jsp:useBean id="parametersBean" type="jetbrains.buildServer.controllers.admin.projects.EditableOutputParamsBean" scope="request"/>

<c:url value="/admin/editBuildParams.html?id=${buildForm.settingsId}" var="inputParamsUrl"/>
<c:url value="/admin/editOutputParams.html?id=${buildForm.settingsId}" var="outputParamsUrl"/>
<admin:editBuildTypePage selectedStep="buildParams">
  <jsp:attribute name="head_include">
    <bs:linkCSS>
      /css/settingsTable.css
      /css/admin/editUserParams.css
    </bs:linkCSS>
    <style type="text/css">
      .outputParamsOptions {
        border-left: 3px solid var(--ring-content-background-color, #fff);
        margin-top: 16px;
        margin-bottom: 4px;
        padding-left: 0.5em;
      }

      .outputParamsOptions .smallNote {
        margin-left: 1.5em;
        text-wrap: nowrap;
      }

      .customParam {
        display: none;
      }

      .existingParamChooser {
        display: none;
        text-wrap: nowrap;
        width: 25em;
      }

      .saveButtonsBlock.saveOption {
        border-top: none;
        margin-top: 0;
      }
    </style>
    <script>
      function toggleDependenciesWarning(exposeAllParamsCheckbox) {
        if (!exposeAllParamsCheckbox.checked) {
          BS.Util.show($j('div.exposeAllParamsWarn')[0]);
        } else {
          BS.Util.hide($j('div.exposeAllParamsWarn')[0]);
        }
      }

      function showHideNameAndValue(show) {
        if (show) {
          BS.Util.show($j('.customParam'));
        } else {
          BS.Util.hide($j('.customParam'));
        }
      }

      function onExistingParamSelection(existingParamSelect) {
        $j('#parameterMode1')[0].checked = true;
        showHideNameAndValue(false);

        if (existingParamSelect.selectedIndex == 0) {
          $j('#parameterName')[0].value = '';
          $j('#parameterValue')[0].value = '';
        } else {
          var opt = existingParamSelect.options[existingParamSelect.selectedIndex];
          $j('#parameterName')[0].value = opt.value;
          $j('#parameterValue')[0].value = '%' + opt.value + '%';
        }
      }

      $j(document).ready(function() {
        BS.EditBuildTypeForm.setupEventHandlers();
        BS.EditBuildTypeForm.setModified(${buildForm.stateModified});
        BS.VisibilityHandlers.attachTo($j('#parameterName')[0], {
          updateVisibility: function() {
            if ($j('#parameterName')[0].value != '' ||
                $j('#error_parameterName')[0].innerText != '' ||
                $j('.existingParamChooser').length == 0) {
              BS.Util.show($j('.customParam'));
            } else {
              BS.Util.hide($j('.customParam'));
            }

            if ($j('.existingParamChooser').length == 0) {
              BS.Util.hide($j('.existingParamChooser'));
            } else {
              BS.Util.show($j('.existingParamChooser'));
            }
          }
        });

        <c:if test="${buildForm.readOnly}">
        BS.EditBuildTypeForm.setReadOnly();
        </c:if>
      });
    </script>
  </jsp:attribute>
  <jsp:attribute name="before_body_include">
    <div class="buildTypeSubTabs">
      <ring:buttonGroup className="ring-button-group-buttonGroup">
        <a class="ring-button-button ring-button-block  ring-button-heightM" href="${inputParamsUrl}">Input Parameters</a>
        <a class="ring-button-button ring-button-block  ring-button-heightM ring-button-active" href="${outputParamsUrl}">Output Parameters</a>
      </ring:buttonGroup>
    </div>
  </jsp:attribute>
  <jsp:attribute name="body_include">

  <div class="section noCaption">
    <bs:smallNote>
      Output parameters are available to downstream build configurations via the <tt>dep.</tt> syntax.<bs:help file="Use+Parameters+in+Build+Chains" preservePlus="true"/>
    </bs:smallNote>


    <bs:refreshable containerId="outputParams" pageUrl="${pageUrl}">
    <form action="<c:url value='/admin/editBuild.html?id=${buildForm.settingsId}'/>" method="post"
          onsubmit="return BS.EditBuildTypeForm.submitBuildType()" id="editBuildTypeForm" class="section noMargin">
      <div class="outputParamsOptions">
        <admin:booleanOption buildTypeForm="${buildForm}" optionName="<%=BuildTypeOptions.BT_EXPOSE_ALL_PARAMETERS_AS_OUTPUT.getKey()%>" fieldName="exposeAllParametersAsOutput" onclick="toggleDependenciesWarning(this)">
          <jsp:attribute name="labelText">All parameters are available to other build configurations</jsp:attribute>
        </admin:booleanOption>
        <div class="smallNote">
          Disable this setting for clarity and easier maintenance.
          Instead of sharing all parameters with other build configurations, create output parameters that reference only the required ones.
          <c:if test="${not buildForm.template}">
          <c:url value="/admin/editProject.html?tab=usagesReport&projectId=${buildForm.project.externalId}&buildTypeId=${buildForm.settingsBuildType.externalId}" var="usagesReportUrl"/>
          <br/>Check the <a href="${usagesReportUrl}" target="_blank">list of incoming dependencies</a> to see the usages of the build configuration parameters.
        </c:if>
        </div>
      </div>
      <c:if test="${buildForm.hasIncomingDependencies()}">
        <c:url value="/admin/editProject.html?tab=usagesReport&projectId=${buildForm.project.externalId}&buildTypeId=${buildForm.settingsBuildType.externalId}" var="usagesReportUrl"/>
        <div class="attentionComment exposeAllParamsWarn" style="display: none">
          Note: disabling of this option can affect <a href="${usagesReportUrl}" target="_blank">dependent build configurations</a>
          if they are using <tt>%dep.${buildForm.originalBuildType.externalId}.&lt;name>%</tt> parameter references in their settings.
        </div>
      </c:if>

      <admin:highlightChangedFields containerId="editBuildTypeForm" closestParentSelector="div.outputParamsOptions"/>

      <c:if test="${!buildForm.readOnly}">
        <div class="saveButtonsBlock saveOption">
          <forms:submit label="Save"/>
          <input type="hidden" value="${buildForm.numberOfSettingsChangesEvents}" name="numberOfSettingsChangesEvents"/>
          <input type="hidden" id="submitBuildType" name="submitBuildType" value="1"/>
          <input type="hidden" name="showDSL" id="buildTypeShowDSL" value=""/>
          <input type="hidden" name="showDSLVersion" id="buildTypeShowDSLVersion" value=""/>
          <input type="hidden" name="showDSLPortable" id="buildTypeShowDSLPortable" value=""/>
        </div>
      </c:if>
    </form>

    <div>&nbsp;</div>

    <c:if test="${not buildForm.readOnly}">
      <div>
        <forms:addButton showdiscardchangesmessage="false" onclick="BS.EditParameterDialog.showDialog('', '', 'output', false, false, false, '', ''); return false"><c:out value="Add new output parameter"/></forms:addButton>
      </div>
    </c:if>

    <admin:editableParametersList params="${parametersBean.parameters}" paramType="output" readOnly="${buildForm.readOnly}" showEmptyParamsMessage="false"/>
    </bs:refreshable>
  </div>

<bs:modalDialog formId="editParamForm"
                title="Parameters"
                action="${outputParamsUrl}"
                closeCommand="BS.EditParameterDialog.cancelDialog()"
                saveCommand="BS.EditParameterForm.saveParameter()">
  <table class="runnerFormTable userDefinedParametersTable">
    <c:set var="parametersToShare" value="${parametersBean.parametersToShare}"/>
    <c:if test="${not empty parametersToShare}">
    <tr class="existingParamChooser">
      <td>
        <forms:radioButton name="parameterMode" id="parameterMode1" checked="true" onclick="if (this.checked) showHideNameAndValue(false)"/> <label class="editParameterLabel" for="parameterMode1">Share existing parameter:</label>
      </td>
      <td class="existingParamChooser">
        <forms:select name="existingParameter" enableFilter="true" onchange="onExistingParamSelection(this)">
          <forms:option value="">-- Choose an existing parameter --</forms:option>
          <c:forEach items="${parametersToShare}" var="p">
            <forms:option value="${p.name}"><c:out value="${p.name}"/></forms:option>
          </c:forEach>
        </forms:select>
      </td>
    </tr>
    <tr class="existingParamChooser">
      <td colspan="2">
        <forms:radioButton name="parameterMode" id="parameterMode2" onclick="if (this.checked) showHideNameAndValue(true)"/> <label class="editParameterLabel" for="parameterMode2">Define new output parameter</label>
      </td>
    </tr>
    </c:if>
    <tr class="customParam">
      <th style="border-top: none">
        <label class="editParameterLabel" for="parameterName">Name:<l:star/></label>
      </th>
      <td style="border-top: none">
        <forms:textField name="parameterName" value="" style="width: 100%;" maxlength="512" noAutoComplete="true"/>
        <span class="error" id="error_parameterName"></span>
        <span class="smallNote" id="inheritedParamName" style="display: none; margin-left: 0;">Name of the inherited parameter cannot be changed</span>
      </td>
    </tr>
    <tr class="customParam">
      <th>
        <label class="editParameterLabel" for="parameterValue">Value:</label>
      </th>
      <td>
        <div class="completionIconWrapper parameterWrapper">
          <forms:textField expandable="true" name="parameterValue" style="width: 100%;" className="buildTypeParams"/>
        </div>
        <span class="error" id="error_parameterValue"></span>
        <span class="smallNote">Type '%' for reference completion</span>
      </td>
    </tr>
  </table>

  <c:if test="${not buildForm.readOnly}">
  <div class="popupSaveButtonsBlock">
    <forms:submit label="Save" id="dialogSaveButton"/>
    <forms:cancel showdiscardchangesmessage="false" onclick="BS.EditParameterDialog.cancelDialog()"/>
    <forms:saving id='userParamsSaving'/>
  </div>
  </c:if>

  <input type="hidden" id="currentNameWithPrefix" name="currentNameWithPrefix" value=""/>
  <input type="hidden" id="currentName" name="currentName" value=""/>
  <input type="hidden" id="parameterSpec" name="parameterSpec" value=""/>
  <input type="hidden" id="submitAction" name="submitAction" value=""/>
  <input type="hidden" id="submitBuildType1" name="submitBuildType" value="1"/>
  <input type="hidden" id="editableObjectId" name="editableObjectId" value="settingsId=${buildForm.settingsId}"/>
</bs:modalDialog>

    <forms:modified/>
  </jsp:attribute>
</admin:editBuildTypePage>
