<%@include file="/include-internal.jsp" %>
<jsp:useBean id="cloudImageWarnings" scope="request" type="java.util.Set<jetbrains.buildServer.clouds.server.serverHealth.CloudImageWarnings.CloudImageWarningType>"/>

<div>
  <c:forEach var="warning" items="${cloudImageWarnings}">

    <div>
      <span class="agentVersion" <bs:tooltipAttrs text="${warning.description}"/>
        ><bs:buildStatusIcon type="red-sign" className="warningIcon"
      /></span
      ><c:out value="${warning.description}"/>
    </div>
  </c:forEach>
</div>
