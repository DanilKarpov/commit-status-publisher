<jsp:useBean id="showMode" type="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" scope="request"/>
<%@ page import="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" %>
<%@ include file="/include-internal.jsp" %>
<c:set var="inplaceMode" value="<%=HealthStatusItemDisplayMode.IN_PLACE%>"/>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>

<div>
  Domain isolation protection for artifacts is disabled.<bs:help file="Artifacts+Domain+Isolation"/><br/>
  To secure the server, consider enabling the domain isolation protection and configuring the URL in <a href="<c:url value="/admin/admin.html?item=serverConfigGeneral"/>">Global Settings</a>.
</div>
