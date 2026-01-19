<%@ page import="jetbrains.buildServer.serverSide.BuildAgentManager.RunConfigurationPolicy" %><%@
    include file="/include-internal.jsp" %><%@
    taglib prefix="agent" tagdir="/WEB-INF/tags/agent"

%><jsp:useBean id="agentDetails" scope="request" type="jetbrains.buildServer.controllers.agent.AgentDetailsFormBase"
/><jsp:useBean id="serverSummary" type="jetbrains.buildServer.web.openapi.ServerSummary" scope="request"
/><c:set var="hasSeveralPools" value="${serverSummary.hasSeveralAgentPools}"
/><c:set var="agentType" value="${agentDetails.agentType}"
/><c:set var="url" value="agentDetails.html?${agentDetailInfo.urlParameters}&tab=agentCompatibleConfigurations"
/><c:set var="cssClass" value=""/>
<script type="text/javascript">
  BS.CompatibilityUtils.rewriteUrlIfAllHash();
</script>
<c:if test="${agentDetails.allConfigurationsCount == 0}">
  <p>There are no configurations found.</p>
</c:if>
<c:if test="${agentDetails.allConfigurationsCount > 0}">

  <div>
    <div class="policyChooser">
      <label for="policy">Current run configuration policy:</label>

      <authz:authorize projectIds="${agentType.agentPool.projectIds}" checkGlobalPermissions="true"
                       anyPermission="CHANGE_AGENT_RUN_CONFIGURATION_POLICY,CHANGE_AGENT_RUN_CONFIGURATION_POLICY_FOR_PROJECT">
        <jsp:attribute name="ifAccessGranted">
          <select name="policy" id="policy" onchange="BS.AgentRunPolicy.onPolicyChange(${agentType.agentTypeId}, this.options[this.selectedIndex].value)">
            <forms:option value="<%=RunConfigurationPolicy.ALL_COMPATIBLE_CONFIGURATIONS.name()%>"
                          selected="${agentDetails.allConfigurationsPolicy}">Run all compatible configurations</forms:option>
            <forms:option value="<%=RunConfigurationPolicy.SELECTED_COMPATIBLE_CONFIGURATIONS.name()%>"
                          selected="${agentDetails.selectedConfigurationsPolicy}">Run assigned configurations only</forms:option>
          </select>
        </jsp:attribute>
        <jsp:attribute name="ifAccessDenied">
          <strong><c:choose>
            <c:when test="${agentDetails.allConfigurationsPolicy}">Run all compatible configurations</c:when>
            <c:otherwise>Run assigned configurations only</c:otherwise>
          </c:choose></strong>
        </jsp:attribute>
      </authz:authorize>
    </div>

    <div class="messagesHolder">
      <div id="savingData"><i class="icon-refresh icon-spin ring-loader-inline"></i> Saving...</div>
      <div id="dataSaved">Your changes have been saved</div>
      <div id="errors" class="error" style="display: none; margin: auto;"></div>
    </div>
  </div>

  <c:if test="${not empty param['showAll']}">
    <script type="text/javascript">
      BS.AgentRunPolicy.showAll = true;
    </script>
  </c:if>

  <c:set var="showCompatTable" value="${not ufn:booleanPropertyValue(currentUser, 'agentCompatibility.hideTable')}"/>

  <c:set var="doNotShowInactive" value="${empty param['showAll']}"/>
  <c:set var="inactiveConfigurationsCount"
         value="${!showCompatTable ? 0 : agentDetails.totalSelectedConfigurationsCount -
                        agentDetails.activeCompatibilities.numTotalCompatible -
                        agentDetails.activeCompatibilities.numTotalIncompatible}"/>
  <c:set var="displayNote" value="${hasSeveralPools and (inactiveConfigurationsCount > 0 or agentDetails.selectedConfigurationsPolicy)}"/>

  <authz:authorize projectIds="${agentType.agentPool.projectIds}" checkGlobalPermissions="true"
                   anyPermission="CHANGE_AGENT_RUN_CONFIGURATION_POLICY,CHANGE_AGENT_RUN_CONFIGURATION_POLICY_FOR_PROJECT">
  <c:if test="${agentDetails.selectedConfigurationsPolicy}">
  <div class="assignAction">
    <forms:addButton onclick="return BS.AgentSelectConfigurationsDialog.show()" showdiscardchangesmessage="false">Assign configurations</forms:addButton>
    <c:set var="cssClass" value="selected"/>
  </div>
  </c:if>
  </authz:authorize>

  <bs:refreshable containerId="agentCompatibilityTableRefreshable" pageUrl="${url}">

    <form action="#" id="runConfigurationForm">
      <input type="hidden" id="agentTypeId" value="${agentType.agentTypeId}"/>
      <c:set var="showButton" value="${false}"/>
      <div class="compatibilityDetailsToolbar">
          <c:if test="${showCompatTable}">
            <span class="expand-collapse">
                <bs:collapseExpand collapseAction="" expandAction=""/>
            </span>
          </c:if>

          <span class="compatibilityDetailsToolbar__hideOption">
            <profile:booleanPropertyCheckbox propertyKey="agentCompatibility.hideTable"
                                             labelText="Hide compatibility table" afterComplete="BS.reload(true);"/>
          </span>


        <c:if test="${displayNote and showCompatTable}">
          <span id="poolDetails">
            <c:set var="total" value="${agentDetails.totalSelectedConfigurationsCount}"/>
            This agent belongs to <bs:agentPoolLink agentPool="${agentDetails.agentType.agentPool}"/>.
            <span <c:if test="${not doNotShowInactive}">style="display:none"</c:if>>
              You're viewing build configurations only from that pool.
              <a href="#" onclick="return BS.CompatibilityUtils.showFromOtherPools(${showButton ? 1 : 0});">
                <c:if test="${total > 0}">View all ${total} configurations &raquo;</c:if>
                <c:if test="${total == 0}">Display build configurations from other pools &raquo;</c:if>
              </a>
            </span>
            <span <c:if test="${doNotShowInactive}">style="display:none"</c:if>>
              You're viewing <i>all</i> <c:if test="${total > 0}">${total}</c:if> build configurations from <i>all</i> pools.
            </span>
          </span>
        </c:if>
      </div>

      <c:if test="${showCompatTable}">

      <agent:agentCompatibilityTable data="${agentDetails.activeCompatibilities}"
                                       selectedConfigurationsPolicy="${agentDetails.selectedConfigurationsPolicy}"
                                       cssClass="${cssClass}"
                                       active="${true}"/>
        <c:set var="showButton" value="${agentDetails.selectedConfigurationsPolicy &&
                                        (agentDetails.activeCompatibilities.numCompatible > 0 ||
                                         agentDetails.activeCompatibilities.numIncompatible > 0)}"/>
      <c:if test="${displayNote}">
        <div id="poolDetailsBottom" <c:if test="${not doNotShowInactive}">style="display:none"</c:if>>
          <a href="#" onclick="return BS.CompatibilityUtils.showFromOtherPools(${showButton ? 1 : 0});">View build configurations from other pools &raquo;</a>
        </div>
      </c:if>
      <bs:refreshable containerId="inactiveConfigurationsTable" pageUrl="${pageUrl}">
        <div id="inactiveConfigurationsTableParent" style='<c:if test="${doNotShowInactive}">display: none;</c:if>'>
          <c:choose>
            <c:when test="${doNotShowInactive}">
              <forms:progressRing style="float: left"/>
              <span>&nbsp;Loading...</span>
            </c:when>
            <c:otherwise>
              <div id="compatibleDivider">
                Build configurations from other pools.
                <a href="#" onclick="return BS.CompatibilityUtils.hideFromOtherPools()">Hide</a>
              </div>
              <agent:agentCompatibilityTable data="${agentDetails.inactiveCompatibilities}"
                                             selectedConfigurationsPolicy="${agentDetails.selectedConfigurationsPolicy}"
                                             cssClass="${cssClass}"
                                             active="${false}"/>
              <c:set var="showButton"
                     value="${agentDetails.selectedConfigurationsPolicy && (showButton || agentDetails.inactiveCompatibilities.numCompatible > 0 || agentDetails.inactiveCompatibilities.numIncompatible > 0)}"/>
            </c:otherwise>
          </c:choose>
        </div>
      </bs:refreshable>
      </c:if>
    </form>
    <script type="text/javascript">
      BS.CompatibilityUtils.initAgentCompatibility();
    </script>
  </bs:refreshable>

  <forms:modified modifiedText="Changes not yet applied" buttonCaption="Unassign selected"/>
  <script type="text/javascript">
    $j(document).ready(function() {
      BS.AgentRunPolicy.setupEventHandlers();
    });
  </script>
  <jsp:include page="/agent/agentSelectConfigurationsDialog.html?mode=empty&agentTypeId=${agentType.agentTypeId}"/>
</c:if>
