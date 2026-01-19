<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<c:set var="message">
  <c:if test="${healthStatusItem.additionalData.containsKey('buildType')}">
    The build configuration <admin:editBuildTypeLinkFull buildType="${healthStatusItem.additionalData.get('buildType')}"/>
    has the following rule errors: <bs:out value="${healthStatusItem.additionalData.get('approvalRuleErrors')}"/>.
  </c:if>
  <c:if test="${healthStatusItem.additionalData.containsKey('template')}">
    The template <admin:editTemplateLinkFull template="${healthStatusItem.additionalData.get('template')}"/>
    has the following rule errors: <bs:out value="${healthStatusItem.additionalData.get('approvalRuleErrors')}"/>.
  </c:if>
  <c:if test="${healthStatusItem.additionalData.containsKey('projectWithUntrustedSettings')}">
    The project <admin:editProjectLinkFull project="${healthStatusItem.additionalData.get('projectWithUntrustedSettings')}"/>
    has the following approval rule errors in the Untrusted Builds settings: <bs:out value="${healthStatusItem.additionalData.get('approvalRuleErrors')}"/>.
  </c:if>
</c:set>
<c:out value="${message}" escapeXml="false"/>
