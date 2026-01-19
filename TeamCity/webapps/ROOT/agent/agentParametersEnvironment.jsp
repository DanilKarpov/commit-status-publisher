<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="agentDetails" scope="request" type="jetbrains.buildServer.controllers.agent.AgentDetailsFormBase"/>
<c:set var="agent" value="${agentDetails.agent}"/>

<%--<h2>Environment variables</h2>--%>
<div>Environment variables that will be included into environment variables list of build processes of a build</div>
<c:set var="enrironment" value="${agentDetails.definedEnvironmentVariables}"/>
<c:if test="${empty enrironment}">
    none available<br/><br/>
  </c:if>
<table class="definitionTable">
  <c:forEach items="${enrironment}" var="key">
    <tr>
      <th><c:out value="${key.key}"/></th>
      <td>&nbsp;<c:out value='${key.value}'/></td>
    </tr>
  </c:forEach>
</table>