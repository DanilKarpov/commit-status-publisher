<%@ page import="jetbrains.buildServer.controllers.admin.projects.BuildConfigurationSteps" %>
<%@ page import="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" %>
<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<c:set var="affectedProject" value="${healthStatusItem.additionalData['project']}"/>
<c:set var="defaultTemplateExtId" value="${healthStatusItem.additionalData['defaultTemplateExtId']}"/>
<jsp:useBean id="showMode" type="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" scope="request"/>
<jsp:useBean id="healthStatusReportUrl" type="java.lang.String" scope="request"/>

<c:set var="inplaceMode" value="<%=HealthStatusItemDisplayMode.IN_PLACE%>"/>
<c:set var="cameFromUrl" value="${showMode eq inplaceMode ? pageUrl : healthStatusReportUrl}"/>
<admin:editProjectLinkFull project="${affectedProject}" />
refers to the unreachable default template '<c:out value="${defaultTemplateExtId}"/>'

