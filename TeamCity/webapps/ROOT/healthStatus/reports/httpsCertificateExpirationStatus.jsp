<%@include file="/include-internal.jsp"%>

<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<c:set var="message" value="${healthStatusItem.additionalData['message']}"/>
<c:out value="${message}" escapeXml="false"/><br/>
Proceed to <a href="<c:url value="/admin/admin.html?item=https"/>">HTTPS settings page</a>.
