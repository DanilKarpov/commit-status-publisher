<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="agentDetails" scope="request" type="jetbrains.buildServer.controllers.agent.AgentDetailsFormBase"/>
<jsp:useBean id="agentParametersModel" scope="request" type="jetbrains.buildServer.controllers.agent.AgentParametersTabModel"/>
<jsp:useBean id="agentDetailInfo" scope="request" type="jetbrains.buildServer.controllers.agent.AgentDetailInfo"/>
<et:_subscribeAgentTab>
  AGENT_PARAMETERS_UPDATED
</et:_subscribeAgentTab>
<div class="subTabs">
<c:forEach var="tab" items="${agentParametersModel.entries}" varStatus="st">
  <c:set var="isNotSelected" value="${agentParametersModel.selectedTabKey eq tab.key}"/>

  <c:choose>
    <c:when test="${not isNotSelected}">
      <a target="_self" href="<c:url value="/agentDetails.html?${agentDetailInfo.urlParameters}&tab=${agentParametersModel.tabName}&${agentParametersModel.propertiesKindKey}=${tab.key}"/>"
          ><c:out value="${tab.subTabCaption}"/></a>
    </c:when>
    <c:otherwise>
      <strong>
        <c:out value="${tab.subTabCaption}"/>
      </strong>
    </c:otherwise>
  </c:choose>
  <c:if test="${not st.last}"><span class="separator">|</span></c:if>
</c:forEach>
</div>

<div style="padding-top:1em">
  <jsp:include page="${agentParametersModel.selectedTabUrl}"/>
</div>
