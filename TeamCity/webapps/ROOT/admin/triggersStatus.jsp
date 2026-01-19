<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="triggersInfo" type="java.util.List<jetbrains.buildServer.diagnostic.web.TriggersStatusExtension.TriggerTypeInfo>" scope="request"/>

<table class="runnerFormTable" style="width: 100%; margin-top: 0.5em">
  <tr class="groupingTitle">
    <td>Trigger name</td>
    <td>Count of enabled triggers</td>
    <td>Responsible node</td>
  </tr>
  <c:forEach items="${triggersInfo}" var="info" varStatus="pos">
    <tr>
      <td><bs:escapeForJs text="${info.triggerDisplayName}" forHTMLAttribute="true"/></td>
      <td>${info.triggersCount}</td>
      <td><bs:escapeForJs text="${info.responsibleNodeId}" forHTMLAttribute="true"/></td>
    </tr>
  </c:forEach>
</table>