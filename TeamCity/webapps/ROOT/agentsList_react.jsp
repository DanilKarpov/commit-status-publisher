<%@ include file="include-internal.jsp"%>
<%@ taglib prefix="agent" tagdir="/WEB-INF/tags/agent"%>
<%@ taglib prefix="intprop" uri="/WEB-INF/functions/intprop"%>
<c:set var="getFullDataUnauthorizedAgents" value="${intprop:getBoolean('teamcity.ui.agents.unauthorized.loadFullData')}"/>
<jsp:useBean id="currentUser" type="jetbrains.buildServer.users.User" scope="request"/>
<jsp:useBean id="agentsForm" scope="request" type="jetbrains.buildServer.controllers.agent.AgentListBaseForm"/>
<%--@elvariable id="pools" type="java.util.List<jetbrains.buildServer.serverSide.agentPools.AgentPool>"--%>
<%--@elvariable id="agentsCount" type="java.lang.Integer"--%>
<%--@elvariable id="agentTabPage" type="java.lang.String"--%>
<%--@elvariable id="tabsCountersOnly" type="java.lang.Boolean"--%>
<bs:linkScript>
  /js/bs/agentBlocks.js
  /js/bs/agents_react.js
</bs:linkScript>
<bs:linkCSS>
  /css/agents_react.css
</bs:linkCSS>
<div id="buildAgents">
  <bs:messages key="agentNotFound"/>
  <bs:messages key="agentRemoved"/>
</div>

<div id="panel">
  <div id="leftPanel">
    <div id="description" class="toolbar">
      <c:if test="${agentsCount > 0}">
        There <bs:are_is val="${agentsCount}"/> <b>${agentsCount}</b> available agent<bs:s val="${agentsCount}"/>.
      </c:if>
      <c:if test="${agentsCount == 0}">
        There are no <c:if test="${fn:contains(agentTabPage, 'unauthorized')}">unauthorized</c:if><c:if test="${fn:contains(agentTabPage, 'unregistered')}">disconnected</c:if> agents.
      </c:if>
    </div>
    <c:if test="${not agentsForm.noAgentDetailsPermission}">
      <div id="groupToolbar" class="toolbar">
        <c:if test="${agentsForm.hasSeveralPools}"><span><agent:poolCollapseExpandAll grouped="${agentsForm.actuallyGroupByPools}"/><agent:groupByPoolsCheckbox_react/>&nbsp;&nbsp;&nbsp;</span></c:if>
        <span id="sorter" <c:if test="${agentsCount < 1}">style="display: none;"</c:if>><span id="sorter_inner"></span></span>
      </div>
    </c:if>
  </div>
</div>
<div id="fetcher"></div>
<script type="text/javascript">
  (function () {
    BS.AgentsReact.showLoader();
    var UPDATE_PERIOD = 20000;
    var options = BS.AgentsReact.getFetcherOptions(UPDATE_PERIOD);
    var additionalFields = {};
    BS.AgentsReact.additionalFields = additionalFields;
    <c:if test="${fn:contains(agentTabPage, 'unauthorized')}">
    options = BS.AgentsReact.getUnauthorizedAgentsFetcherOptions(UPDATE_PERIOD);
      <c:if test="${getFullDataUnauthorizedAgents}">
        additionalFields.authorizedInfo = true;
      </c:if>
      <c:if test="${not getFullDataUnauthorizedAgents}">
        additionalFields.authorizedInfo = false;
        additionalFields.lastActivityTime = false;
        additionalFields.enabledInfo = false;
      </c:if>
    </c:if>
    <c:if test="${fn:contains(agentTabPage, 'unregistered')}">
    options = BS.AgentsReact.getUnregisteredAgentsFetcherOptions(UPDATE_PERIOD);
    additionalFields.disconnectionComment = true;
    </c:if>
    additionalFields.cloudInfo = true;
    options.additionalFields = additionalFields;
    ReactUI.renderAgentsFetcher('fetcher', options);

    <c:if test="${fn:contains(agentTabPage, 'unauthorized')}">
      <%--@elvariable id="cloudAgentIds" type="java.lang.String"--%>
      ReactUI.receiveAgentsInCloud(${cloudAgentIds});
    </c:if>

    BS.AgentsReact.renderSorter('sorter_inner',"${agentTabPage}", additionalFields);
  })();
</script>
<c:choose>
  <c:when test="${not agentsForm.actuallyGroupByPools}">
    <div id="agentsPanel" style="display: none;">
      <div class="renderAgents">
        <div id="connectedAgents"></div>
      </div>
      <script type="text/javascript">
        (function () {
          var locator = BS.AgentsReact.getAgentsLocator();
          <c:if test="${fn:contains(agentTabPage, 'unauthorized')}">
          locator = BS.AgentsReact.getUnauthorizedAgentsFetcherOptions(6000).locator;
          </c:if>
          <c:if test="${fn:contains(agentTabPage, 'unregistered')}">
          locator = BS.AgentsReact.getUnregisteredAgentsFetcherOptions(6000).locator;
          </c:if>
          var rendererOptions = BS.AgentsReact.getAgentsRendererOptions(
            0,
            undefined,
            function(poolId, agents){
              var running = 0;
              agents.forEach(function(agent) {
                if ('build' in agent) {
                  running++;
                }
              });
              if (agents.length > 0){
                $j('#agentsPanel').css('display','block');
              } else {
                $j('#agentsPanel').css('display','none');
              }
            },
            locator,
            true,
            "${agentTabPage}"
          );
          rendererOptions.additionalFields = BS.AgentsReact.additionalFields;
          ReactUI.renderAgents('connectedAgents', rendererOptions);
        })();
      </script>
    </div>
  </c:when>
  <c:otherwise>
    <c:forEach items="${pools}" var="pool" varStatus="poolStatus">
      <c:set var="poolId" value="${pool.agentPoolId}"/>
      <bs:chooseAgentPoolBlockState agentPoolId="${pool.agentPoolId}">
        <jsp:attribute name="ifExpanded">
          <c:set var="ifCollapsed" value="false" />
        </jsp:attribute>
        <jsp:attribute name="ifCollapsed">
          <c:set var="ifCollapsed" value="true" />
        </jsp:attribute>
      </bs:chooseAgentPoolBlockState>
      <div id="poolPanel_${poolId}" class="agentPoolBox" style="display: none;">
        <div class="agentDescription blockHeader" onclick="BS.AgentBlocks.toggleBlock('${poolId}', true); BS.AgentsReact.togglePoolCollapsedState(${poolId})">
          <span class="agentPoolDescription">
            <bs:agentPoolHandle agentPoolId="${poolId}" skipClickHandler="true"/>
            <bs:agentPoolLink agentPool="${pool}" groupHeader="${true}"/>
           </span>
          <input type="hidden" class="agentsCount" id="agentsCount_${poolId}" value="0"/>
          <input type="hidden" class="runningAgentsCount" id="runningAgentsCount_${poolId}" value="0"/>
          <span class="commentText" id="comment_${poolId}"><%--will be provided in js--%></span>
        </div>
        <div class="renderAgents agentsBlock agentRow-${poolId}"
            <c:if test="${ifCollapsed}">style='display: none'</c:if>>
          <div id="connectedAgents_${poolId}"></div>
        </div>
        <script type="text/javascript">
          (function () {
            var locator = BS.AgentsReact.getAgentsLocator();
            <c:if test="${fn:contains(agentTabPage, 'unauthorized')}">
            locator = BS.AgentsReact.getUnauthorizedAgentsFetcherOptions(6000).locator;
            </c:if>
            <c:if test="${fn:contains(agentTabPage, 'unregistered')}">
            locator = BS.AgentsReact.getUnregisteredAgentsFetcherOptions(6000).locator;
            </c:if>

            BS.AgentsReact.setPoolCollapsedState(${poolId}, ${ifCollapsed})

            var rendererOptions = BS.AgentsReact.getAgentsRendererOptions(
              0,
              ${poolId},
              function(poolId, agents){
                var running = 0;
                agents.forEach(function(agent){
                  if (agent.pool.id === poolId){
                    if ('build' in agent){
                      running++;
                    }
                  }
                });
                if (agents.length > 0){
                  $j('#poolPanel_${poolId}').css('display','block');
                } else {
                  $j('#poolPanel_${poolId}').css('display','none');
                }
                $j('#runningAgentsCount_' + poolId).val(running);
                $j('#agentsCount_' + poolId).val(agents.length);
                <c:if test="${fn:startsWith(agentTabPage, 'registered')}">
                $j('#comment_' + poolId).html(BS.AgentsReact.getPoolDescription(running, agents.length));
                </c:if>
              },
              locator,
              ${poolStatus.index == 0}
            );
            rendererOptions.additionalFields = BS.AgentsReact.additionalFields;
            ReactUI.renderAgents('connectedAgents_${poolId}', rendererOptions);
          })();
        </script>
      </div>
    </c:forEach>
    <agent:restoreAgentBlockStates grouped="${true}"/>
  </c:otherwise>
</c:choose>
<script type="text/javascript">
  (function () {
    var locator = BS.AgentsReact.getFetcherOptions(6000).locator;
    <c:if test="${fn:contains(agentTabPage, 'unauthorized')}">
    locator = BS.AgentsReact.getUnauthorizedAgentsFetcherOptions(6000).locator;
    </c:if>
    <c:if test="${fn:contains(agentTabPage, 'unregistered')}">
    locator = BS.AgentsReact.getUnregisteredAgentsFetcherOptions(6000).locator;
    </c:if>
    BS.AgentsReact.subscribeOnStoreChange(locator, "${agentTabPage}", ${agentsForm.actuallyGroupByPools}, ${agentsForm.licensesLeft});
       BS.periodicalExecutor(BS.AgentsReact.checkPools, 6000).start();
    <c:if test="${agentsForm.actuallyGroupByPools}">
    </c:if>
  })();
</script>


<div id="installLinks" style="display: none;">
  <h3 class="title">Install Build Agents</h3>
  <%@ include file="installLinks.jspf" %>
</div>

<bs:changeAgentStatus agentActionCode="changeAuthorizeStatus" agentPoolsList="${pools}"/>
<bs:changeAgentStatus agentActionCode="changeAgentStatus"/>

<et:subscribeOnEvents>
<jsp:attribute name="eventNames">
  AGENT_REGISTERED
  AGENT_UNREGISTERED
  AGENT_REMOVED
  AGENT_STATUS_CHANGED
</jsp:attribute>
<jsp:attribute name="eventHandler">
  BS.AgentsReact.refreshTabsCounters();
</jsp:attribute>
</et:subscribeOnEvents>

