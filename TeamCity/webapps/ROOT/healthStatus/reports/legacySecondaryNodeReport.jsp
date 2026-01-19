<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<jsp:useBean id="showMode" type="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" scope="request"/>
<jsp:useBean id="healthStatusReportUrl" type="java.lang.String" scope="request"/>

<%--@elvariable id="node" type="jetbrains.buildServer.serverSide.TeamCityNode"--%>
<c:set var="node" value="${healthStatusItem.additionalData['node']}"/>
<c:url var="actionUrl" value="/admin/admin.html?item=nodesConfiguration"/>

<a href="${actionUrl}">Running builds node</a> with id <code><c:out value="${node.id}"/></code> is no longer supported and must be replaced with a secondary node.<bs:help file="upgrade-notes" anchor="running-builds-node-discontinued"/>