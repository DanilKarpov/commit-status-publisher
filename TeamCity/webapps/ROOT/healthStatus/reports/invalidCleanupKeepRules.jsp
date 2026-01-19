<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<c:set var="message">
  <c:choose>
    <c:when test="${healthStatusItem.additionalData.containsKey('project')}">
      The project <admin:editProjectLinkFull project="${healthStatusItem.additionalData.get('project')}"/>
      contains illegal keep rule with id=${healthStatusItem.additionalData.get('featureId')}.
    </c:when>
    <c:when test="${healthStatusItem.additionalData.containsKey('buildType')}">
      The build configuration <admin:editBuildTypeLinkFull buildType="${healthStatusItem.additionalData.get('buildType')}"/>
      contains illegal keep rule with id=${healthStatusItem.additionalData.get('featureId')}.
    </c:when>
  </c:choose>

  <c:if test="${healthStatusItem.additionalData.containsKey('paramName')}">
    <c:choose>
      <c:when test="${healthStatusItem.additionalData.containsKey('paramValue')}">
        The problematic <c:out value="${healthStatusItem.additionalData.get('rulePart')}"/> parameter name/value:
        '<c:out value="${healthStatusItem.additionalData.get('paramName')}"/>'/'<c:out value="${healthStatusItem.additionalData.get('paramValue')}"/>'.
      </c:when>
      <c:otherwise>
        The problematic <c:out value="${healthStatusItem.additionalData.get('rulePart')}"/> parameter name: '<c:out value="${healthStatusItem.additionalData.get('paramName')}"/>'.
      </c:otherwise>
    </c:choose>
  </c:if>
  <c:if test="${healthStatusItem.additionalData.containsKey('message')}">
    Error message: <c:out value="${healthStatusItem.additionalData.get('message')}"/>.
  </c:if>
</c:set>
<c:out value="${message}" escapeXml="false"/>