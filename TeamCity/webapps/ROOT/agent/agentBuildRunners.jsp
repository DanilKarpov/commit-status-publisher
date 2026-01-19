<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="agentDetails" scope="request" type="jetbrains.buildServer.controllers.agent.AgentDetailsFormBase"/>
<c:set var="agent" value="${agentDetails.agent}"/>
<et:_subscribeAgentTab>
  AGENT_REGISTERED
  AGENT_PARAMETERS_UPDATED
</et:_subscribeAgentTab>
<p>This agent supports the following build runners:</p>
<ul class="agentSummary">
  <c:forEach var="runType" items="${availableRunTypes}">
    <li><strong><c:out value="${runType.displayName}"/></strong><c:if test="${not empty runType.description}">: <c:out value="${runType.description}"/></c:if></li>
  </c:forEach>
</ul>
