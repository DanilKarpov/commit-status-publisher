<%@include file="/include-internal.jsp" %>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="dslContextParameters" type="java.util.List" scope="request"/>

<style type="text/css">
  .dslParametersTable {
    table-layout: fixed;
    margin-top: 1em;
  }

  .newParamInput {
    width: 100%;
    height: 2em;
  }

</style>

<c:set var="readOnly" value="${not afn:permissionGrantedForProject(project, 'EDIT_PROJECT')}"/>

<script type="application/javascript">
  BS.EditContextParameters = OO.extend(BS.AbstractWebForm, {
    usedParameterNames: [],

    parametersCount: 0,

    initNewParamInputs: function() {
      $j('#dslContextParam_new_name').val("").placeholder({text: '&lt;Name>'});
      $j('#dslContextParam_new_value').val("").placeholder({text: '&lt;Value>'});
      $j('#dslContextParam_new_name_error').html("");
      $j('#dslContextParam_new_value_error').html("");
    },

    formElement: function () {
      return $('editContextParameters');
    },

    deleteParameter: function (paramTr) {
      var tbody = paramTr.parentNode;
      tbody.removeChild(paramTr);
      this.parametersCount--;
      this.setModified(true);
      $j('#saveButton').removeAttr("disabled");
      if (this.parametersCount === 0) {
        $j('#tableParamsHeader').hide();
      }
      var name = $j(paramTr).find("span.paramName").text().trim();
      var index = this.usedParameterNames.indexOf(name);
      if (index != -1) this.usedParameterNames.splice(index, 1);
    },

    addParameter: function (calledBeforeSubmit) {
      var newName = $j('#dslContextParam_new_name').val().trim();
      var newValue = $j('#dslContextParam_new_value').val();
      if (calledBeforeSubmit && !newName && !newValue) {
        return true;
      }
      if (!newName) {
        $j("#dslContextParam_new_error").text("Parameter name should not be empty");
        return false;
      }
      if (!/^[a-z][0-9a-z._\*\-]*$/i.test(newName)) {
        $j("#dslContextParam_new_error").text("Parameter name should start with a letter and only contain the following characters: [a-Z, 0-9, ._-*]");
        return false;
      }
      if (this.usedParameterNames.indexOf(newName) != -1) {
        $j("#dslContextParam_new_error").text("Parameter with the specified name already exists");
        return false;
      }
      if (!newValue) {
        $j("#dslContextParam_new_error").text("Parameter value should not be empty");
        return false;
      }
      var newRow = $j('#newParamTemplate').clone();
      newRow.attr("id","");

      newRow.attr("style", "");
      var parameterId = this.parametersCount++;
      newRow.find('td label span').attr("id", "paramName_" + parameterId).text(newName);
      newRow.find('#dslContextParam_name_').attr("name", "dslContextParam_name_" + parameterId).attr("id", "dslContextParam_name_" + parameterId).val(newName);
      newRow.find('#dslContextParam_error_').attr("id", "dslContextParam_name_" + parameterId + "_error");
      newRow.find('#dslContextParam_value_').attr("name", "dslContextParam_value_" + parameterId).attr("id", "dslContextParam_value_" + parameterId).val(newValue);
      newRow.find('#dslContextParam_clipboard_').attr("data-clipboard-target", "#paramName_" + parameterId);
      $j('#tableParamsHeader').show();
      $j('#tableParams').append(newRow);
      this.initNewParamInputs();
      if (!calledBeforeSubmit) {
        this.setModified(true);
        $j('#saveButton').removeAttr("disabled");
      }
      $j("#dslContextParam_new_error").text("");
      this.usedParameterNames.push(newName);
      return true;
    },

    setupEventHandlers: function () {
      var that = this;
      this._currentParameters = this.serializeParameters();

      this.setUpdateStateHandlers({
        updateState: function () {
          $j('#saveButton').removeAttr("disabled");
          that.setModified(that.serializeParameters() !== that._currentParameters);
        },

        saveState: function () {
          that.submit();
        }
      });
    },

    submit: function () {
      if (!this.addParameter(true)){
        return false;
      }

      BS.Util.show('dslParametersProgress');

      BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.SimpleListener, {
        onBeginSave: function(form) {
          form.disable();
        },

        onCompleteSave: function (form, responseXML) {
          BS.Util.hide('dslParametersProgress');
          BS.XMLResponse.processErrors(responseXML, {}, function (id, elem) {
            alert(elem.firstChild.nodeValue);
          });
          BS.reload(true);
        }
      }));
      return false;
    }
  });

  $j(document).ready(function() {
    BS.EditContextParameters.initNewParamInputs();
    BS.EditContextParameters.setupEventHandlers();
    BS.Clipboard('#editContextParameters span.clipboard-btn');
  });
</script>
<div class="grayNote" style="margin-top: 1em;">
  Context parameters allow customizing the behavior of project settings generation from Kotlin DSL. <br/>
  The parameters, set on this page, will be passed to the DSL code at runtime. You can get their values in the code using the 'DslContext.getParameter(name, defaultValue)' method. <bs:help file="Kotlin+DSL" anchor="contextParameters"/>
</div>

<div>
  <bs:messages key="dslParameters"/>
</div>

<c:url value="/admin/versionedSettingsDslContext.html" var="actionUrl"/>
<form id="editContextParameters" action="${actionUrl}" method="post" onsubmit="return BS.EditContextParameters.submit();" autocomplete="off">

  <table class="runnerFormTable dslParametersTable">

    <c:if test="${!readOnly}">
      <tbody>
      <tr>
        <td>
          <input type="text" id="dslContextParam_new_name" value="" class="newParamInput" autocomplete="off" maxlength="40">
        </td>
        <td>
          <input type="text" id="dslContextParam_new_value" value="" class="newParamInput" autocomplete="off">
        </td>
        <td>
          <forms:addButton onclick="BS.EditContextParameters.addParameter(false); return false;">Add</forms:addButton>
        </td>
      </tr>
      <tr>
        <td colspan="3" style="border-top: none; padding-top: 0.1px;">
          <span class="error" id="dslContextParam_new_error"/>
        </td>
      </tr>
      </tbody>
    </c:if>

    <tbody id="tableParams">
      <c:if test="${fn:length(dslContextParameters) == 0}">
        <c:set var="headerStyle" value="display: none"/>
      </c:if>
      <tr id="tableParamsHeader" style="${headerStyle}">
        <th>Name:</th>
        <th>Value:</th>
      </tr>

      <tr id="newParamTemplate" style="display: none">
        <td>
          <span id="dslContextParam_clipboard_" class="clipboard-btn tc-icon icon16 tc-icon_copy" style="float: left" data-clipboard-action="copy" data-clipboard-target=""></span>
          <label><span class="paramName"></span></label>
          <input type="hidden" id="dslContextParam_name_" name="dslContextParam_name_" value=""/>
          <span class="error" id="dslContextParam_error_"></span>
        </td>
        <td>
          <forms:textField name="dslContextParam_value_"  value="" style="width: 100%"/>
        </td>
        <td>
          <a href="#" onclick="BS.EditContextParameters.deleteParameter(this.parentNode.parentNode); return false;">Delete</a>
        </td>
      </tr>

      <c:forEach items="${dslContextParameters}" var="dslParam" varStatus="status">
        <%--@elvariable id="dslParam" type="jetbrains.buildServer.controllers.project.VersionedSettingsDslContextParametersTab.DslContextParameter"--%>
        <tr>
          <td>
            <span class="clipboard-btn tc-icon icon16 tc-icon_copy" style="float: left" data-clipboard-action="copy" data-clipboard-target="#paramName_${status.index}"></span>
            <label><span class="paramName" id="paramName_${status.index}"><c:out value="${dslParam.name}"/></span><c:if test="${dslParam.required}"><l:star/></c:if></label>
            <input type="hidden" name="dslContextParam_name_${status.index}" value='<c:out value="${dslParam.name}"/>'/>
          </td>
          <td>
            <c:choose>
              <c:when test="${!readOnly}">
                <forms:textField name="dslContextParam_value_${status.index}" value="${dslParam.value}" style="width: 100%"/>
              </c:when>
              <c:otherwise>
                <label><span style="width: 100%;"><c:out value="${dslParam.value}"/></span></label>
              </c:otherwise>
            </c:choose>
          </td>
            <td class="delete">
              <c:if test="${!readOnly}">
                <a href="#" onclick="BS.EditContextParameters.deleteParameter(this.parentNode.parentNode); return false;">Delete</a>
              </c:if>
            </td>
        </tr>
        <script type="application/javascript">
          BS.EditContextParameters.parametersCount++;
          BS.EditContextParameters.usedParameterNames.push("${util:forJS(dslParam.name, false, false)}");
        </script>
      </c:forEach>
    </tbody>

  </table>

  <c:if test="${!readOnly}">
    <div class="saveButtonsBlock">
      <input type="hidden" id="projectId" name="projectId" value="${project.externalId}"/>
      <forms:submit id="saveButton" label="Save" disabled="true"/>
      <forms:saving id="dslParametersProgress"/>
    </div>
  </c:if>

  <forms:modified onSave="return BS.EditContextParameters.submit();"/>

</form>

