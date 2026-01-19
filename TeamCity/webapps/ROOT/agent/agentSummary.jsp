<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="agentDetails" scope="request" type="jetbrains.buildServer.controllers.agent.AgentDetailsForm"/>
<c:set var="agent" value="${agentDetails.agent}"/>
<c:set var="agentType" value="${agentDetails.agentType}"/>
<c:set var="runningBuild" value="${agent.runningBuild}"/>
<et:_subscribeAgentTab>
  AGENT_REGISTERED
  AGENT_PARAMETERS_UPDATED
  AGENT_UNREGISTERED
  AGENT_REMOVED
  AGENT_STATUS_CHANGED
  BUILD_STARTED
  BUILD_FINISHED
  BUILD_INTERRUPTED
  BUILD_REMOVED
</et:_subscribeAgentTab>

<div id="agentSummary" class="divsWithHeaders">
  <div>
    <h2>Status</h2>
    <div class="details">
      <ul class="agentSummary">
        <li>
          <c:choose>
            <c:when test="${agent.registered}"><span class="registered">Connected</span> since
              <strong><bs:date value="${agent.registrationTimestamp}"/></strong>, last communication date <strong><bs:date value="${agent.lastCommunicationTimestamp}"/></strong></c:when>
            <c:otherwise><span class="red-text">Disconnected</span><c:if test="${not empty agent.unregistrationComment}"> (<c:out value="${agent.unregistrationComment}"/>)</c:if>, last communication date <strong>
              <bs:date value="${agent.lastCommunicationTimestamp}"/>
            </strong>
            <authz:authorize anyPermission="REMOVE_AGENT,REMOVE_AGENT_FOR_PROJECT"
                             projectIds="${agent.agentPool.projectIds}"
                             checkGlobalPermissions="true">
              <jsp:attribute name="ifAccessGranted">
                <c:set var="removeAgentForm">
                  <form id="removeAgentForm" action="<c:url value='/agentDetails.html'/>" style="display:inline; margin-left: 1em;">
                    <input class="btn btn_mini" type="button" value="Remove" onclick="BS.RemoveAgent.remove(${not empty runningBuild})"/>
                    <input type="hidden" name="removeAgent" value="true"/>
                    <input type="hidden" name="agentId" value="${agent.id}"/>
                  </form>
                </c:set>
                <c:choose>
                  <c:when test="${not empty runningBuild}">
                    <bs:canStopBuild build="${runningBuild}"><jsp:attribute name="ifAccessGranted">${removeAgentForm}</jsp:attribute></bs:canStopBuild>
                  </c:when>
                  <c:otherwise>${removeAgentForm}</c:otherwise>
                </c:choose>
              </jsp:attribute>
            </authz:authorize>
            </c:otherwise>
          </c:choose>
        </li>
        <li>
          <c:url var="agentStatusUrl" value="/agentStatus.html?id=${agent.id}"/>
          <jsp:include page="/agentStatus.html?id=${agent.id}"/>
        </li>
      </ul>
    </div>
  </div>

  <div>
    <h2>Details</h2>
    <div class="details">
      <ul class="agentSummary">
        <li>Agent name: <strong><c:out value="${agent.name}"/></strong></li>
        <c:set var="agentHost" value="${agent.hostName}"/>
        <c:if test="${agentDetails.cloudProfile != null}">
          <authz:authorize projectId="${agentDetails.cloudProfile.projectId}" allPermissions="VIEW_AGENT_CLOUDS">
              <li>Cloud image: <bs:agentDetailsFullLink
                  showCloudIcon="true"
                  doNotShowPoolInfo="true"
                  agentType="${agent.agentType}">${agent.agentType.details.name}</bs:agentDetailsFullLink>
              </li>
          </authz:authorize>
        </c:if>
        <li>Hostname: <strong id="agent-hostname">${agentHost}</strong><bs:copy2ClipboardLink dataId="agent-hostname"/></li>
        <c:if test="${agent.hostAddress != agentHost}">
          <li>IP: <strong>${agent.hostAddress}</strong></li>
        </c:if>
        <li>Port: <strong>${agent.port}</strong></li>
        <%--@elvariable id="isMainNode" type="java.lang.Boolean"--%>
        <c:if test="${isMainNode}">
          <li>Communication protocol: <strong><c:out value="${agent.communicationProtocolDescription}"/><bs:help file="Setting+up+and+Running+Additional+Build+Agents" anchor="Agent-ServerDataTransfers"/></strong></li>
        </c:if>
        <li>Operating system: <bs:osIcon osName="${agent.operatingSystemName}"/><strong>${agent.operatingSystemName}</strong></li>
        <li>CPU rank: <strong><c:choose><c:when test="${agent.cpuBenchmarkIndex > 0}">${agent.cpuBenchmarkIndex}</c:when><c:otherwise>unknown</c:otherwise></c:choose></strong></li>
        <c:set var="pool" value="${agentType.agentPool}"/>
        <li>Pool: <strong><bs:agentPoolLink agentPool="${pool}" hidePoolWord="${true}"/></strong></li>
        <%--@elvariable id="canManageClouds" type="java.lang.Boolean"--%>
        <c:if test="${agent.registered and canManageClouds}">
          <li>
            <bs:agentOutdated agent="${agent}"/>
            Version: <strong>${agent.version}</strong>
            <c:if test="${agent.outdated}"> (outdated, current version is <strong>${agent.currentAgentVersion}</strong>)</c:if>
            <c:if test="${!agent.outdated && agent.pluginsOutdated}"> (some plugins on the agent are out of date)</c:if>
            <%--@elvariable id="isUsesOldJava" type="java.lang.Boolean"--%>
            <c:if test="${isUsesOldJava}"><div>This agent can't be upgraded automatically since it is running under an unsupported JRE. Java versions 8 and later are supported.</div></c:if>
          </li>
        </c:if>
      </ul>
    </div>
  </div>

  <c:if test="${not empty runningBuild}">
  <div>
    <h2>Running build</h2>
    <div class="details">
      <authz:authorize allPermissions="VIEW_PROJECT" projectId="${runningBuild.projectId}">
        <jsp:attribute name="ifAccessGranted">
          <style>
            #running {
              display: inline-block;
              min-height: 64px;
              line-height: 64px;
              width: 100%;
            }
          </style>
          <div id="running"></div>
          <script>
            (function () {
              var locator = 'buildId:${runningBuild.buildId},state:(running:true)';
              ReactUI.renderBuilds('running', {
                withLoader: true,
                inlineLoader: true
              }, {
                withRunning: true,
                locator: locator
              }, {
                showAgent: false
              });
            })();
          </script>
        </jsp:attribute>
        <jsp:attribute name="ifAccessDenied">
          <bs:buildStatusIcon type="running-green"/>Running a build. You do not have permissions to see the build details.
        </jsp:attribute>
      </authz:authorize>
    </div>
  </div>
  </c:if>
  <ext:extensionsAvailable placeId="<%=PlaceId.AGENT_SUMMARY%>">
    <bs:refreshable containerId="agentSummaryExtensions" pageUrl="${pageUrl}">
      <h2>Miscellaneous</h2>
      <div class="details">
        <ext:includeExtensions placeId="<%=PlaceId.AGENT_SUMMARY%>"/>
      </div>
    </bs:refreshable>
  </ext:extensionsAvailable>
</div>

<bs:changeAgentStatus agentActionCode="changeAgentStatus"/>
<%--@elvariable id="agentPoolsList" type="java.util.List<jetbrains.buildServer.serverSide.agentPools.AgentPool>"--%>
<%--@elvariable id="selectedAgentPool" type="java.lang.Integer"--%>
<bs:changeAgentStatus agentActionCode="changeAuthorizeStatus"
                      agentPoolsList="${agentPoolsList}"
                      selectedAgentPool="${selectedAgentPool}"/>
