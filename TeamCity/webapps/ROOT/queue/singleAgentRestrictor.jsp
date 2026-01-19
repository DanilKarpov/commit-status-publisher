<%@ taglib prefix="bs" tagdir="/WEB-INF/tags"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<c:set var="agent" value="${agentRestrictor.buildAgent}"/>
<c:choose>
  <c:when test="${agent == null}">Agent deleted</c:when>
  <c:otherwise>
    <bs:agentDetailsLink agent="${agent}"/>
  </c:otherwise>
</c:choose>
