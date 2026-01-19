<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="jetbrains.buildServer.web.util.WebUtil" %>
<%@ page import="jetbrains.buildServer.util.StringUtil" %>
<%@include file="/include-internal.jsp"%>

<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<c:set var="message" value="${healthStatusItem.additionalData['message']}"/>

<c:out value="${message}" escapeXml="false"/><br/>
<c:choose>
  <c:when test="${WebUtil.withExperimentalOverview(pageContext.request)}">
    <c:set var="reportUrl"><c:url value="/agents/overview?tab=agentsParametersReport&iframeSrc=${StringUtil.encodeURLParameter(WebUtil.getRootUrl(pageContext.request))}%2Fagents.html%3Ftab%3DagentsParametersReport%26embedded%3Dtrue%23teamcity.serverUrl" /></c:set>
  </c:when>
  <c:otherwise>
    <c:set var="reportUrl"><c:url value="/agents.html?tab=agentsParametersReport#teamcity.serverUrl"/></c:set>
  </c:otherwise>
</c:choose>
Visit <a href="<c:out value="${reportUrl}" escapeXml="false"/>">agent parameters report</a> to view server URL configured on agents.
