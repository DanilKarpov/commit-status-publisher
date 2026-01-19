<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>

<%--@elvariable id="buildType" type="jetbrains.buildServer.serverSide.SBuildType"--%>
<%--@elvariable id="buildDecision" type="jetbrains.buildServer.controllers.healthStatus.reports.AutoCheckoutHealthPageExtension.BuildDecisionBean"--%>

Builds of <admin:viewOrEditBuildTypeLinkFull buildType="${buildType}"/> use server-side checkout because the checkout rules are not suitable for agent-side checkout. See the build log for details:
<ul>
  <li>
    <bs:_viewLog build="${buildDecision.build}" noLink="true" urlAddOn="${buildDecision.logUrlAddOn}"/>
    <a href="${url}">Build #<c:out value="${buildDecision.build.buildNumber}"/></a> on <bs:agentDetailsLink agent="${buildDecision.build.agent}"/>
  </li>
</ul>


