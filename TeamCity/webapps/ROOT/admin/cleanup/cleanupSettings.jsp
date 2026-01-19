<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>

<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>
<admin:editBuildTypePage selectedStep="cleanupSettings">
  <jsp:attribute name="head_include"></jsp:attribute>
  <jsp:attribute name="body_include">
    <div id="cleanup-form"></div>
    <script>
      ReactUI.renderCleanup('cleanup-form', {
        buildTypeId: '${buildForm.externalId}',
        isTemplate: ${buildForm.isTemplate()}
      })
    </script>
  </jsp:attribute>
</admin:editBuildTypePage>
