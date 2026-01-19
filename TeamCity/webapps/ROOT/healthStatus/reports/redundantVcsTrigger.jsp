<%@ page import="jetbrains.buildServer.controllers.admin.projects.BuildConfigurationSteps" %>
<%@ page import="jetbrains.buildServer.serverSide.auth.Permission" %>
<%@ page import="jetbrains.buildServer.serverSide.healthStatus.reports.RedundantVcsTriggerReport" %>
<%@ page import="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" %>
<%@ taglib prefix="C" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>

<jsp:useBean id="showMode" type="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" scope="request"/>
<jsp:useBean id="healthStatusReportUrl" type="java.lang.String" scope="request"/>
<jsp:useBean id="editableRedundantDueTo" type="java.util.Collection" scope="request"/>
<jsp:useBean id="uneditableRedundantDueTo" type="java.util.Collection" scope="request"/>
<jsp:useBean id="invisibleRedundantDueToCount" type="java.lang.Integer" scope="request"/>
<jsp:useBean id="isTriggerInherited" type="java.lang.Boolean" scope="request"/>

<c:set var="buildTypeKey" value="<%=RedundantVcsTriggerReport.BUILD_TYPE_KEY%>"/>
<c:set var="triggerKey" value="<%=RedundantVcsTriggerReport.TRIGGER_KEY%>"/>
<c:set var="buildType" value="${healthStatusItem.additionalData[buildTypeKey]}"/>
<c:set var="redundantTrigger" value="${healthStatusItem.additionalData[triggerKey]}"/>

<c:set var="inplaceMode" value="<%=HealthStatusItemDisplayMode.IN_PLACE%>"/>
<c:set var="editProjectPermission" value="<%=Permission.EDIT_PROJECT%>"/>

<c:set var="editBuildTypeWithRedundantTriggerLink">
  <admin:editBuildTypeLinkFull buildType="${buildType}" step="<%=BuildConfigurationSteps.TRIGGERS_STEP_ID%>"/>
</c:set>

<c:set var="helpLink"><bs:help file="Server+Health" anchor="RedundantTrigger"/></c:set>

<c:set var="redundantDueToList">
  <c:choose>
    <c:when test="${fn:length(editableRedundantDueTo) > 0 || fn:length(uneditableRedundantDueTo) > 0}">
      The following dependent build configuration<bs:s val="${invisibleRedundantDueToCount}"/>
      <bs:have_has val="${invisibleRedundantDueToCount}"/> a VCS trigger with the same settings:
      <ul>
        <c:forEach items="${editableRedundantDueTo}" var="buildTypeFromChain">
          <li>
            <admin:editBuildTypeLinkFull buildType="${buildTypeFromChain}" step="<%=BuildConfigurationSteps.TRIGGERS_STEP_ID%>"/>
          </li>
        </c:forEach>
        <c:forEach items="${uneditableRedundantDueTo}" var="buildTypeFromChain">
          <li>
            <c:out value="${buildTypeFromChain.fullName}"/>
          </li>
        </c:forEach>
        <c:if test="${invisibleRedundantDueToCount > 0}">
          <li>
            and ${invisibleRedundantDueToCount} hidden build configuration<bs:s val="${invisibleRedundantDueToCount}"/>
          </li>
        </c:if>
      </ul>
    </c:when>
    <c:otherwise>
      ${invisibleRedundantDueToCount} hidden dependent build configuration<bs:s val="${invisibleRedundantDueToCount}"/>
      <bs:have_has val="${invisibleRedundantDueToCount}"/> a VCS trigger with the same settings.
    </c:otherwise>
  </c:choose>
</c:set>

<div>${editBuildTypeWithRedundantTriggerLink} has a redundant VCS trigger which can be deleted as triggering a build on VCS changes in dependencies
is already configured in dependent build configuration(s). The redundant trigger might cause extra builds in the queue.${helpLink}</div>
<div style="margin-top: .5em">
  ${redundantDueToList}
</div>

<c:set var="onUserActionCompleted" value="function() { if (BS.HealthStatusReport) { BS.HealthStatusReport.refreshContent(); } else { BS.reload(true); }}"/>

<c:if test="${not buildType.readOnly}">
<div style="margin-top: .5em">
  <c:choose>
    <c:when test="${isTriggerInherited}">
      <c:set var="buildTypeSettingsId"><admin:buildTypeOrTemplateEditId buildType="${buildType}"/></c:set>
      <a href="#" onclick="BS.AdminActions.setParametersDescriptorEnabled('${buildTypeSettingsId}', '${redundantTrigger.id}', false, 'Trigger', ${onUserActionCompleted}); return false;">Disable trigger</a>
    </c:when>
    <c:otherwise>
      <a href="#" onclick="BS.AdminActions.deleteBuildTrigger('${redundantTrigger.id}', '${buildType.externalId}', ${onUserActionCompleted}); return false;">Delete trigger</a>
    </c:otherwise>
  </c:choose>
</div>
</c:if>