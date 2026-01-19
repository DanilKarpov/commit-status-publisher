<%@ page import="jetbrains.buildServer.serverSide.BuildTypeOptions" %>
<%@include file="/include-internal.jsp"%>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="availableParents" type="java.util.List" scope="request"/>
<jsp:useBean id="cameFromSupport" type="jetbrains.buildServer.web.util.CameFromSupport" scope="request"/>
<style type="text/css">
  #createFromTemplateParams table.runnerFormTable td {
    border-right: 0;
    vertical-align: top;
  }

  #createFromTemplateParams table.runnerFormTable td.name {
    width: 26%;
  }

  #createFromTemplateParams table.runnerFormTable td.value {
    width: 74%;
  }

  #createFromTemplateParams table.runnerFormTable td.value div.completionIconWrapper {
    display: flex;
  }

  td.compositeBuildTypeDeps {
    border-top: none;
    padding-left: 0;
  }
</style>

<div id="container" class="clearfix" style="width:70%;">
  <bs:unprocessedMessages/>

  <c:url value='/admin/createBuildType.html' var="actionUrl"/>
  <c:set var="templates" value="${project.availableTemplates}"/>
  <form id="createBuildTypeForm" action="${actionUrl}" onsubmit="return BS.CreateBuildTypeForm.submit()">
    <table class="runnerFormTable">
      <tr>
        <th>
          <label for="parentProjectId"><strong>Parent project:</strong></label>
        </th>
        <td>
          <bs:projectsFilter name="parentProjectId" id="parentProjectId"
                             projectBeans="${availableParents}"
                             selectedProjectExternalId="${project.externalId}"
                             disableRoot="true" onchange="BS.CreateBuildTypeForm.parentProjectChanged(this.options[this.selectedIndex].value)"/>
          <span class="error" id="error_parentProject"></span>
        </td>
      </tr>

      <tr>
        <th>
          <label for="buildTypeName"><strong>Name:<l:star/></strong></label>
        </th>
        <td>
          <forms:textField name="buildTypeName" maxlength="80" className="longField"/>
          <span class="error" id="error_buildTypeName"></span>
          <span class="error" id="error_createBuildTypeFailed"></span>
        </td>
      </tr>
      <tr>
        <th>
          <label for="buildTypeExternalId"><strong>Build configuration ID:<l:star/></strong><bs:help file="Entity+IDs"/></label>
        </th>
        <td>
          <forms:textField name="buildTypeExternalId" maxlength="256" className="longField"/>
          <span class="smallNote">This ID is used in URLs, REST API, HTTP requests to the server, and configuration settings in the TeamCity Data Directory.</span>
          <span class="error" id="error_buildTypeExternalId"></span>
        </td>
      </tr>
      <tr>
        <th><label for="description">Description:</label></th>
        <td><forms:textField name="description" className="longField" maxlength="256" value=""/></td>
      </tr>
      <tr class="advancedSetting">
        <th><label for="buildConfigurationType">Build configuration type:</label></th>
        <td>
          <c:set var="buildConfTypeOptionName" value="<%=BuildTypeOptions.BT_BUILD_CONFIGURATION_TYPE.getKey()%>"/>
          <c:set var="regular" value="<%=BuildTypeOptions.BuildConfigurationType.REGULAR.name()%>"/>
          <c:set var="composite" value="<%=BuildTypeOptions.BuildConfigurationType.COMPOSITE.name()%>"/>
          <c:set var="deployment" value="<%=BuildTypeOptions.BuildConfigurationType.DEPLOYMENT.name()%>"/>

          <forms:select name="buildConfigurationType" style="width: 18em" enableFilter="true" onchange="{
          var value = this.options[this.selectedIndex].value;
          $j('.smallNote.buildConfigurationTypeNote').hide();
          $j('.smallNote.buildConfigurationTypeNote.' + value).show();
          }">
            <forms:option value="${regular}" selected="true">Regular</forms:option>
            <forms:option value="${composite}" selected="${composite}">Composite (aggregating results)</forms:option>
            <forms:option value="${deployment}" selected="${deployment}">Deployment</forms:option>
          </forms:select>
          <span class="smallNote buildConfigurationTypeNote ${regular}" style="display: none;">Builds of a regular build configuration can have build steps and are executed on agents.</span>
          <span class="smallNote buildConfigurationTypeNote ${composite}" style="display: none;">Builds of a composite build configuration do not run on an agent. The main purpose of composite build is to aggregate results from snapshot dependencies in a single place.<bs:help file="Composite+Build+Configuration"/></span>
          <span class="smallNote buildConfigurationTypeNote ${deployment}" style="display: none;">Deployment build configuration publishes / deploys artifacts of other builds to some environment.<bs:help file="Deployment+Build+Configuration"/></span>
          <script type="text/javascript">
            $j('#buildConfigurationType').trigger("change");
          </script>
        </td>
      </tr>
      <c:if test="${not empty templates}">
        <tr id="templateChooserContainer" class="advancedSetting">
          <th>
            <label for="templateId"><strong>Based on template:</strong></label>
          </th>
          <td>
            <forms:select name="templateId" style="width: 30em;" enableFilter="true" onchange="BS.CreateBuildTypeForm.onTemplateChange()">
              <option value="">&lt;Do not attach to a template&gt;</option>
              <c:set var="curPrj" value=""/>
              <c:forEach items="${templates}" var="template">
                <c:if test="${template.projectId != curPrj}">
                  <forms:option value="">-- <c:out value="${template.project.fullName}"/> project templates --</forms:option>
                  <c:set var="curPrj" value="${template.projectId}"/>
                </c:if>
                <forms:option value="${template.externalId}" selected="${templateId == template.externalId}"><c:out value="${template.name}"/><c:if test="${not empty template.description}"> (<c:out value="${template.description}"/>)</c:if></forms:option>
              </c:forEach>
            </forms:select> <forms:saving id="templateParamsUpdateProgress" style="float: none;"/>
            <span class="error" id="error_templateId"></span>
          </td>
        </tr>
        <tr class="advancedSetting">
          <td colspan="2" style="padding: 0; border-bottom: none;">
            <div id="createFromTemplateParams"></div>
          </td>
        </tr>
      </c:if>
    </table>

    <admin:showHideAdvancedOpts containerId="createBuildTypeForm" optsKey="buildTypeGeneralSettings"/>

    <div class="saveButtonsBlock">
      <forms:submit name="createBuildType" label="Create"/>
      <forms:saving id="createProgress"/>
    </div>

  </form>

  <script type="text/javascript">
    <%@include file="/js/bs/editBuildType.js"%>

    BS.AdminActions.prepareBuildTypeIdGenerator("buildTypeExternalId", "buildTypeName", $('parentProjectId'));

    BS.CreateBuildTypeForm = OO.extend(BS.AbstractWebForm, {
      parentProjectChanged: function (projectId) {
        if (!projectId) return;
        var href = document.location.href;
        document.location.href = href.replace("projectId=${project.externalId}", "projectId=" + projectId);
      },

      formElement: function () {
        return $('createBuildTypeForm');
      },

      savingIndicator: function () {
        return $('createProgress');
      },

      onTemplateChange: function() {
        var curProjectId = '${project.externalId}';
        this.clearErrors();
        var selectedTemplateId = $j('#templateId').find("option:selected").val();
        this._prepareForTemplateId(selectedTemplateId, curProjectId);

        if (selectedTemplateId) {
          var type = templateTypes[selectedTemplateId];
          if (type == '${regular}') {
            $('buildConfigurationType').setSelected(0);
          } else if (type == '${composite}') {
            $('buildConfigurationType').setSelected(1);
          } else if (type == '${deployment}') {
            $('buildConfigurationType').setSelected(2);
          }
        }
      },

      _prepareForTemplateId: function (templateId, curProjectId) {
        $j('#createFromTemplateParams').html('');
        var that = this;

        if (!templateId) {
          return;
        }

        this.disable();
        BS.TemplateParametersLoader.loadParameters(
            "templateId=" + templateId + "&projectId=" + curProjectId,
            "createFromTemplateParams",
            "templateParamsUpdateProgress",
            function () {
              that.enable();
              BS.VisibilityHandlers.updateVisibility(that.formElement());
            }
        );
      },

      submit: function () {
        var that = this;
        BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
          createFailed: function (elem) {
            $('error_createBuildTypeFailed').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
          },

          invalidName: function (elem) {
            this.emptyName(elem);
          },

          emptyName: function (elem) {
            $('error_buildTypeName').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
            that.highlightErrorField($("buildTypeName"));
          },

          onParentProjectNotFoundError: function (elem) {
            $('error_parentProject').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
          },

          invalidId: function (elem) {
            $('error_buildTypeExternalId').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
            that.highlightErrorField($("buildTypeExternalId"));
          },

          templateNotFound: function (elem) {
            $('error_templateId').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
            that.highlightErrorField($("templateId"));
          },

          emptyId: function (elem) {
            this.invalidId(elem);
          },

          duplicateId: function (elem) {
            this.invalidId(elem);
          },

          onConfigInRootError: function (elem) {
            $("error_parentProject").innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
            that.highlightErrorField($("parentProjectId"));
          },

          onCompleteSave: function (form, responseXML, err) {
            BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);

            if (!err) {
              BS.XMLResponse.processRedirect(responseXML);
            } else {
              form.enable();
            }
          }
        }));
        return false;
      }
    });

    <c:set var="buildConfTypeOption" value="<%=BuildTypeOptions.BT_BUILD_CONFIGURATION_TYPE%>"/>
    var templateTypes = {};
    <c:forEach var="t" items="${templates}">
    templateTypes['${t.externalId}'] = '${t.getOption(buildConfTypeOption)}';
    </c:forEach>

    $j(document).ready(function() {
      BS.CreateBuildTypeForm.onTemplateChange();
      $j('#buildTypeName').focus();
    });
  </script>
</div>
