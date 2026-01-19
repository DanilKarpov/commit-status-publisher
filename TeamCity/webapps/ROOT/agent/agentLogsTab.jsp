<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="agentDetails" scope="request" type="jetbrains.buildServer.controllers.agent.AgentDetailsForm" />
<jsp:include page="/agent/viewLogs.html?id=${agentDetails.agent.id}"/>