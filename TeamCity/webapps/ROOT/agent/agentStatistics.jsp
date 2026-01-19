<%@ include file="/include-internal.jsp"
  %><jsp:useBean id="agentStatistics" scope="request" type="jetbrains.buildServer.controllers.agent.statistics.AgentStatisticsForm"
  /><jsp:useBean id="serverSummary" scope="request" type="jetbrains.buildServer.web.openapi.ServerSummary"
  /><c:set var="lines" value="${agentStatistics.lines}"
  />
<bs:linkCSS dynamic="${true}">
  /css/agentBlocks.css
</bs:linkCSS>

<div class="agentStatistics">
<c:url value="/agentsStatistics.html" var="controllerUrl"/>
<form action="${controllerUrl}" method="post" id="agentsStatsFilter">
  <input type="hidden" name="tab" value="agentStatistics"/>
  <input type="hidden" name="agentsStatistics" value="1"/>
  <table class="agentStatsFilter">
    <tr>
      <td class="dateFromLabel"><label for="dateFrom">From:</label></td>
      <td class="dateFromInput">
        <forms:textField name="dateFrom" value="${agentStatistics.range.dateFrom}" noAutoComplete="true"/>
        <div class="error" id="error_dateFrom" style="margin-left:0; white-space:nowrap;"></div>
      </td>
      <td class="dateToLabel"><label for="dateTo">To:</label></td>
      <td class="dateToInput">
        <forms:textField name="dateTo" value="${agentStatistics.range.dateTo}" noAutoComplete="true"/>
        <div class="error" id="error_dateTo" style="margin-left:0; white-space:nowrap;"></div>
      </td>
      <td>
        <input class="btn btn_mini" type="submit" name="submitFilter" value="Update"/>
        <span class="resetLink">
          <forms:resetFilter resetHandler="BS.AgentsStatistics.resetFilter();"
                             hidden="${empty agentStatistics.agentNameFilter}"/>
        </span>
      </td>
      <td style="width:50px;vertical-align:middle;"><forms:saving id="agentStatisticsProgress" className="progressRingInline"/></td>
      <td>&nbsp;</td>
      <td style="width: 100px; text-align: right;"><label for="agentName">Agent:</label></td>
      <td style="width: 200px" class="nowrap">
        <c:url var="autocompletionUrl" value="/agentNamesAutocompletion.html"/>
        <forms:autocompletionTextField name="agentName" value="${agentStatistics.agentNameFilter}" style="width:15em;" maxlength="256"
                                       autocompletionSource="BS.AgentsStatistics.createFindAgentNameFunction('${autocompletionUrl}')"
                                       autocompletionShowOnFocus="true"
                                       autocompletionShowEmpty="false"/>
        <span class="resetLink">
          <forms:resetFilter resetHandler="BS.AgentsStatistics.resetFilter();"
                             hidden="${empty agentStatistics.agentNameFilter}"/>
        </span>
      </td>
      <c:if test="${serverSummary.hasSeveralAgentPools}">
        <td style="width: 150px; text-align: right;"><forms:checkbox name="groupByPools" checked="${agentStatistics.groupByPools}" style="vertical-align:middle;"/><label
            for="groupByPools">Group by agent pools</label></td>
      </c:if>
      <c:if test="${agentStatistics.hasCloudAgents}">
        <td style="width: 150px; text-align: right;"><forms:checkbox name="groupCloudAgents" checked="${agentStatistics.groupCloudAgents}" style="vertical-align:middle;"/><label
            for="groupCloudAgents">Group cloud agents</label></td>
      </c:if>
      <td style="width: 100px; text-align: right;"><label for="sortOrder" style="vertical-align:middle;">Sort by:</label></td>
      <td style="width: 50px">
        <select id="sortOrder" name="sortOrder">
          <c:set var="sortOrder">${agentStatistics.range.sortOrder}</c:set>
          <c:forEach items="${agentStatistics.sortOrders}" var="item"><forms:option value="${item.key}" selected="${item.key eq sortOrder}"><c:out
            value="${item.value}"/></forms:option></c:forEach>
        </select>
      </td>
    </tr>
  </table>
</form>


  <script type="text/javascript">
    BS.AgentsStatistics.init_filter();
    BS.AgentsStatistics.decorateDateInputs();
    BS.AgentsStatistics.buildTypeToProject = {<bs:mapOfListToJSON map="${lines.projectToName}" quote="true"/>};
    BS.AgentsStatistics.buildTypeToProject[''] = 'Configuration is unavailable';
  </script>

<div class="stickyBar">
<div class="agent_scale">
  <div class="scale">
    <c:forEach items="${lines.scale.beans}" var="seg" varStatus="pos">
      <c:if test="${not pos.last}">
        <div class="point" style="width: ${100 / (fn:length(lines.scale.beans) - 1)}%">
          <div class="tick">
            <bs:date value="${seg.time}" pattern="dd MMM yyyy" no_span="true"/>
            <div style="margin-top:-10px;">
              <bs:date value="${seg.time}" pattern="HH:mm:ss" no_span="true"/>
            </div>
          </div>
          <div class="line rulerUp"></div>
        </div>
      </c:if>
    </c:forEach>
  </div>
  <div class="last_tick">
    <div class="point">
      <c:set var="seg" value="${lines.scale.beans.last}"/>
      <%--@elvariable id="seg" type="jetbrains.buildServer.controllers.agent.statistics.segments.ScaleSegmentBean"--%>
      <div class="tick">
        <bs:date value="${seg.time}" pattern="dd MMM yyyy" no_span="true"/>
        <div style="margin-top:-10px;">
          <bs:date value="${seg.time}" pattern="HH:mm:ss" no_span="true"/>
        </div>
      </div>
      <div class="line"></div>
    </div>
  </div>
</div>
</div>

<div class="agents_list agents_scrollable custom-scroll" id="agents_scrollable">
  <div>
    <div class="agentLines">
      <c:forEach items="${lines.lines}" var="poolLine">
        <c:set var="pool" value="${poolLine.first}"/>
        <c:if test="${pool != null}">
          <div class="pool_header"><bs:agentPoolLink agentPool="${pool}" groupHeader="${true}"/></div>
        </c:if>
        <c:forEach items="${poolLine.second}" var="line" varStatus="pos">
          <div class="agent_line_wrapper">
          <div class="agent_in_pool">
            <c:forEach items="${line.value.beans}" var="seg">
              <%--@elvariable id="seg" type="jetbrains.buildServer.controllers.agent.statistics.segments.SingleBuildSegmentBean"--%>
              <c:set var="kind" value="${seg.kind}"
              /><c:set var="borderClass"
                ><c:if test="${seg.drawLeftBorder or seg.drawRightBorder}"
                  ><c:if test="${seg.drawLeftBorder}">left</c:if
                  ><c:if test="${seg.drawRightBorder}">right</c:if
                ></c:if
              ></c:set

              ><c:set var="kindAttr"
                ><c:choose
                  ><c:when test="${kind.idle}">idle</c:when
                  ><c:when test="${kind.one}">one</c:when
                  ><c:when test="${kind.group}">group</c:when
                  ></c:choose
                ></c:set

              ><c:if test="${kind.one}"
                ><c:set var="val" value="${seg.agentBuildValue}"
              /></c:if

              ><c:if test="${not empty val}"
                ><c:set var="buildTypeId" value="${val.buildTypeId}"
                /></c:if

              ><c:if test="${not empty val}"
                ><c:set var="buildId" value="${val.inHistory ? val.buildId : 0}"
              /></c:if

              ><c:if test="${kind.group}"
                ><c:set var="buildsCount" value="${seg.buildsCount}"
              /></c:if
              ><c:if test="${(kind.group || kind.one) && !empty seg.runningSince}"
                ><c:set var="runningSince"><bs:date value="${seg.runningSince}" pattern="dd MMM yyyy HH:mm:ss" no_span="true"
                /></c:set></c:if
                ><c:if test="${not empty val and not(kind.one and val.inHistory)}"
                ><c:set var="segStartTime"
                  ><bs:date value="${seg.startTime}" pattern="dd MMM yyyy HH:mm:ss" no_span="true"
                /></c:set
              ><c:set var="segFinishTime"
                ><bs:date value="${seg.finishTime}" pattern="dd MMM yyyy HH:mm:ss" no_span="true"
              /></c:set
                ><c:set var="segDuration" value="${seg.duration}"
              /></c:if

            ><c:if test="${not empty val}"
            ><c:set var="segNumber"><c:out value="${val.buildNumber}"/></c:set
            ><c:set var="segStatusText"><c:out value="${val.statusText}"/></c:set></c:if>
              <%--@elvariable id="val" type="jetbrains.buildServer.serverSide.statistics.buildtime.AgentBuildValue"--%>
              <div class="agent_line_segment ${borderClass}"
                  data-kind="${kindAttr}"
                  data-build-type-id="${buildTypeId}"
                  data-build-id="${buildId}"
                  data-builds-count="${buildsCount}"
                  data-seg-start-time="${segStartTime}"
                  data-seg-finish-time="${segFinishTime}"
                  data-seg-duration="${segDuration}"
                  data-build-number="${segNumber}"
                  data-build-status="${segStatusText}"
                  data-build-running="${val.running || !empty runningSince}"
                  data-build-running-since="${runningSince}"
                  style="width:${seg.length / line.value.size * 100}%;background-color:${seg.cssColor};">
                <c:if test="${seg.drawable}"><span><c:out value="${seg.duration}"/></span></c:if>
              </div>
            </c:forEach>
          </div>
          <div class="agent_link">
            <div>
              <c:set var="agentName" value="${line.key.agentName}"/>
              <c:set var="agent" value="${line.key.agent}"/>
              <c:set var="agentType" value="${line.key.agentType}"/>
              <c:choose>
                <c:when test="${not empty agent or not empty agentType}">
                  <bs:agentDetailsFullLink agentType="${agentType}" agent="${agent}" doNotShowPoolInfo="${agentStatistics.actuallyGroupedByPools}"><c:out value="${agentName}"/></bs:agentDetailsFullLink>
                </c:when>
                <c:otherwise><c:out value="${agentName}"/></c:otherwise>
              </c:choose>
            </div>
            <div>Usage: <c:out value="${line.value.loadFactor}"/></div>
          </div>
          </div>
        </c:forEach>
      </c:forEach>
    </div>
    <c:if test="${fn:length(lines.lines) == 0}">
      <div class="noData" style="width:85%;">No data found</div>
    </c:if>
  </div>
</div>

</div>
<script type="text/javascript">
  BS.AgentsStatistics.init();
  $j(function(){$j(".stickyBar").sticky({topSpacing:0, zIndex: 1})});
</script>