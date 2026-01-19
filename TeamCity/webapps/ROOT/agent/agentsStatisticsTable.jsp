<%@ page import="java.util.Set" %>
<%@ page import="java.util.HashSet" %>
<%@ page import="java.util.Arrays" %>
<%@ page import="jetbrains.buildServer.web.functions.BlockStateUtil" %>
<%@ page import="java.util.Collections" %>
<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="agent" tagdir="/WEB-INF/tags/agent" %>
<jsp:useBean id="form" scope="request" type="jetbrains.buildServer.controllers.agent.statistics.AgentsStatisticsTableForm"/>
<jsp:useBean id="serverSummary" type="jetbrains.buildServer.web.openapi.ServerSummary" scope="request"/>
<c:set var="range" value="${form.date}"/>
<c:url value="/agentsStatisticsTable.html" var="controllerUrl"/>
<bs:linkScript>
  /js/bs/agentStatisticsTable.js
</bs:linkScript>

<div class="agentStatisticsTableForm">
<form action="${controllerUrl}" method="post" onsubmit="return BS.AgentStatisticsTableFilter.submitFilter()" id="agentsStatsFilter">
  <c:set var="groupByProject" value="${form.groupByProject}"/>
  <c:set var="groupByPool" value="${form.groupByAgentPool}"/>
  <c:set var="groupCloudAgents" value="${form.groupCloudAgents}"/>
  <c:set var="hasSeveralPools" value="${serverSummary.hasSeveralAgentPools}"/>

  <table class="agentStatsFilter">
    <tr>
      <td class="dateFromLabel"><label for="dateFrom">From:</label></td>
      <td class="dateFromInput">
        <forms:textField name="dateFrom" value="${range.dateFrom}" noAutoComplete="true"/>
        <div class="error" id="error_dateFrom" style="margin-left:0; white-space: nowrap;"></div>
      </td>
      <td class="dateToLabel"><label for="dateTo">To:</label></td>
      <td class="dateToInput">
        <forms:textField name="dateTo" value="${range.dateTo}" noAutoComplete="true"/>
        <div class="error" id="error_dateTo" style="margin-left:0; white-space: nowrap;"></div>
      </td>
      <td><input class="btn btn_mini" type="submit" name="submitFilter" value="Update"/><forms:saving className="progressRingInline"/></td>
      <td>&nbsp;</td>
      <td style="width: 150px; text-align: right;">
        <forms:checkbox name="groupByProject" id="groupByProject" onclick="BS.AgentStatisticsTableFilter.submitFilter();" checked="${groupByProject}" style="vertical-align:middle;"/>
        <label for="groupByProject">Group by project</label>
      </td>
      <td style="width: 150px; text-align: right;">
        <forms:checkbox name="groupCloudAgents" id="groupCloudAgents" onclick="BS.AgentStatisticsTableFilter.submitFilter();" checked="${groupCloudAgents}" style="vertical-align:middle;"/>
        <label for="groupCloudAgents">Group cloud agents</label>
      </td>
      <c:if test="${hasSeveralPools}">
        <td style="width: 150px; text-align: right;">
          <forms:checkbox name="groupByAgentPool" id="groupByAgentPool" onclick="BS.AgentStatisticsTableFilter.submitFilter();" checked="${groupByPool}" style="vertical-align:middle;"/>
          <label for="groupByAgentPool">Group by agent pool</label>
        </td>
      </c:if>
    </tr>
  </table>
  <input type="hidden" name="tab" value="agentStatisticsTable"/>
</form>

<%
  final Set<String> collapsedProjectIds = form.getGroupByProject()
                                          ? new HashSet<String>(Arrays.asList(BlockStateUtil.getBlockState(request, "agentMatrixProject").split(":")))
                                          : Collections.<String>emptySet();

  final Set<Integer> collapsedPoolIds;
  if (form.getGroupByAgentPool()) {
    collapsedPoolIds = new HashSet<Integer>();
    for (final String poolIdStr : BlockStateUtil.getBlockState(request, "agentMatrixPool").split(":")) {
      try {
        collapsedPoolIds.add(Integer.parseInt(poolIdStr));
      } catch (final NumberFormatException ignore) {}
    }
  }
  else {
    collapsedPoolIds = Collections.emptySet();
  }
%>

<c:set var="table" value="${form.bean}"/>
<c:set var="total" value="${table.total}"/>
<script type="text/javascript">
    BS.AgentsStatistics.decorateDateInputs();
    $j(document).ready(BS.AgentStatisticsTable.initDelegates);
</script>
  <c:if test="${table.hasUnaccessibleBuildTypes}">
    <div class="attentionComment"><bs:buildStatusIcon type="red-sign" className="warningIcon"/>You do not have permissions to see some of the build configurations.</div>
  </c:if>
  <table class="agentStatisticsTable">
    <thead>
      <tr>
        <th <c:if test="${groupByPool}">rowspan="2"</c:if>><strong><c:out value="${table.groupedCols.row}"/></strong></th>
        <th <c:if test="${groupByPool}">rowspan="2"</c:if> colspan="2">
          <strong><c:out value="${table.groupedCols.summary}"/></strong>
          <c:if test="${hasSeveralPools && groupByPool}">
            <div class="collapseExpand">
              <bs:collapseExpand type="text" collapseAction="BS.AgentMatrixAgentBlocks.collapseAll(); return false;" expandAction="BS.AgentMatrixAgentBlocks.expandAll(); return false;"/>
            </div>
          </c:if>
        </th>
        <c:if test="${groupByPool}">
          <c:forEach items="${table.groupedCols.values}" var="head">
            <c:set var="pool" value="${head.first}"/>
            <c:set var="poolId" value="${pool.agentPoolId}"/>
            <c:set var="colspan" value="${fn:length(head.second) + 1}"/>
            <script type="text/javascript">
              BS.AgentMatrixAgentBlocks.poolHeaderColSpanById[${poolId}] = ${colspan};
            </script>
            <c:set var="collapsed" value='<%=collapsedPoolIds.contains(pageContext.getAttribute("poolId"))%>'/>
            <th class="head" id="poolHeader:${poolId}" colspan="<c:choose><c:when test="${collapsed}">1</c:when><c:otherwise>${colspan}</c:otherwise></c:choose>">
              <table class="matrixBlockHandle">
                <tr>
                  <td><img src="<c:choose><c:when test="${collapsed}"><c:url value="/img/tree/plus16.png"/></c:when><c:otherwise><c:url value="/img/tree/minus16.png"/></c:otherwise></c:choose>"
                           class="poolHandle" id="poolHandle:${poolId}" onclick="BS.AgentMatrixAgentBlocks.toggleBlock(${poolId}, true);" data-no-retina="true"/></td>
                  <td><bs:agentPoolLink agentPool="${pool}"/></td>
                </tr>
              </table>
              <div id="statsCol_pool-${poolId}" style="display:none;"><bs:agentPoolLink agentPool="${pool}"/></div>
              <div id="statsTypeCol_pool-${poolId}" style="display:none;">Agent pool</div>
            </th>
          </c:forEach>
          </tr>
          <tr>
        </c:if>
        <c:forEach items="${table.groupedCols.values}" var="head">
          <c:set var="poolId" value=""/>
          <c:if test="${groupByPool}">
            <th class="groupCol">Total</th>
            <c:set var="poolId" value="${head.first.agentPoolId}"/>
          </c:if>
          <c:set var="clazz">poolCell-${poolId}</c:set>
          <c:set var="collapsed" value='<%=collapsedPoolIds.contains(pageContext.getAttribute("poolId"))%>'/>
          <c:forEach items="${head.second}" var="agent">
            <th class="head ${clazz}" <c:if test="${collapsed}">style="display: none;"</c:if>>
              <div id="statsCol_agent-${agent.id}" style="display:none;"><bs:agentDetailsLink agent="${agent.agent}" agentType="${agent.agentType}"/></div>
              <div id="statsTypeCol_agent-${agent.id}" style="display:none;">Agent</div>
              <c:set var="agentName"><bs:trim maxlength="15">${agent.agentName}</bs:trim></c:set>
              <c:choose>
                <c:when test="${not empty agent.agent}"><bs:agentDetailsLink agent="${agent.agent}">${agentName}</bs:agentDetailsLink></c:when>
                <c:when test="${not empty agent.agentType}"><bs:agentDetailsLink agentType="${agent.agentType}"><bs:trim maxlength="15">${agent.agentType.details.name}</bs:trim></bs:agentDetailsLink></c:when>
                <c:otherwise>${agentName}</c:otherwise>
              </c:choose>
            </th>
          </c:forEach>
        </c:forEach>
      </tr>
      <tr>
        <c:set var="row" value="${table.colsSummary}"/>
        <th rowspan="2">
          <strong><c:out value="${row.row}"/></strong>
          <c:if test="${groupByProject}">
            <div class="collapseExpand">
              <bs:collapseExpand type="text" collapseAction="BS.AgentMatrixBuildTypeBlocks.collapseAll(); return false;" expandAction="BS.AgentMatrixBuildTypeBlocks.expandAll(); return false;"/>
            </div>
          </c:if>
        </th>
        <th><strong><bs:printTime time="${row.summary.loadTime / 1000}"/></strong></th>
        <th>&nbsp;</th>
        <c:forEach items="${row.values}" var="head">
          <c:set var="poolId" value=""/>
          <c:if test="${groupByPool}">
            <th class="hsummary groupCol"><bs:printTime time="${head.first.loadTime / 1000}"/></th>
            <c:set var="poolId" value="${head.first.colId}"/>
          </c:if>
          <c:set var="clazz">poolCell-${poolId}</c:set>
          <c:set var="collapsed" value='<%=collapsedPoolIds.contains(pageContext.getAttribute("poolId"))%>'/>
          <c:forEach items="${head.second}" var="agentSummary">
             <th class="hsummary ${clazz}" <c:if test="${collapsed}">style="display: none;"</c:if>>
               <bs:printTime time="${agentSummary.loadTime / 1000}"/>
             </th>
          </c:forEach>
        </c:forEach>
      </tr>
      <tr>
        <c:set var="row" value="${table.colsSummary}"/>
        <th>&nbsp;</th>
        <th><strong><bs:percent value="${row.summary.loadTime}" total="${total}"/></strong></th>
        <c:forEach items="${row.values}" var="head">
          <c:set var="poolId" value=""/>
          <c:if test="${groupByPool}">
            <th class="hsummary groupCol"><bs:percent value="${head.first.loadTime}" total="${total}"/></th>
            <c:set var="poolId" value="${head.first.colId}"/>
          </c:if>
          <c:set var="clazz">poolCell-${poolId}</c:set>
          <c:set var="collapsed" value='<%=collapsedPoolIds.contains(pageContext.getAttribute("poolId"))%>'/>
          <c:forEach items="${head.second}" var="agentSummary">
             <th class="hsummary ${clazz}" <c:if test="${collapsed}">style="display: none;"</c:if>>
               <bs:percent value="${agentSummary.loadTime}" total="${total}"/>
             </th>
          </c:forEach>
        </c:forEach>
      </tr>
    </thead>
    <tbody>
      <c:forEach items="${table.groupedRows}" var="rows">
        <c:if test="${not empty rows.headerRow}">
          <c:set var="row" value="${rows.headerRow}"/>
          <tr class="groupRow">
            <th class="head">
              <table class="matrixBlockHandle">
                <tr>
                  <td>
                    <c:set var="projectId"><c:if test="${not empty row.row.project}">${row.row.project.projectId}</c:if></c:set>
                    <c:if test="${empty projectId and not empty row.row.buildType}"><c:set var="projectId" value="${row.row.buildType.projectId}"/></c:if>
                    <c:set var="collapsed" value='<%=collapsedProjectIds.contains(pageContext.getAttribute("projectId"))%>'/>
                    <img src="<c:choose><c:when test="${collapsed}"><c:url value="/img/tree/plus16.png"/></c:when><c:otherwise><c:url value="/img/tree/minus16.png"/></c:otherwise></c:choose>"
                         class="projectHandle" id="projectHandle:${projectId}" onclick="BS.AgentMatrixBuildTypeBlocks.toggleBlock('${projectId}', true);" data-no-retina="true"/>
                  </td>
                  <td>
                    <c:if test="${not empty row.row.project}"><bs:projectLink project="${row.row.project}"><bs:trim maxlength="30">${row.row.project.extendedName}</bs:trim></bs:projectLink></c:if>
                    <c:if test="${not empty row.row.project and not empty row.row.buildType}">::</c:if>
                    <c:if test="${not empty row.row.buildType}"><bs:buildTypeLink buildType="${row.row.buildType}"><bs:trim maxlength="45">${row.row.buildType.name}</bs:trim></bs:buildTypeLink></c:if>
                  </td>
                  <div id="statsRow_${row.row.id}" style="display:none;">
                    <c:if test="${not empty row.row.project}"><bs:projectLink project="${row.row.project}"/></c:if>
                    <c:if test="${not empty row.row.project and not empty row.row.buildType}">::</c:if>
                    <c:if test="${not empty row.row.buildType}"><bs:buildTypeLink buildType="${row.row.buildType}"/></c:if>
                  </div>
                  <div id="statsTypeRow_${row.row.id}" style="display:none;"><c:choose><c:when test="${empty row.row.buildType}">Project</c:when><c:otherwise>Build configuration</c:otherwise></c:choose></div>
                </tr>
              </table>
            </th>
            <th class="vsummary">
               <bs:printTime time="${row.summary.loadTime / 1000}"/>
            </th>
            <th class="vsummary">
              <bs:percent value="${row.summary.loadTime}" total="${total}"/>
            </th>
            <c:forEach items="${row.values}" var="head">
              <c:set var="poolId" value=""/>
              <c:if test="${groupByPool}">
                <agent:agentMatrixCell value="${head.first}" collapsed="${false}" row="${row}" clazz="groupCol"/>
                <c:set var="poolId" value="${head.first.colId}"/>
              </c:if>
              <c:set var="clazz">poolCell-${poolId}</c:set>
              <c:set var="collapsed" value='<%=collapsedPoolIds.contains(pageContext.getAttribute("poolId"))%>'/>
              <c:forEach items="${head.second}" var="agentSummary">
                <agent:agentMatrixCell value="${agentSummary}" collapsed="${collapsed}" row="${row}" clazz="${clazz}"/>
              </c:forEach>
            </c:forEach>
          </tr>
        </c:if>
        <c:forEach items="${rows.rows}" var="row">
          <c:set var="projectId"><c:if test="${not empty row.row.project}">${row.row.project.projectId}</c:if></c:set>
          <c:if test="${empty projectId and not empty row.row.buildType}"><c:set var="projectId" value="${row.row.buildType.projectId}"/></c:if>
          <c:set var="collapsed" value='<%=collapsedProjectIds.contains(pageContext.getAttribute("projectId"))%>'/>
          <tr class="projectRow-${projectId}" <c:if test="${collapsed}">style="display: none;"</c:if>>
            <th class="head" style="${empty row.row.project ? 'padding-left: 1.5em;' : ''}">
              <c:if test="${not empty row.row.project}"><bs:projectLink project="${row.row.project}"><bs:trim maxlength="30">${row.row.project.extendedName}</bs:trim></bs:projectLink></c:if>
              <c:if test="${not empty row.row.project and not empty row.row.buildType}">::</c:if>
              <c:if test="${not empty row.row.buildType}"><bs:buildTypeLink buildType="${row.row.buildType}"><bs:trim maxlength="45">${row.row.buildType.name}</bs:trim></bs:buildTypeLink></c:if>
              <div id="statsRow_${row.row.id}" style="display:none;">
                <c:if test="${not empty row.row.project}"><bs:projectLink project="${row.row.project}"/></c:if>
                <c:if test="${not empty row.row.project and not empty row.row.buildType}">::</c:if>
                <c:if test="${not empty row.row.buildType}"><bs:buildTypeLink buildType="${row.row.buildType}"/></c:if>
              </div>
              <div id="statsTypeRow_${row.row.id}" style="display:none;"><c:choose><c:when test="${empty row.row.buildType}">Project</c:when><c:otherwise>Build configuration</c:otherwise></c:choose></div>
            </th>
            <th class="vsummary">
               <bs:printTime time="${row.summary.loadTime / 1000}"/>
            </th>
            <th class="vsummary">
               <bs:percent value="${row.summary.loadTime}" total="${total}"/>
            </th>
            <c:forEach items="${row.values}" var="head">
              <c:set var="poolId" value=""/>
              <c:if test="${groupByPool}">
                <agent:agentMatrixCell value="${head.first}" collapsed="${false}" row="${row}" clazz="groupCol"/>
                <c:set var="poolId" value="${head.first.colId}"/>
              </c:if>
              <c:set var="clazz">poolCell-${poolId}</c:set>
              <c:set var="collapsed" value='<%=collapsedPoolIds.contains(pageContext.getAttribute("poolId"))%>'/>
              <c:forEach items="${head.second}" var="value">
                <agent:agentMatrixCell value="${value}" collapsed="${collapsed}" row="${row}" clazz="${clazz}"/>
              </c:forEach>
            </c:forEach>
          </tr>
        </c:forEach>
      </c:forEach>
    </tbody>
  </table>

  <h3>Legend</h3>
  <table class="agentStatisticsLegend">
    <tr>
      <td class="cell"><div class="hasBuilds">&nbsp;</div></td>
      <td>Builds of the build configuration were run on the agent</td>
    </tr>
    <tr>
      <td class="cell"><div class="compatible">&nbsp;</div></td>
      <td>No builds were run on the agent. Build configuration is compatible with the agent</td>
    </tr>
    <tr>
      <td class="cell"><div class="notCompatible">&nbsp;</div></td>
      <td>The agent is not compatible with the build configuration</td>
    </tr>
    <c:if test="${groupByPool || groupByProject}">
      <tr>
        <td class="cell" colspan="2">For group cells:</td>
      </tr>
      <tr>
        <td class="cell"><div class="hasBuilds group">&nbsp;</div></td>
        <td>Builds of the build configuration or project were run on the agent or in the agent pool</td>
      </tr>
      <tr>
        <td class="cell"><div class="compatible group">&nbsp;</div></td>
        <td>No builds were run on the agent or in the agent pool. Build configuration or at least one build configuration of the project is compatible with the agent or with at least one agent in the agent pool</td>
      </tr>
      <tr>
        <td class="cell"><div class="notCompatible group">&nbsp;</div></td>
        <td>The agent or all agents in the agent pool is/are not compatible with the build configuration or all build configurations of the project</td>
      </tr>
    </c:if>
  </table>
</div>

<script type="text/javascript">
  <c:if test="${form.groupByAgentPool}">
    <l:blockState blocksType="agentMatrixPool"/>
    BS.AgentMatrixAgentBlocks.restoreSavedBlocks();
  </c:if>
  <c:if test="${form.groupByProject}">
    <l:blockState blocksType="agentMatrixProject"/>
    BS.AgentMatrixBuildTypeBlocks.restoreSavedBlocks();
  </c:if>
</script>
