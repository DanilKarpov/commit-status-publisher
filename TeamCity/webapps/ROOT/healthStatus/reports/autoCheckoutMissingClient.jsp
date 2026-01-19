<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>

<%--@elvariable id="buildType" type="jetbrains.buildServer.serverSide.SBuildType"--%>
<%--@elvariable id="buildDecisions" type="java.util.List<jetbrains.buildServer.controllers.healthStatus.reports.AutoCheckoutHealthPageExtension.BuildDecisionBean>"--%>

Some builds of <admin:viewOrEditBuildTypeLinkFull buildType="${buildType}"/> cannot use agent-side checkout because of the missing or misconfigured VCS client. See the build log for details:
<bs:truncatedList id="autoCheckoutReportMissingClient_${util:forJSIdentifier(healthStatusItem.identity)}" elements="${buildDecisions}">
  <jsp:attribute name="elemHTML">
    <bs:_viewLog build="${elem.build}" noLink="true" urlAddOn="${elem.logUrlAddOn}"/>
      <a href="${url}">Build #<c:out value="${elem.build.buildNumber}"/></a> on <bs:agentDetailsLink agent="${elem.build.agent}"/>
  </jsp:attribute>
</bs:truncatedList>

Agent-side checkout is recommended to improve the server performance and reduce the total build time.<bs:help file="VCS+Checkout+Mode"/>
