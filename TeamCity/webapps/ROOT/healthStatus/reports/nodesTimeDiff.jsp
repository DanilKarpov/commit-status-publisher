<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<c:set var="message">
  <c:set var="additionalData" value="${healthStatusItem.additionalData}"/>
  <c:forEach items="${additionalData}" var="dataEntry">
    <c:if test="${dataEntry.key.startsWith('anotherNode.')}">
      <c:set var="nodeData" value="${dataEntry.value}"/>
      <c:set var="nodeId" value="${nodeData.get('nodeId')}"/>
      <c:set var="offset" value="${nodeData.get('offset')}"/>
      <c:set var="isBehind" value="${nodeData.get('isBehind')}"/>
      The node '${nodeId}' time is not in sync with this server time. It is ${offset} <c:if test="${isBehind}">behind</c:if><c:if test="${!isBehind}">ahead</c:if>.
    </c:if>
  </c:forEach>
  <c:if test="${additionalData.containsKey('theNode')}">
    <c:set var="nodeData" value="${additionalData.get('theNode')}"/>
    <c:set var="sourceName" value="${nodeData.get('sourceName')}"/>
    <c:set var="offset" value="${nodeData.get('offset')}"/>
    <c:set var="isBehind" value="${nodeData.get('isBehind')}"/>
    This server time is not in sync with the ${sourceName} time. It is ${offset} <c:if test="${isBehind}">behind</c:if><c:if test="${!isBehind}">ahead</c:if>.
  </c:if>
</c:set>
<c:out value="${message}" escapeXml="false"/>