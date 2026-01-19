<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>

<div>
  Some users cannot use optimized web UI updates via WebSocket protocol.<br/>
  The following addresses were used by the affected sessions:
  <ul>
    <c:forEach items="${healthStatusItem.additionalData['problematicHosts']}" var="host">
      <li><a href="<c:url value="${host}"/>"><c:out value="${host}"/></a></li>
    </c:forEach>
  </ul>
  Most probably there is not appropriately configured proxy server between the client browsers and the TeamCity server.<bs:help file="Server+Health" anchor="ProxyServerConfiguration"/>
</div>
