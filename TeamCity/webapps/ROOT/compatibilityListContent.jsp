<%@ include file="include-internal.jsp" %>
<%@ taglib prefix="agent" tagdir="/WEB-INF/tags/agent" %>
<jsp:useBean id="serverSummary" type="jetbrains.buildServer.web.openapi.ServerSummary" scope="request"/>
<jsp:useBean id="compatibilityModel" scope="request" type="jetbrains.buildServer.controllers.compatibility.CompatibilityModel"/>

<bs:linkCSS dynamic="${true}">
  /css/agentBlocks.css
</bs:linkCSS>
<bs:linkScript>
  /js/bs/agentBlocks.js
</bs:linkScript>
<script type="text/javascript">
  BS.AgentBlocks.mustPersistState = false;
</script>
<c:set var="showAllPoolsPropKey" value="teamcity.compatibility.showAllPools"/>
<c:set var="showAllPoolsEnabled" value="${ufn:booleanPropertyValue(currentUser, showAllPoolsPropKey)}"/>
<c:set var="poolsWithAgents" value="${compatibilityModel.activeTable.compatibleAgentsColumn.pools.size() + compatibilityModel.activeTable.incompatibleAgentsColumn.pools.size() + compatibilityModel.activeTable.compatibleExecutorsColumn.pools.size() + compatibilityModel.activeTable.incompatibleExecutorsColumn.pools.size()}"/>

<c:if test="${compatibilityModel.associatedPools.size() == 0}">
  <table class="agentsCompatibilityTable">
    <tr>
      <td>
        <bs:buildStatusIcon type="red-sign" className="warningIcon"/>Current project <strong><c:out value="${compatibilityModel.projectFullName}"/></strong> is not associated with any
        agent pool. New builds will not start until the project is added to at least one pool.
      </td>
    </tr>
  </table>
</c:if>

<c:if test="${compatibilityModel.associatedPools.size() > 0 and poolsWithAgents == 0}">
  <table class="agentsCompatibilityTable">
    <tr>
      <td>
        <bs:buildStatusIcon type="red-sign" className="warningIcon"/>Agent pools associated with the project <strong><c:out value="${compatibilityModel.projectFullName}"/></strong> are empty, builds won't be started.
        <c:choose>
          <c:when test="${compatibilityModel.associatedPools.size() == 1}">
            Please add compatible agents to the pool <bs:agentPoolLink agentPool="${compatibilityModel.associatedPools.get(0)}"/>
          </c:when>
          <c:otherwise>
            Please add compatible agents to one of the pools:
            <ul>
              <c:forEach var="pool" items="${compatibilityModel.associatedPools}">
                <li><bs:agentPoolLink agentPool="${pool}"/></li>
              </c:forEach>
            </ul>
          </c:otherwise>
        </c:choose>
      </td>
    </tr>
  </table>
</c:if>

<c:if test="${poolsWithAgents > 0}">
  <c:if test="${compatibilityModel.hasSeveralPools}">
    <div class="agentsToolbar">
      <bs:collapseExpand collapseAction="BS.AgentBlocks.collapseAll(); return false" expandAction="BS.AgentBlocks.expandAll(); return false"/>
    </div>
  </c:if>

  <bs:_compatibilityTable tableModel="${compatibilityModel.activeTable}" active="${true}"  />
</c:if>

<bs:refreshable containerId="otherPoolsAgents" pageUrl="${pageUrl}">
  <c:if test="${compatibilityModel.hasSeveralPools and not showAllPoolsEnabled}">
    <p>
      There can be compatible agents in other pools.
      <a href="#" onclick="BS.Util.show('showAllPoolsProgressInline'); BS.User.setBooleanProperty('${showAllPoolsPropKey}', true, { afterComplete: function() { $('otherPoolsAgents').refresh('showAllPoolsProgressInline'); } }); return false;">Show all agent pools &raquo;</a> <forms:saving id="showAllPoolsProgressInline" className="progressRingInline"/>
    </p>
  </c:if>
  <c:if test="${compatibilityModel.inactiveTable.agentsNotEmpty}">
    <p style="margin-top: 2em;">
      <bs:buildStatusIcon type="red-sign" className="warningIcon"/>Following agents belong to the agent pools which are not associated with <strong><c:out value="${compatibilityModel.projectFullName}"/></strong> project.
      <a href="#" onclick="BS.Util.show('showAllPoolsProgressInline'); BS.User.setBooleanProperty('${showAllPoolsPropKey}', false, { afterComplete: function() { $('otherPoolsAgents').refresh('showAllPoolsProgressInline'); } }); return false;">&laquo; Hide other agent pools</a> <forms:saving id="showAllPoolsProgressInline" className="progressRingInline"/>
    </p>
    <bs:_compatibilityTable tableModel="${compatibilityModel.inactiveTable}" active="${false}" />
  </c:if>
</bs:refreshable>
