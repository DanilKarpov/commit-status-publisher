<%--@elvariable id="pageUrl" type="java.util.String"--%>
<%--@elvariable id="lastFullScan" type="java.util.String"--%>
<%--@elvariable id="updateProgress" type="jetbrains.buildServer.serverSide.statistics.diskusage.DiskUsageTaskExecutor.UpdateAllProgress"--%>
<%--@elvariable id="freeArtifactsSize" type="long"--%>
<%--@elvariable id="fullscanPerformed" type="boolean"--%>
<%--@elvariable id="blankPage" type="java.lang.Boolean"--%>
<%--@elvariable id="allVisible" type="java.lang.Boolean"--%>
<%--@elvariable id="canRescanDiskUsage" type="java.lang.Boolean"--%>
<%--@elvariable id="pinnedBuilds" type="java.lang.Long"--%>
<%--@elvariable id="lastFullScanDuration" type="java.lang.Long"--%>
<%--@elvariable id="pinnedArtifacts" type="java.lang.Long"--%>
<%--@elvariable id="pinnedLogs" type="java.lang.Long"--%>
<%--@elvariable id="projectRow" type="java.util.List<jetbrains.buildServer.controllers.admin.diskUsage.DiskUsageController.ProjectRowBean>"--%>
<%--@elvariable id="archivedRow" type="jetbrains.buildServer.serverSide.statistics.diskusage.DiskUsageProjectRow"--%>
<%--@elvariable id="archivedRowCount" type="java.lang.Long"--%>
<%@ include file="/include-internal.jsp"
%><%@ taglib prefix="props" tagdir="/WEB-INF/tags/props"
%><%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"
%><%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"
%><%@ taglib prefix="l" tagdir="/WEB-INF/tags/layout"
%><%@ taglib prefix="forms" tagdir="/WEB-INF/tags/forms"
%><%@ taglib prefix="bs" tagdir="/WEB-INF/tags"
%><%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin"
%><jsp:useBean id="diskUsageForm" scope="request" class="jetbrains.buildServer.controllers.admin.diskUsage.DiskUsageReportForm"/>
<c:set var="showRescan" value="${canRescanDiskUsage and allVisible}"/>
<bs:linkCSS>
  /css/FontAwesome/css/font-awesome.min.css
  /css/main.css
  /css/icons.css
  /css/forms.css
  /css/project.css
  /css/admin/adminMain.css
  /css/admin/diskUsage.css
</bs:linkCSS>

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
  /js/bs/diskusage.js
  /js/bs/cleanupPolicies.js
</bs:linkScript>
<div>
  <bs:refreshable containerId="diskUsageContainer" pageUrl="${pageUrl}">
    <c:if test="${not blankPage}">
      <div class="diskUsageOverview">
        <div>Total available disk space: <strong><c:out value="${freeArtifactsSize}"/></strong></div>
      </div>
    </c:if>

    <div class="diskUsageToolbar">
      <div class="ajax_update_progress"></div>
      <bs:refreshable containerId="updatingProgress" pageUrl="${pageUrl}">
        <c:if test="${diskUsageForm.updating}">
          <span
              class="refreshProgress">Full rescan is in progress: ${updateProgress.processedProjects > -1 ? updateProgress.processedProjects : '0'}
            of ${updateProgress.totalProjects  > -1 ? updateProgress.totalProjects : "?"} projects done
          </span>
          <script type="text/javascript">
            BS.DiskUsage.wait_for_rescan_finish(10000, $j("#updatingProgress"));
          </script>
        </c:if>
        <c:if test="${updateFinished}">
          <script type="text/javascript">
            BS.DiskUsage.refresh_now();
          </script>
        </c:if>
      </bs:refreshable>
      <p class="grayNote">
        <c:if test="${fullscanPerformed}">${lastFullScan}<br/></c:if>
        <c:if test="${not fullscanPerformed}">
          The sizes are calculated incrementally and can be inaccurate.<c:if test="${showRescan}"> Click "Rescan Now" at the bottom of the page to trigger a full disk scan.</c:if><br/>
        </c:if>
      </p>

      <c:if test="${diskUsageForm.grouped}">
          <span class="collapseExpandBlock">
          <bs:collapseExpand collapseAction="BS.CollapsableBlocks.collapseAll(true, 'projectHierarchy'); return false"
                             expandAction="BS.CollapsableBlocks.expandAll(true, 'projectHierarchy'); return false"/>
          </span>
      </c:if>

        <span class="checkboxHide">
          <forms:checkbox id="groupedCB" name="groupedCB" checked="${diskUsageForm.grouped}"/>
          <label for="groupedCB">Group by project</label>
        </span>

        <span class="checkboxHide">
          <forms:checkbox name="showArchived" id="showArchived" checked="${not diskUsageForm.hideArchived}"/>
          <label for="showArchived">Show archived projects</label>
        </span>

        <c:if test="${shouldDisplayStoragesList}">
          <label for="artifactStorageId">Artifact storage:</label>
          <forms:select id="artifactStorageId" name="artifactStorageId" enableFilter="true">
            <forms:option value="${totalStorageSelector}" selected="${totalStorageSelector == diskUsageForm.storageId}">
              <c:out value="${totalStorageSelector}"/>
            </forms:option>
            <c:forEach var="storagesGroup" items="${artifactStorages}">
              <optgroup label="${storagesGroup.key}">
                <c:forEach var="storage" items="${storagesGroup.value}">
                  <forms:option value="${storage.id}" selected="${storage.id == diskUsageForm.storageId}">
                    <c:out value="${storage.name}"/>
                  </forms:option>
                </c:forEach>
              </optgroup>
            </c:forEach>
          </forms:select>
        </c:if>
    </div>

    <div class="diskUsageFiltersResult">
      <c:if test="${not empty archivedRow}">
        <div>
          <c:set var="storageId" value="${diskUsageForm.storageId}"/>
          ${archivedRowCount} archived configuration<bs:s val="${archivedRowCount}"/> hidden<c:if test="${archivedRow.statisticResult.containsData and archivedRow.statisticResult.getTotal(storageId) > 0}"> (${archivedRow.statisticResult.getTotalFormatted(storageId)})</c:if>
        </div>
      </c:if>
    </div>


    <c:set var="showTable" value="${not empty projectRow and (not empty projectRow[0].buildTypes or not empty projectRow[0].subProjects) or blankPage}"/>
    <script type="text/javascript">
      jQuery(function () {
        const sortBy = "<c:out value="${diskUsageForm.sortBy}" />";
        const sortAsc = <c:out value="${diskUsageForm.sortAsc}" />;
        const groupBy = "<c:out value="${diskUsageForm.grouped ? diskUsageForm.groupBy : null}" />";
        const groupAsc = <c:out value="${diskUsageForm.groupAsc}" />;
        const updating = <c:out value="${diskUsageForm.updating}" />;
        const blank = ${blankPage ? true : false};
        const storageId = "${util:forJS(diskUsageForm.storageId, true, false)}";

        BS.DiskUsage.init(sortBy, sortAsc, groupBy, groupAsc, updating, ${not diskUsageForm.hideArchived}, false, blank, storageId);

        <c:if test="${showTable}">
        <c:forEach var="sortOptionName" items="${diskUsageForm.sortOptionNames}">
          BS.DiskUsage.initSortableHolder('${sortOptionName}');
        </c:forEach>

        <c:if test="${diskUsageForm.grouped}">
        <c:forEach var="groupOptionName" items="${diskUsageForm.groupOptionNames}">
          BS.DiskUsage.initGroupableHolder('${groupOptionName}');
        </c:forEach>
        </c:if>
        </c:if>
      });
    </script>

    <c:if test="${showTable}">
      <%@include file="diskUsageTable.jsp" %>
    </c:if>
    <c:if test="${not showTable}">
      <div class="descr">
        There are no visible projects.
      </div>
    </c:if>

    <div class="diskUsageFooterToolbar">
      <c:if test="${showRescan}">
        <input type="button" class="btn btn_mini refreshBtn" value="Rescan now" ${diskUsageForm.updating ? 'disabled' : ''}
               id="rescanButton" onclick='BS.DiskUsage.submitStartFullScan(<c:if test="${fullscanPerformed}">"<bs:printTime time="${lastFullScanDuration}"/>"</c:if>);'/>
      </c:if>
    </div>
  </bs:refreshable>
</div>
