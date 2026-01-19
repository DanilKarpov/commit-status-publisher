<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>

<%--@elvariable id="currentNode" type="jetbrains.buildServer.serverSide.impl.OnlineTeamCityNode"--%>
<%--@elvariable id="otherNode" type="jetbrains.buildServer.serverSide.impl.OnlineTeamCityNode"--%>
<%--@elvariable id="otherNodeUrl" type="java.lang.String"--%>
<%--@elvariable id="currentNodeIsMain" type="java.lang.Boolean"--%>
<%--@elvariable id="stoppedDueToDataUpgradeTime" type="java.util.Date"--%>

<c:choose>
  <c:when test="${stoppedDueToDataUpgradeTime != null}">
    TeamCity data was upgraded by the main TeamCity Server at <bs:formatDate value="${stoppedDueToDataUpgradeTime}"/>, the current node stopped refreshing the data.<br/>
    Update the secondary node to the same build as the main TeamCity Server.
  </c:when>
  <c:when test="${currentNodeIsMain}">
    The <c:if test="${otherNodeUrl != null}"><a href="${otherNodeUrl}"></c:if>Secondary Node (id: <c:out value='${otherNode.id}'/>)<c:if test="${otherNodeUrl != null}"></a></c:if> version (<c:out value="${otherNode.displayVersion}"/>, build ${otherNode.buildNumber}) doesn't match the current server version.<br/>
    Update the secondary node to the same build as the main TeamCity Server.
    <div style="margin-top: 0.5em;">
        <b>Node Details</b>
    </div>
    <div>
      <c:out value="${otherNode.description}"/>
    </div>
  </c:when>
  <c:otherwise>
    The version of the main <c:if test="${otherNodeUrl != null}"><a href="${otherNodeUrl}"></c:if>TeamCity Server<c:if test="${otherNodeUrl != null}"></a></c:if> (<c:out value="${otherNode.displayVersion}"/>, build <c:out value="${otherNode.buildNumber}"/>) doesn't match the current node version.<br/>
    <a href="<c:url value='/admin/admin.html?item=update'/>">Update</a> the secondary node to the same build as the main TeamCity Server.
  </c:otherwise>
</c:choose>

