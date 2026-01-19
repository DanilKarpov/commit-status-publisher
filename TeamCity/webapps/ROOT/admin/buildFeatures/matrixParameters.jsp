<%@ include file="/include-internal.jsp"%>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>

<div id="matrix-param-build-form"></div>
<script>
  ReactUI.renderMatrixParamBuild('matrix-param-build-form', {
    buildTypeId: '${buildForm.externalId}',
    projectId: '${buildForm.project.externalId}',
<c:if test="${buildForm.buildFeaturesBean.selectedDescriptor != null}">
    featureId: '${buildForm.buildFeaturesBean.selectedDescriptor.id}',
</c:if>
    featureType: '${buildForm.buildFeaturesBean.featureType}',
    readOnly: '${buildForm.readOnly}',
  })
</script>
