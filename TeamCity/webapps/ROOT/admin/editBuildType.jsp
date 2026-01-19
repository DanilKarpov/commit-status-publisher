<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>
<admin:editBuildTypePage selectedStep="general">
  <jsp:attribute name="head_include">

    <script type="text/javascript">
      $j(document).ready(function() {
        BS.EditBuildTypeForm.setupEventHandlers();
        BS.EditBuildTypeForm.setModified(${buildForm.stateModified});
      });
    </script>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <form action="<c:url value='/admin/editBuild.html?id=${buildForm.settingsId}'/>" method="post"
          onsubmit="return BS.EditBuildTypeForm.submitBuildType()" id="editBuildTypeForm">

    <admin:buildTypeForm buildForm="${buildForm}" title="${title}"/>

    <admin:showHideAdvancedOpts containerId="editBuildTypeForm" optsKey="buildTypeGeneralSettings"/>
    <admin:highlightChangedFields containerId="editBuildTypeForm"/>

    <c:if test="${!buildForm.readOnly}">
      <div class="saveButtonsBlock">
        <forms:submit name="submitButton" label="Save"/>
        <forms:cancel cameFromSupport="${buildForm.cameFromSupport}" />
        <forms:saving/>
      </div>
    </c:if>
    <input type="hidden" id="submitBuildType" name="submitBuildType" value="store"/>
    <input type="hidden" value="${buildForm.numberOfSettingsChangesEvents}" name="numberOfSettingsChangesEvents"/>
    </form>

    <forms:modified/>
  </jsp:attribute>
</admin:editBuildTypePage>
