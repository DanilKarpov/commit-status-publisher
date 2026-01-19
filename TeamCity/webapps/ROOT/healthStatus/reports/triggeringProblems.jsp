<%@include file="/include-internal.jsp"%>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<c:set var="reason" value="${healthStatusItem.additionalData['reason']}"/>
Automatic build triggering paused for the whole server because of the following reason: <c:out value="${fn:toLowerCase(reason.reasonText)}"/>.
<c:choose>
  <c:when test="${reason.resolveMessage != null}">
    <c:out value="${reason.resolveMessage}"/>
  </c:when>
</c:choose>
