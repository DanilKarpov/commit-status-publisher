<jsp:useBean id="showMode" type="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" scope="request"/>
<%@ page import="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" %>
<%@ include file="/include-internal.jsp" %>
<c:set var="inplaceMode" value="<%=HealthStatusItemDisplayMode.IN_PLACE%>"/>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>

<div>
  Web UI is working using legacy update mode and it is <bs:helpLink file="Server+Health" anchor="WebSocketconnectionissues">recommended</bs:helpLink> to update Tomcat setting. <br/>
  Details: WebSocket protocol cannot be used with Tomcat BIO connector.
</div>
