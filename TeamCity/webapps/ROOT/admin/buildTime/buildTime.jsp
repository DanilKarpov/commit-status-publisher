<%--@elvariable id="pageUrl" type="java.util.String"--%>
<%--@elvariable id="projectRow" type="java.util.List<jetbrains.buildServer.controllers.admin.diskUsage.DiskUsageController.ProjectRowBean>"--%>
<%--@elvariable id="archivedRow" type="jetbrains.buildServer.serverSide.statistics.diskusage.DiskUsageProjectRow"--%>
<%--@elvariable id="serverTotal" type="long"--%>
<%--@elvariable id="currentRootTotal" type="long"--%>
<%--@elvariable id="pool" type="jetbrains.buildServer.serverSide.agentPools.AgentPool"--%>
<%--@elvariable id="agentPools" type="java.util.List<jetbrains.buildServer.serverSide.agentPools.AgentPool>"--%>
<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="l" tagdir="/WEB-INF/tags/layout" %>
<%@ taglib prefix="forms" tagdir="/WEB-INF/tags/forms" %>
<%@ taglib prefix="util" uri="/WEB-INF/functions/util" %>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<%@ taglib prefix="stat" tagdir="/WEB-INF/tags/statistics" %>
<jsp:useBean id="buildTimeForm" scope="request" class="jetbrains.buildServer.controllers.admin.buildTime.BuildTimeReportForm"/>
<bs:linkCSS>
  /css/FontAwesome/css/font-awesome.min.css
  /css/main.css
  /css/icons.css
  /css/forms.css
  /css/project.css
  /css/tags.css
  /css/admin/adminMain.css
  /css/admin/diskUsage.css
</bs:linkCSS>
<style type="text/css">

</style>
<style type="text/css">
  <c:set var="c" value="255"/>
  <c:forEach var="i" begin="0" end="10" step="1">
  tr.project.tr-depth-${i} > td, tr.build_type.tr-depth-${i+1} > td{
    background-color: rgb(${c},${c},${c});
  }
  <c:set var="c" value="${c-8}"/>
  </c:forEach>
</style>
<bs:linkScript>
  /js/bs/blocks.js
  /js/bs/blockWithHandle.js
  /js/bs/collapseExpand.js
  /js/bs/buildtime.js
  /js/bs/cleanupPolicies.js
</bs:linkScript>
<div>
  <bs:refreshable containerId="diskUsageContainer" pageUrl="${pageUrl}">
    <c:if test="${not blankPage && serverTotal!=currentRootTotal}">
      <div class="diskUsageOverview">
        <div>Server build time: <stat:buildTime time="${serverTotal}"/></div>
      </div>
    </c:if>

    <div class="diskUsageToolbar">

      <div class="ajax_update_progress"></div>

      <c:if test="${buildTimeForm.grouped}">
          <span class="collapseExpandBlock">
          <bs:collapseExpand collapseAction="BS.CollapsableBlocks.collapseAll(true, 'projectHierarchy'); return false"
                             expandAction="BS.CollapsableBlocks.expandAll(true, 'projectHierarchy'); return false"/>
          </span>
      </c:if>
        <span>
          <forms:radioButton id="dateRange24" name="dateRangeType" checked="${buildTimeForm.dateRangeType=='LAST24H'}" value="LAST24H"/>
          <label for="dateRange24">last 24h</label>&nbsp;&nbsp;
          <forms:radioButton id="dateRangeWeek" name="dateRangeType" checked="${buildTimeForm.dateRangeType=='LASTWEEK'}" value="LASTWEEK"/>
          <label for="dateRangeWeek">last week</label>&nbsp;&nbsp;
          <forms:radioButton id="dateRangeMonth" name="dateRangeType" checked="${buildTimeForm.dateRangeType=='LASTMONTH'}" value="LASTMONTH"/>
          <label for="dateRangeMonth">last month</label>
        </span>
        <span class="checkboxHide" style="padding-left: 20px;">
          <forms:checkbox id="groupedCB" name="groupedCB" checked="${buildTimeForm.grouped}"/>
          <label for="groupedCB">Group by project</label>
        </span>
        <span class="checkboxHide" style="padding-left: 20px;">
           <label for="agentPoolId">Agent pool:</label>
          <forms:select id="agentPoolId" name="agentPoolId" enableFilter="true">
            <forms:option value="${buildTimeForm.anyAgentPoolId}" selected="${empty buildTimeForm.agentPoolId}">&lt;All&gt;</forms:option>
            <c:forEach var="pool" items="${agentPools}">
              <forms:option value="${pool.agentPoolId}" selected="${buildTimeForm.agentPoolId == pool.agentPoolId}"><c:out
                  value="${pool.name}"/></forms:option>
            </c:forEach>
          </forms:select>
        </span>
        <span class="checkboxHide" style="padding-left: 10px;">
          <forms:checkbox name="showArchived" id="showArchived" checked="${not buildTimeForm.hideArchived}"/>
          <label for="showArchived">Show archived projects&nbsp;</label>
        </span>

      <div class="diskUsageFiltersResult">
        <c:if test="${not empty archivedRow}">
          <div>
              ${fn:length(archivedRow.rows)} archived configuration<bs:s val="${fn:length(archivedRow.rows)}"/> hidden
          </div>
        </c:if>
      </div>
    </div>


    <c:set var="showTable" value="${not empty projectRow and (not empty projectRow[0].buildTypes or not empty projectRow[0].subProjects) or blankPage}"/>
    <script type="text/javascript">
      jQuery(function () {
        var groupBy = "${buildTimeForm.grouped ? buildTimeForm.groupBy : null}";
        var blank = ${blankPage ? true : false};
        BS.BuildTime.init('${buildTimeForm.dateRangeType}', '${buildTimeForm.sortBy}', ${buildTimeForm.sortAsc}, groupBy, ${buildTimeForm.groupAsc},
            ${buildTimeForm.updating}, ${not buildTimeForm.hideArchived}, false, blank);

        <c:if test="${showTable}">
        <c:forEach var="sortOptionName" items="${buildTimeForm.sortOptionNames}">
        BS.BuildTime.initSortableHolder('${sortOptionName}');
        </c:forEach>

        <c:if test="${buildTimeForm.grouped}">
        <c:forEach var="groupOptionName" items="${buildTimeForm.groupOptionNames}">
        BS.BuildTime.initGroupableHolder('${groupOptionName}');
        </c:forEach>
        </c:if>
        </c:if>
      });
    </script>

    <c:if test="${showTable}">
      <%@include file="buildTimeTable.jsp" %>
    </c:if>
    <c:if test="${not showTable}">
      <div class="descr">
        There are no visible projects.
      </div>
    </c:if>


  </bs:refreshable>
</div>
