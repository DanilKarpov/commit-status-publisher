<%@ include file="include-internal.jsp"%>
<jsp:useBean id="groups" scope="request" type="java.util.List<jetbrains.buildServer.controllers.agent.AgentsParametersReportController.ParameterGroup>"/>

<c:set var="url"><c:url value="/agents/agentsParametersReportResult.html"/></c:set>
<bs:refreshable containerId="queryResult" pageUrl="${url}">
  <c:if test="${not empty groups}">
  <table class="dark agentParametersReport borderBottom">
    <tr><th class="paramsReportHeader0">Parameter name / Parameter value / Agents</th></tr>
    <c:forEach var="group" items="${groups}">
      <c:choose>
        <c:when test="${group.parameterDefined}">
          <tr><td class="paramsReportHeader1"><c:out value="${group.parameterName}"/></td></tr>
          <c:forEach var="valGroup" items="${group.valueGroups}">
            <tr><td class="paramsReportHeader2"><bs:trim maxlength="200">${valGroup.parameterValue}</bs:trim></td></tr>
            <tr><td class="paramsReportValue">
              <c:forEach var="agent" items="${valGroup.agents}">
                <bs:agent agent="${agent}"/><br/>
              </c:forEach>

              <c:forEach var="agentType" items="${valGroup.agentTypes}">
                <bs:agentDetailsFullLink showCloudIcon="${true}" agentType="${agentType}"/><br/>
              </c:forEach>
            </td></tr>
          </c:forEach>
        </c:when>
        <c:otherwise>
          <tr><td class="paramsReportHeader1 parameterUndefined">&lt;Agents without parameter defined&gt;</td></tr>
          <tr><td class="paramsReportValue">
            <c:forEach var="agent" items="${group.agents}">
              <bs:agent agent="${agent}"/><br/>
            </c:forEach>
            <c:forEach var="agentType" items="${group.agentTypes}">
              <bs:agentDetailsFullLink showCloudIcon="${true}" agentType="${agentType}"/><br/>
            </c:forEach>
          </td></tr>
        </c:otherwise>
      </c:choose>
    </c:forEach>
  </table>
  </c:if>
</bs:refreshable>
