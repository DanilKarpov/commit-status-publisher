<%@ include file="include-internal.jsp"%>
<%@ taglib prefix="agent" tagdir="/WEB-INF/tags/agent"%>
<jsp:useBean id="agentGroups" scope="request" type="java.util.List<jetbrains.buildServer.controllers.agent.AgentGroup>"/>
<jsp:useBean id="agentsForm" scope="request" type="jetbrains.buildServer.controllers.agent.AgentListForm"/>

<bs:agentsListContent agentsForm="${agentsForm}" agentGroups="${agentGroups}">
  <c:if test="${agentsForm.licensesLeft == 0 and not empty agentGroups}">
    <div class="attentionComment" style="margin-top: .5em"><bs:buildStatusIcon type="red-sign" className="warningIcon"/>Additional agents cannot be authorized because there are no agent
      licenses left.
      <authz:authorize allPermissions="MANAGE_SERVER_LICENSES">
        View available licenses at <a href="<c:url value='/admin/admin.html?item=license'/>">Manage licenses</a> page.
      </authz:authorize>
    </div>
  </c:if>

  <p class="note">
    <c:if test="${not empty agentGroups}">
      There <bs:are_is val="${agentsCount}"/> <b>${agentsCount}</b> unauthorized agent<bs:s val="${agentsCount}"/>.
    </c:if>
    <c:if test="${empty agentGroups}">
      There are no unauthorized agents found.
    </c:if>
    <c:if test="${agentsForm.licensesLeft != 0}">
      Agent licenses left: <b><c:choose><c:when
      test="${agentsForm.licensesLeft == -1}">unlimited</c:when><c:otherwise>${agentsForm.licensesLeft}</c:otherwise></c:choose></b>.
    </c:if>
  </p>

  <c:if test="${not empty agentGroups}">
    <div class="clearfix">
      <agent:poolCollapseExpandAll grouped="${agentsForm.actuallyGroupByPools}"/>
      <agent:groupByPoolsCheckbox/>
    </div>
  </c:if>

  <c:if test="${not empty agentGroups}">
    <div id="agentsTable">
      <jsp:include page="unauthorizedAgentsList.jsp"/>
    </div>
  </c:if>
</bs:agentsListContent>