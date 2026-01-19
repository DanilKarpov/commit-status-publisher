<%@ page import="jetbrains.buildServer.serverSide.CurrentNodeInfo" %>
<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<c:set var="multiNode" value="${healthStatusItem.additionalData['multiNode']}"/>
<c:set var="javaVersionStr" value="${healthStatusItem.additionalData['javaVersionStr']}"/>

<c:set var="node">
  <c:choose>
    <c:when test="${multiNode}">
      Current TeamCity node (<%=CurrentNodeInfo.getNodeId()%>)
    </c:when>
    <c:otherwise>
      This TeamCity server
    </c:otherwise>
  </c:choose>
</c:set>

<div>
  <bs:out>
    ${node} is running under Java <c:out value="${javaVersionStr}"/>. This version of Java will no longer be supported in future versions of TeamCity. Please upgrade Java to version 21.
  </bs:out>
  <p>
    As Java is not upgraded automatically during the TeamCity autoupdate, please install the new version manually using
    <bs:helpLink file="how-to#Install+Non-Bundled+Version+of+Java">this instruction</bs:helpLink>.
    If you are upgrading from 32- to 64-bit Java, consider adjusting settings as described
      <bs:helpLink file="configure-server-installation#Configure+Memory+Settings+for+TeamCity+Server">here</bs:helpLink>.
    See the full list of
    <bs:helpLink file="supported-platforms-and-environments#Supported+Java+Versions+for+TeamCity+Server">supported Java versions</bs:helpLink>.
  </p>
</div>