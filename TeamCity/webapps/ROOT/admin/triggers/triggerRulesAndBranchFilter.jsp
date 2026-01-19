<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<jsp:useBean id="propertiesBean" type="jetbrains.buildServer.controllers.BasePropertiesBean" scope="request"/>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>
<l:settingsGroup title="VCS Trigger Rules" className="advancedSetting"/>
<tr class="advancedSetting">
  <th style="vertical-align: top;">
    <label for="triggerRules" class="rightLabel">Trigger rules:</label><bs:help file="Configuring+VCS+Triggers" anchor="buildTriggerRules"/>
  </th>
  <td style="vertical-align: top;">
    <admin:triggerRulesForm buildForm="${buildForm}"/>
  </td>
</tr>
<c:set var="branchFilter" value="${propertiesBean.properties['branchFilter']}"/>
<c:if test="${buildForm.template or buildForm.branchesConfigured or (not empty branchFilter and branchFilter != param['defaultBranchFilter'])}">
  <jsp:include page="branchFilter.jsp"/>
</c:if>
