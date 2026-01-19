<%@ page import="jetbrains.buildServer.serverSide.CurrentNodeInfo" %>
<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<div>
  The following authorized agents compatible with the project <bs:projectLink project="${healthStatusItem.getAdditionalData().get('project')}"/> are no longer available:
  <c:set var="disconnectedAgents" value="${healthStatusItem.getAdditionalData().get('agents')}"/>
  <c:forEach var="agent" items="${disconnectedAgents}">
    <div><bs:agentDetailsFullLink agent="${agent}" doNotShowUnavailableStatus="true" showRunningStatus="false"/> disconnected since:
      <bs:date value="${agent.getLastCommunicationTimestamp()}" pattern="dd'&nbsp;'MMM'&nbsp;'yy'&nbsp;'HH:mm:ss"/>
    </div>
  </c:forEach>
  <br>
  If you no longer intend to use these agents, remove them from the "Agents" administration page.
</div>