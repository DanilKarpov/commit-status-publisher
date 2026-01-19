<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<jsp:useBean id="editCleanupRulesForm" type="jetbrains.buildServer.controllers.admin.cleanup.EditCleanupRulesForm" scope="request"/>

<div id="cleanup-policies-form"></div>
<script>
  ReactUI.renderProjectCleanup('cleanup-policies-form', {
    projectInternalId: '${editCleanupRulesForm.parentProject.projectId}',
    projectId: '${editCleanupRulesForm.projectId}'
  })
</script>

