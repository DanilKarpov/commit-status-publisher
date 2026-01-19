<%@ page import="jetbrains.buildServer.serverSide.NodeResponsibility" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>

<c:set var="missingResponsibilities" value="${healthStatusItem.additionalData['missingResponsibilities']}"/>
<c:set var="checkForChangesResp" value="<%=NodeResponsibility.CAN_CHECK_FOR_CHANGES%>"/>
<c:set var="processBuildTriggersResp" value="<%=NodeResponsibility.CAN_PROCESS_BUILD_TRIGGERS%>"/>

<div>
  <c:set var="consequences" value=""/>
  There are currently no TeamCity nodes with the following responsibilities:
  <ul>
    <c:forEach items="${missingResponsibilities}" var="nr">
      <li>
        <c:out value="${nr.displayName}"/>
      </li>
    </c:forEach>
  </ul>

  As a result:
  <ul>
    <c:forEach items="${missingResponsibilities}" var="nr">
      <li>
        <c:choose>
          <c:when test="${nr == checkForChangesResp}">queued builds won't be able to start</c:when>
          <c:when test="${nr == processBuildTriggersResp}">new builds won't be triggered</c:when>
        </c:choose>
      </li>
    </c:forEach>
  </ul>

  Please check the <a href="<c:url value="/admin/admin.html?item=nodesConfiguration"/>">nodes configuration</a>.
</div>