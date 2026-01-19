<%@ include file="include-internal.jsp"%>
<%@ taglib prefix="agent" tagdir="/WEB-INF/tags/agent"%>
<jsp:useBean id="agentGroups" scope="request" type="java.util.List<jetbrains.buildServer.controllers.agent.AgentGroup>"/>
<jsp:useBean id="agentsForm" scope="request" type="jetbrains.buildServer.controllers.agent.AgentListForm"/>

<bs:agentsListContent agentsForm="${agentsForm}" agentGroups="${agentGroups}">
  <c:if test="${empty agentGroups}">
    <p class="note">There are no disconnected agents found.</p>
  </c:if>

  <c:if test="${not empty agentGroups}">
    <p class="note">There <bs:are_is val="${agentsCount}"/> <b>${agentsCount}</b> currently disconnected agent<bs:s val="${agentsCount}"/>.</p>

    <div class="clearfix">
      <agent:poolCollapseExpandAll grouped="${agentsForm.actuallyGroupByPools}"/>
      <agent:groupByPoolsCheckbox/>
    </div>

    <div id="agentsTable">
      <jsp:include page="unregisteredAgentsList.jsp"/>
    </div>
  </c:if>
</bs:agentsListContent>