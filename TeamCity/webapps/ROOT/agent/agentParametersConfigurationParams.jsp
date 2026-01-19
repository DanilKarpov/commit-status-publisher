<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="agentDetails" scope="request" type="jetbrains.buildServer.controllers.agent.AgentDetailsFormBase"/>

<%--<h2>Configuration parameters</h2>--%>
<div>This is a list of properties that can only be used as references in the TeamCity UI.</div>

<c:set var="configParameters" value="${agentDetails.definedConfigurationParameters}"/>
<c:choose>
  <c:when test="${empty configParameters}">
    none available<br/><br/>
  </c:when>
  <c:otherwise>

    <table class="definitionTable">
      <c:forEach items="${configParameters}" var="key">
        <tr>
          <th><c:out value="${key.key}"/></th>
          <td>&nbsp;<c:out value='${key.value}'/></td>
        </tr>
      </c:forEach>
    </table>

  </c:otherwise>
</c:choose>
