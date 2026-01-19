<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>
<c:set var="isReadOnlyForm" value="${buildForm.readOnly or buildForm.buildRunnerBean.enforced or buildForm.buildRunnerBean.inherited and not buildForm.buildStepsOverridingSupported}" />
<admin:editBuildTypePage selectedStep="runType">
  <jsp:attribute name="head_include">
    <bs:linkCSS>
      /css/admin/iprSettings.css
      /css/admin/runParams.css
      /css/admin/requirements.css
    </bs:linkCSS>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <div class="dslContainer">
      <div id="dslMode"></div>
    </div>
    <div id="uiMode">
    <form id="editBuildTypeForm" action="<c:url value='/admin/editRunType.html?id=${buildForm.settingsId}&runnerId=${buildForm.buildRunnerBean.id}'/>"
          method="post" onsubmit="return BS.EditBuildRunnerForm.submitBuildRunner('${buildForm.settingsId}')">

    <div id="runnerParams" class="clearfix">
      <jsp:include page="/admin/runnerParams.html">
        <jsp:param name="runTypeInfoKey" value="${empty param['runTypeInfoKey'] ? buildForm.multipleRunnersBean.currentBuildRunnerBean.runTypeInfoKey : param['runTypeInfoKey']}"/>
      </jsp:include>
    </div>

    <script type="text/javascript">
      BS.updateDeprecated = function() {
        document.querySelectorAll("li.deprecated").forEach(function(deprecatedOption) {
          deprecatedOption.style.color = "gray";
        });
      };

      BS.openRunnerSelector = function(event) {
        event && event.preventDefault && event.preventDefault();
        const toHide = jQuery(".runners-advanced, .runnerFormTable");
        toHide.addClass("hidden");
        $('saveButtons').hide();
      };

      BS.selectRunnerInFlattenMode = function(runType, onComplete) {
        jQuery(".runners-list").addClass("hidden");
        BS.updateRunnerContainerAsync(runType, onComplete);
      };

      BS.updateRunnerContainer = function(runType = $('runTypeInfoKey').getValue()) {
        BS.updateRunnerContainerAsync(runType)
      };

      BS.updateRunnerContainerAsync = function(runType, onComplete = () => {}) {
        BS.Util.show('chooseRunnerProgress');
        BS.MultilineProperties.clearProperties();
        BS.EditBuildRunnerForm.removeUpdateStateHandlers();

        BS.ajaxUpdater($('runnerParams'), '<c:url value="/admin/runnerParams.html?id=${buildForm.settingsId}&runnerId=${buildForm.buildRunnerBean.id}&runTypeInfoKey="/>' + encodeURIComponent(runType), {
          evalScripts : true,
          onComplete: function() {
            if (runType == '') {
              $('saveButtons').hide();
            } else {
              $('saveButtons').show();
            }

            typeof onComplete === 'function' && onComplete()

            BS.EditBuildRunnerForm.setupEventHandlers('${buildForm.settingsId}');
            BS.Util.hide('chooseRunnerProgress');
            BS.EditBuildRunnerForm.saveInSession();
            BS.AvailableParams.attachPopups('settingsId=${buildForm.settingsId}', 'textProperty', 'multilineProperty');
            BS.EditBuildRunnerForm.setupCtrlEnterForTextareas('${buildForm.settingsId}');
            BS.updateDeprecated();
          }
        });
      }

      <c:if test="${empty buildForm.multipleRunnersBean.currentBuildRunnerBean.runTypeInfoKey}">
        $j(document).ready(function() {
          $j('#runTypeInfoKey').prevAll('input').focus();
        });
      </c:if>

      jQuery(document).ready(function() {
        BS.updateDeprecated();
      });
    </script>

    <authz:authorize projectId="${buildForm.project.projectId}" allPermissions="EDIT_PROJECT">
      <input type="hidden" name="showDSL" id="showDSL" value=""/>
      <input type="hidden" name="showDSLVersion" id="showDSLVersion" value=""/>
      <input type="hidden" name="showDSLPortable" id="showDSLPortable" value=""/>
    </authz:authorize>
    <c:if test="${not isReadOnlyForm}">
    <div class="saveButtonsBlock" id="saveButtons" style="${not buildForm.buildRunnerBean.runnerTypeSelected ? 'display:none' : 'display:block'}">
      <forms:submit name="submitButton" label="Save"/>
      <forms:cancel cameFromSupport="${buildForm.cameFromSupport}"/>
      <forms:saving/>

      <input type="hidden" value="${buildForm.numberOfSettingsChangesEvents}" name="numberOfSettingsChangesEvents"/>
    </div>
    </c:if>

    </form>
    <forms:modified/>
    </div>

    <c:url var="autocompletionUrl" value="/admin/parameterAutocompletion.html?settingsId=${buildForm.settingsId}"/>
    <admin:editRequirementDialog
        editRequirementAction="-"
        autocompletionUrl="${autocompletionUrl}"
        dialogJsObject="BS.EditBuildStepConditionDialog"
        saveCommand="BS.EditBuildStepConditionDialog.saveCondition(this)"
    />


    <script type="text/javascript">
    BS.MultilineProperties.updateVisible();
    BS.EditBuildRunnerForm.setupEventHandlers('${buildForm.settingsId}');
    BS.EditBuildRunnerForm.setModified(${buildForm.buildRunnerBean.stateModified});
    <c:if test="${isReadOnlyForm}">
    BS.EditBuildRunnerForm.setReadOnly([{name: 'wrapToggle'}]);
    </c:if>
    BS.AvailableParams.attachPopups('settingsId=${buildForm.settingsId}', 'textProperty', 'multilineProperty');
    BS.EditBuildRunnerForm.setupCtrlEnterForTextareas('${buildForm.settingsId}');
    </script>
  </jsp:attribute>
</admin:editBuildTypePage>
