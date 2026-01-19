<%@ page import="jetbrains.buildServer.serverSide.healthStatus.ItemSeverity" %>
<%@ page import="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" %>
<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<jsp:useBean id="showMode" type="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" scope="request"/>
<jsp:useBean id="healthStatusReportUrl" type="java.lang.String" scope="request"/>

<c:set var="isSeverityInfo" value='<%=healthStatusItem.getSeverity()==ItemSeverity.INFO%>'/>
<c:set var="inplaceMode" value='<%=showMode==HealthStatusItemDisplayMode.IN_PLACE%>'/>
<c:set var="agent" value='<%=healthStatusItem.getAdditionalData().get("agent")%>'/>
<c:set var="instance" value='<%=healthStatusItem.getAdditionalData().get("instance")%>'/>

  <c:if test="${not empty instance}">
    An error occurred while stopping <c:out value="${instance.cloudName}"/> instance <strong><c:out value="${instance.name}"/></strong>.
    Its current state: <strong><c:out value="${instance.status}"/></strong>. See teamcity-cloud.log for details.
    <c:if test="${not inplaceMode}">
      <c:if test="${not empty instance.errorInfo}">
        <div>
          Cloud error message: <c:out value="${instance.errorInfo.message}"/>
        </div>
      </c:if>
      <c:if test="${not empty instance.throwable}">
        <div>
          Exception: <c:out value="${instance.throwable.message}"/>
        </div>
      </c:if>
    </c:if>
  </c:if>
  <c:if test="${not empty agent and isSeverityInfo and not inplaceMode}">
    Agent <bs:agentDetailsLink agentName="${agent.agentName}" agentTypeId="${agent.agentTypeId}"/>
    (<c:out value="${agent.cloudName}"/> profile <strong><c:out value="${agent.profileName}"/></strong>)
    is idle for <c:out value="${agent.agentIdleMinutes}"/> minutes whereas idle shutdown timeout is
    <c:out value="${agent.timeoutMinutes}"/> minutes
  </c:if>
