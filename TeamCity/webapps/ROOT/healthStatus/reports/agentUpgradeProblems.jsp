<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<jsp:useBean id="problematicAgents" type="java.util.Map" scope="request"/>
${fn:length(problematicAgents)} agent<bs:s val="${fn:length(problematicAgents)}"/> tried to upgrade several times but failed
<ul>
  <c:forEach items="${problematicAgents}" var="agentInfo">
    <li><bs:agent agent="${agentInfo.key}" doNotShowOutdated="true"/></li>
  </c:forEach>
</ul>