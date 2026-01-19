<%@ include file="include-internal.jsp"%>
<%@ taglib prefix="agent" tagdir="/WEB-INF/tags/agent"%>
<jsp:useBean id="currentUser" type="jetbrains.buildServer.users.User" scope="request"/>
<jsp:useBean id="agentsForm" scope="request" type="jetbrains.buildServer.controllers.agent.AgentListForm"/>
<%--@elvariable id="agentsForm" type="jetbrains.buildServer.controllers.agent.AgentListForm"--%>
<jsp:useBean id="agentGroups" scope="request" type="java.util.List<jetbrains.buildServer.controllers.agent.AgentGroup>"/>
<bs:agentsListContent agentsForm="${agentsForm}" agentGroups="${agentGroups}">
  <c:if test="${empty agentGroups}">
    <p class="note">There are no agents available.</p>
  </c:if>

  <c:if test="${not empty agentGroups}">
    <p class="note">There <bs:are_is val="${agentsCount}"/> <b>${agentsCount}</b> agent<bs:s val="${agentsCount}"/> available (<strong>${agentsForm.numberOfRunningBuilds}</strong> running).</p>

    <div class="clearfix">
      <agent:poolCollapseExpandAll grouped="${agentsForm.actuallyGroupByPools}"/>
      <agent:groupByPoolsCheckbox/>
    </div>

    <div id="agentsTable">
      <jsp:include page="agentsRunningBlock.jsp"/>
    </div>

  </c:if>

  <c:if test="${empty agentGroups && not intprop:getBooleanOrTrue('teamcity.internal.agent.distribution.jdk.bundle.enabled')}">
    <h3 class="title">Install Build Agents</h3>
    <%@ include file="installLinks.jspf" %>
  </c:if>
</bs:agentsListContent>



