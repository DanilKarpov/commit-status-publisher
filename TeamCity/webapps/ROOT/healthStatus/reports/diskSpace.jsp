<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<c:set var="message">
  <c:choose>
    <c:when test="${afn:permissionGrantedGlobally('VIEW_SERVER_SETTINGS')}">
      ${healthStatusItem.additionalData['message']}
    </c:when>
    <c:otherwise>
      ${healthStatusItem.additionalData['userMessage']}
    </c:otherwise>
  </c:choose>
</c:set>
<c:out value="${message}" escapeXml="false"/><bs:help file="TeamCity+Disk+Space+Watcher"/>

