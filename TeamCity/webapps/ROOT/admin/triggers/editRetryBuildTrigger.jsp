<%@ include file="/include.jsp" %>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<jsp:useBean id="propertiesBean" type="jetbrains.buildServer.controllers.BasePropertiesBean" scope="request"/>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>

<tr>
  <td colspan="2"><em>Retry Build Trigger adds a new build to the queue if the previous build failed.</em></td>
</tr>
<tr>
  <td style="vertical-align: top;">
    <label for="enqueueTimeout">Seconds to wait:</label>
  </td>
  <td style="vertical-align: top;">
    <props:textProperty name="enqueueTimeout"/>
    <span class="error" id="error_enqueueTimeout"></span>
    <span class="smallNote">Seconds to wait before starting a new build.</span>
  </td>
</tr>
<tr>
  <td style="vertical-align: top;">
    <label for="retryAttempts">Number of attempts to retry the build:</label>
  </td>
  <td style="vertical-align: top;">
    <props:textProperty name="retryAttempts"/>
    <span class="error" id="error_retryAttempts"></span>
    <span class="smallNote">Leave blank for unlimited number of retry attempts.</span>
  </td>
</tr>
<l:settingsGroup title="Triggering settings"/>
<tr>
  <td style="vertical-align: top;" colspan="2">
    <props:checkboxProperty name="reRunBuildWithTheSameRevisions"/>
    <label for="reRunBuildWithTheSameRevisions">Trigger a new build with the same revisions</label>
  </td>
</tr>
<tr>
  <td style="vertical-align: top;" colspan="2">
    <props:checkboxProperty name="moveToTheQueueTop"/>
    <label for="moveToTheQueueTop">Put the newly triggered builds to the queue top</label>
  </td>
</tr>
<c:set var="branchFilter" value="${propertiesBean.properties['branchFilter']}"/>
<c:set var="defaultBranchFilter" value='+:*'/>
<c:if test="${buildForm.template or buildForm.branchesConfigured or (not empty branchFilter and branchFilter != defaultBranchFilter)}">
  <jsp:include page="/admin/triggers/branchFilter.jsp"/>
</c:if>
