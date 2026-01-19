<%@ include file="include-internal.jsp" %>
<jsp:useBean id="queuedBuild" type="jetbrains.buildServer.serverSide.SQueuedBuild" scope="request"/>
<jsp:useBean id="canRunAgents" type="java.util.List" scope="request"/>
<jsp:useBean id="virtualAgents" type="java.util.List" scope="request"/>
<c:set var="virtualAgentsCount" value="${fn:length(virtualAgents)}"/>
<c:set var="numCanRun" value="${fn:length(canRunAgents)}"/>
<c:set var="totalAgents" value="${numCanRun + virtualAgentsCount}"/>
<c:set var="estimate" value="${queuedBuild.buildEstimates}"/>
<c:set var="plannedAgent" value="${estimate.agent}"/>
<c:if test="${not empty estimate and not empty estimate.waitReason}">
  <div>Wait reason: <em><c:out value="${estimate.waitReason.description}"/></em></div>
</c:if>

<c:if test="${totalAgents gt 0}">
  <c:if test="${numCanRun gt 0}">
  <p class="compatible">This build can run on:</p>
  <ul class="compatibleList">
    <c:if test="${plannedAgent != null}">
      <li><b>Planned agent:</b><bs:agent agent="${plannedAgent}" showRunningStatus="true" showCommentsAsIcon="true"/></li>
    </c:if>
    <c:forEach var="agent" items="${canRunAgents}">
      <li><bs:agent agent="${agent}" showRunningStatus="true" showCommentsAsIcon="true"/></li>
    </c:forEach>
  </ul>
  </c:if>
  <c:if test="${virtualAgentsCount gt 0}">
    <p class="compatible">Compatible cloud agents:</p>
    <ul class="compatibleList">
    <c:forEach var="va" items="${virtualAgents}">
      <li><em><bs:agentDetailsFullLink agentType="${va.agentType}" showCloudIcon="${true}" cloudStartingInstances="${va.startingInstancesCount}" canStartNewInstance="${va.canStartNewInstance}"/></em></li>
    </c:forEach>
    </ul>
  </c:if>

  <bs:compatibleAgentsLink queuedBuild="${queuedBuild}">More details &raquo;</bs:compatibleAgentsLink>
</c:if>

<c:if test="${totalAgents eq 0 and (empty estimate or empty estimate.waitReason)}">
<p class="compatible">No agents</p>
<bs:compatibleAgentsLink queuedBuild="${queuedBuild}">More details &raquo;</bs:compatibleAgentsLink>
</c:if>