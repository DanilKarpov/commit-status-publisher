<%@ taglib prefix="bs" tagdir="/WEB-INF/tags"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<c:set var="agentType" value="${agentRestrictor.agentType}"/>
<c:choose>
  <c:when test="${agentType == null}">Agent deleted</c:when>
  <c:otherwise>
    <bs:agentDetailsLink agentType="${agentType}"/>
  </c:otherwise>
</c:choose>
