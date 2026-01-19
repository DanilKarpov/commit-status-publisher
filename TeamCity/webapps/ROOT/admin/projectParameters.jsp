<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<jsp:useBean id="currentProject" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="projectParametersBean" type="jetbrains.buildServer.controllers.admin.projects.EditableUserDefinedParametersBean" scope="request"/>

<div class="buildTypeSubTabs">
  <ring:buttonGroup className="ring-button-group-buttonGroup">
    <a class="ring-button-button ring-button-block  ring-button-heightM ring-button-active" href="${pageUrl}">Input Parameters</a>
    <a class="ring-button-button ring-button-block  ring-button-heightM ring-button-disabled" href="#" onclick="return false;" title="Output parameters can only be defined for a build configuration or a template">Output Parameters</a>
  </ring:buttonGroup>
</div>

<div class="section noCaption">
  <bs:smallNote>
    Input parameters are used to customize behavior of the build steps or to parametrize builds to allow running them with different values of the same parameter.
  </bs:smallNote>

  <c:url var="actionUrl" value="/admin/editProjectParams.html?projectId=${currentProject.externalId}"/>
  <bs:unprocessedMessages/>
  <admin:userDefinedParameters userParametersBean="${projectParametersBean}" parametersActionUrl="${actionUrl}"
                               readOnly="${currentProject.readOnly or not afn:permissionGrantedForProject(currentProject, 'EDIT_PROJECT')}"
                               editableObjectId="projectId=${currentProject.externalId}" alwaysShowBuildParameters="true"
                               projectId="${currentProject.externalId}"/>
</div>