<%@ include file="include-internal.jsp" %>
<jsp:useBean id="agentDetails" type="jetbrains.buildServer.controllers.agent.AgentDetailsForm" scope="request"/>
<c:set var="agent" value="${agentDetails.agent}"/>
<c:set var="agentType" value="${agentDetails.agentType}"/>
<c:set var="pattern" value="dd MMM HH:mm"/>
<bs:refreshable containerId="agentStatus:${agent.id}" pageUrl="${pageUrl}">
<c:choose>

  <c:when test="${'1' == param['tableMode']}"> <!-- Agent list: Enable/Disable link  -->

    <c:set var="action" value="" />

    <authz:authorize anyPermission="ENABLE_DISABLE_AGENT,ENABLE_DISABLE_AGENT_FOR_PROJECT"
                     projectIds="${agent.agentPool.projectIds}"
                     checkGlobalPermissions="true">
      <c:set var="poolOptions" value="{poolId: ${agentType.agentPoolId}, cloud: ${agentType.details.cloudAgent ? 1 : 0}}"/>
      <c:set var="action">
        class="actionLink" href="#"
        onclick="BS.Agent.showChangeStatusDialog(${!agent.enabled}, ${agent.id}, ${agent.registered}, 'changeAgentStatus', ${poolOptions}); return false"
      </c:set>
    </authz:authorize>
    <bs:agentStatusInfo trueText="Enabled" falseText="Disabled"
                        trueCssClass="enabled" falseCssClass="disabled"
                        comment="${agent.statusComment}" state="${agent.enabled}" action="${action}"/>

  </c:when>


  <c:when test="${'2' == param['tableMode']}"> <!-- Agent list: Unauthorize link  -->

    <c:set var="action"></c:set>
    <c:if test="${agent.authorized}">
      <authz:authorize anyPermission="AUTHORIZE_AGENT_FOR_PROJECT,AUTHORIZE_AGENT" checkGlobalPermissions="true" projectIds="${agentType.agentPool.projectIds}">
        <c:set var="poolOptions" value="{poolId: ${agentType.agentPoolId}, cloud: ${agentType.details.cloudAgent ? 1 : 0}}"/>
        <c:set var="action">
          class="actionLink" href="#"
          onclick="BS.Agent.showChangeStatusDialog(${false}, ${agent.id}, ${agent.authorized}, 'changeAuthorizeStatus', ${poolOptions}); return false"
        </c:set>
      </authz:authorize>
    </c:if>
    <c:if test="${not agent.authorized and agentDetails.canBeAuthorized}">
      <authz:authorize allPermissions="AUTHORIZE_AGENT">
        <c:if test="${agent.authorized or (not agent.authorized and agentDetails.canBeAuthorized)}">
          <c:set var="poolOptions" value="{poolId: ${agentType.agentPoolId}, cloud: ${agentType.details.cloudAgent ? 1 : 0}}"/>
          <c:set var="action">
            class="actionLink" href="#"
            onclick="BS.Agent.showChangeStatusDialog(${not agent.authorized}, ${agent.id}, ${agent.authorized}, 'changeAuthorizeStatus', ${poolOptions}); return false"
          </c:set>
        </c:if>
      </authz:authorize>
      <c:forEach items="${agentDetails.availablePools}" var="pool">
        <c:if test="${empty poolOptions}">
          <authz:authorize anyPermission="AUTHORIZE_AGENT_FOR_PROJECT" projectIds="${pool.projectIds}">
            <c:if test="${agent.authorized or (not agent.authorized and agentDetails.canBeAuthorized)}">
              <c:set var="poolOptions" value="{poolId: ${agentType.agentPoolId}, cloud: ${agentType.details.cloudAgent ? 1 : 0}}"/>
              <c:set var="action">
                class="actionLink" href="#"
                onclick="BS.Agent.showChangeStatusDialog(${not agent.authorized}, ${agent.id}, ${agent.authorized}, 'changeAuthorizeStatus', ${poolOptions}); return false"
              </c:set>
            </c:if>
          </authz:authorize>
        </c:if>
      </c:forEach>
    </c:if>
    <bs:agentStatusInfo trueText="Authorized" falseText="Unauthorized"
                        trueCssClass="authorized" falseCssClass="unauthorized"
                        comment="${agent.authorizeComment}" state="${agent.authorized}" action="${action}"/>
  </c:when>


  <c:otherwise> <!-- This block is used when shown on the agent page itself -->
    <div>
    <bs:agentStatusInfo2 trueText="Authorized" falseText="Unauthorized"
                         trueCssClass="authorized" falseCssClass="red-text"
                         comment="${agent.authorizeComment}" state="${agent.authorized}"/>
    <c:if test="${agentDetails.manageable and (agent.authorized or (not agent.authorized and agentDetails.canBeAuthorized))}">
      &nbsp;&nbsp;&nbsp;
      <c:if test="${agent.authorized}">
        <authz:authorize anyPermission="AUTHORIZE_AGENT_FOR_PROJECT,AUTHORIZE_AGENT" checkGlobalPermissions="true" projectIds="${agentType.agentPool.projectIds}">
          <c:set var="poolOptions" value="{cloud: ${agentType.details.cloudAgent ? 1 : 0}}"/>
          <button class="btn btn_mini actionLink"
                  onclick="BS.Agent.showChangeStatusDialog(${not agent.authorized}, ${agent.id}, ${agent.authorized}, 'changeAuthorizeStatus', ${poolOptions}); return false">${(agent.authorized) ? "Unauthorize" : "Authorize"}</button>
        </authz:authorize>
      </c:if>
      <c:if test="${not agent.authorized and agentDetails.canBeAuthorized}">
        <authz:authorize allPermissions="AUTHORIZE_AGENT">
          <c:set var="poolOptions" value="{cloud: ${agentType.details.cloudAgent ? 1 : 0}}"/>
          <button class="btn btn_mini actionLink"
                  onclick="BS.Agent.showChangeStatusDialog(${not agent.authorized}, ${agent.id}, ${agent.authorized}, 'changeAuthorizeStatus', ${poolOptions}); return false">${(agent.authorized) ? "Unauthorize" : "Authorize"}</button>
        </authz:authorize>
        <c:forEach items="${agentDetails.availablePools}" var="pool">
          <c:if test="${empty poolOptions}">
            <authz:authorize allPermissions="AUTHORIZE_AGENT_FOR_PROJECT" projectIds="${pool.projectIds}">
              <c:set var="poolOptions" value="{cloud: ${agentType.details.cloudAgent ? 1 : 0}}"/>
              <button class="btn btn_mini actionLink"
                      onclick="BS.Agent.showChangeStatusDialog(${not agent.authorized}, ${agent.id}, ${agent.authorized}, 'changeAuthorizeStatus', ${poolOptions}); return false">${(agent.authorized) ? "Unauthorize" : "Authorize"}</button>
            </authz:authorize>
          </c:if>
        </c:forEach>
      </c:if>


    </c:if>
    </div>
    <div>

      <c:set var="maintenanceSuffix"><c:if test="${agent.agentType.isCloud()}">&nbsp;for maintenance</c:if></c:set>
      <c:set var="disabledText" value="Disabled${maintenanceSuffix}"/>
      <c:set var="actionText"><c:if test="${agent.enabled}">Disable${maintenanceSuffix}</c:if
      ><c:if test="${not agent.enabled}">Enable</c:if></c:set>
    <bs:agentStatusInfo2 trueText="Enabled" falseText="${disabledText}"
                         trueCssClass="enabled" falseCssClass="red-text"
                         comment="${agent.statusComment}" state="${agent.enabled}"/>
     &nbsp;&nbsp;&nbsp;
      <c:if test="${agentDetails.manageable}">
        <authz:authorize anyPermission="ENABLE_DISABLE_AGENT,ENABLE_DISABLE_AGENT_FOR_PROJECT"
                         projectIds="${agent.agentPool.projectIds}"
                         checkGlobalPermissions="true">
          <c:set var="poolOptions" value="{poolId: ${agentType.agentPoolId}, cloud: ${agentType.details.cloudAgent ? 1 : 0}}"/>
          <button class="btn btn_mini actionLink"
                  onclick="BS.Agent.showChangeStatusDialog(${not agent.enabled}, ${agent.id}, ${agent.registered}, 'changeAgentStatus', ${poolOptions}); return false">${actionText}</button>
        </authz:authorize>
      </c:if>

      &nbsp;&nbsp;&nbsp;
      <c:if test="${agent.agentStatusToRestore != null}">
          (Will be automatically <c:choose><c:when test="${agent.agentStatusToRestore}">enabled</c:when><c:otherwise>disabled</c:otherwise></c:choose> at <strong><bs:date value="${agent.agentStatusRestoringTimestamp}"/></strong>)
      </c:if>

    </div>
  </c:otherwise>
</c:choose>
</bs:refreshable>