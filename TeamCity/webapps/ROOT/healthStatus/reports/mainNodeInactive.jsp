<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>

<c:set var="mainNodeUrl" value="${healthStatusItem.additionalData['mainNodeUrl']}"/>
<c:set var="mainNodeInactiveTimeMins" value="${healthStatusItem.additionalData['mainNodeInactiveTimeMins']}"/>

<div>
  <c:choose>
    <c:when test="${not empty mainNodeInactiveTimeMins}">
      The main node (<a href="<c:url value="${mainNodeUrl}"/>">${mainNodeUrl}</a>) has been inactive for ${mainNodeInactiveTimeMins} <bs:plural txt="minute" val="${mainNodeInactiveTimeMins}"/>.
    </c:when>
    <c:otherwise>
      The main node (<a href="<c:url value="${mainNodeUrl}"/>">${mainNodeUrl}</a>) has been stopped.
    </c:otherwise>
  </c:choose>

  If this is a planned inactivity (a restart or upgrade), you can ignore this message - it will disappear once the main node is active again.

  Otherwise, please log in to the main node server and check the status of the TeamCity process.
  If there is no TeamCity process or the server is down and cannot be recovered shortly,
  you can assign the "Main node" responsibility to the current or some other node on the
  <a href="<c:url value="/admin/admin.html?item=nodesConfiguration"/>">nodes configuration</a> page.
</div>