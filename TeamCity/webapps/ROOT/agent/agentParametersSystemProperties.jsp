<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="agentDetails" scope="request" type="jetbrains.buildServer.controllers.agent.AgentDetailsFormBase"/>

<%--<h2>System Properties</h2>--%>
<div>This is a list of properties that can be used for defining build configuration requirements and in the build scripts.</div>
<c:set var="buildParameters" value="${agentDetails.definedSystemProperies}"/>
<c:choose>
  <c:when test="${empty buildParameters}">
    none available<br/><br/>
  </c:when>
  <c:otherwise>

    <table class="definitionTable">
      <c:forEach items="${buildParameters}" var="key">
        <tr>
          <th><c:out value="${key.key}"/></th>
          <td>&nbsp;<c:out value='${key.value}'/></td>
        </tr>
      </c:forEach>
    </table>

  </c:otherwise>
</c:choose>
