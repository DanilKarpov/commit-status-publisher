<%@ taglib prefix="bs" tagdir="/WEB-INF/tags"%>
<%@ taglib prefix="queue" tagdir="/WEB-INF/tags/queue"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<c:set var="pool" value="${agentRestrictor.agentPool}"/>
<c:choose>
  <c:when test="${pool == null}">Pool deleted</c:when>
  <c:otherwise>
    <queue:queuedBuildAgentsPopup itemId="${itemId}" buildTypeId="${buildTypeId}">
      <bs:agentPoolLink agentPool="${pool}" nameSuffix=" (${canRunOn})"/>
    </queue:queuedBuildAgentsPopup>
  </c:otherwise>
</c:choose>
