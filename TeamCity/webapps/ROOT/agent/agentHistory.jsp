<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags/tags" %>
<jsp:useBean id="agentDetailInfo" scope="request" type="jetbrains.buildServer.controllers.agent.AgentDetailInfo"/>

<bs:pinBuildDialog onBuildPage="${false}"/>
<div id="history"></div>
<script>
  (function () {
    <c:choose>
    <c:when test="${agentDetailInfo.agentType}">
    ReactUI.renderAgentHistory('history', {agent: {typeId: '${agentDetailInfo.id}'}});
    </c:when>
    <c:otherwise>
    ReactUI.renderAgentHistory('history', {agent: {id: '${agentDetailInfo.id}'}});
    </c:otherwise>
    </c:choose>
  })();
</script>
