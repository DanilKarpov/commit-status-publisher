<%@ include file="/include-internal.jsp" %>
<%--@elvariable id="buildTimeForm" type="jetbrains.buildServer.controllers.admin.buildTime.BuildTimeReportForm"--%>
<%--@elvariable id="projectRow" type="java.util.List<jetbrains.buildServer.web.util.ProjectHierarchyTreeBean>"--%>
<%--@elvariable id="archivedRow" type="jetbrains.buildServer.serverSide.statistics.buildtime.BuildTimeProjectRow"--%>
<%--@elvariable id="buildTypes" type="java.util.Map<jetbrains.buildServer.serverSide.SBuildType, jetbrains.buildServer.serverSide.statistics.diskusage.DiskUsageRow>"--%>
<%--elvariable id="prows" type="java.util.Map<jetbrains.buildServer.serverSide.SProject, jetbrains.buildServer.serverSide.statistics.buildtime.BuildTimeProjectRow>"--%>
<%--@elvariable id="hasProjectLimits" type="boolean"--%>
<%--@elvariable id="rootLimit" type="jetbrains.buildServer.serverSide.statistics.buildtime.LimitInfo"--%>
<bs:trimWhitespace>
  <c:set var="tableClass"><c:if test="${buildTimeForm.grouped}">grouped</c:if> diskUsageTable sortable dark borderBottom</c:set>
  <c:if test="${buildTimeForm.grouped}">
    <bs:projectHierarchy rootProjects="${projectRow}" linksToAdminPage="true" subprojectsPreceed="true" collapsible="true"
                         tablePostHeaderClass="total" tableFooterClass="archivedProject" showRootProjects="false" treeId="diskUsage"
                         tableClass="${tableClass}" tableBuildTypeClass="buildTypeData" customEmptyProjectMessage="No visible configurations"
        >
      <jsp:attribute name="projectHTML">
        <%--@elvariable id="projectBean" type="jetbrains.buildServer.controllers.admin.buildTime.BuildTimeReportController.ProjectRowBean"--%>
        <c:set var="pr" value="${projectBean.projectRow}"/>
        <%--@elvariable id="pr" type="jetbrains.buildServer.serverSide.statistics.buildtime.BuildTimeProjectRow"--%>
        <%--@elvariable id="serverTotal" type="long"--%>
        <td class="size subtotal"><stat:buildTime time="${pr.statisticResult.time}"/></td>
        <td class="percent subtotal"><c:choose>
          <c:when test="${!empty pr.parent}">
            ${util:formatPercent(pr.statisticResult.time, pr.parent.statisticResult.time)}
          </c:when>
          <c:otherwise>100%</c:otherwise>
        </c:choose>
        </td>
        <c:if test="${!empty hasProjectLimits}">
          <td class="sortable groupable size">
             <c:if test="${!empty pr.statisticResult.limit && pr.statisticResult.limit.limit>=0}">
               <bs:printTime time="${pr.statisticResult.limit.limit}"/>
             </c:if>
          </td>
        </c:if>
      </jsp:attribute>
      <jsp:attribute name="buildTypeHTML">
        <c:set var="pr" value="${projectBean.projectRow}"/>
        <c:set var="bt" value="${pr.rowsMap[buildType]}"/>
        <%--@elvariable id="bt" type="jetbrains.buildServer.serverSide.statistics.buildtime.BuildTimeRow"--%>
        <td class="size">
          <stat:buildTime time="${bt.statisticResult.time}"/>
        </td>
        <td class="percent">${util:formatPercent(bt.statisticResult.time, pr.statisticResult.time)}</td>
        <c:if test="${!empty hasProjectLimits}">
          <td class="size">&nbsp;</td>
        </c:if>
      </jsp:attribute>
      <jsp:attribute name="tableHeader">
        <th class="sortable projectName groupable"><span id="CONFIGURATION">Project/Configuration Name</span></th>
        <th class="sortable groupable size"><span class="descDefault" id="DURATION">Duration</span></th>
        <th class="percent"><span class="descDefault" id="a">%</span></th>
        <c:if test="${!empty hasProjectLimits}">
          <th class="sortable groupable size">Limits</th>
        </c:if>
      </jsp:attribute>
      <jsp:attribute name="postHeader">
        <td>Total:</td>
        <%--@elvariable id="currentRootTotal" type="java.math.BigDecimal"--%>
        <td class="size subtotal"><stat:buildTime time="${currentRootTotal}"/></td>
        <td class="percent subtotal">${util:formatPercent(currentRootTotal, serverTotal)}
        <c:if test="${!empty hasProjectLimits}">
          <c:if test="${!empty rootLimit && rootLimit.limit>=0}">
            <td class="size"><bs:printTime time="${rootLimit.limit}"/></td>
          </c:if>
        </c:if>
      </jsp:attribute>
    </bs:projectHierarchy>
  </c:if>
  <c:if test="${not buildTimeForm.grouped}">
    <bs:projectHierarchy rootProjects="${projectRow}" linksToAdminPage="false" tablePostHeaderClass="total" tableFooterClass="archivedProject" treeId="diskUsage"
                         showRootProjects="false" tableClass="${tableClass}" tableBuildTypeClass="buildTypeData" _defaultBTNameColumn="false">
      <jsp:attribute name="projectHTML"></jsp:attribute>
      <jsp:attribute name="buildTypeHTML">
        <%--@elvariable id="projectBean" type="jetbrains.buildServer.controllers.admin.diskUsage.DiskUsageController.ProjectRowBean"--%>
        <c:set var="pr" value="${projectBean.projectRow}"/>
        <c:set var="bt" value="${pr.rowsMap[buildType]}"/>
        <%--@elvariable id="bt" type="jetbrains.buildServer.serverSide.statistics.buildtime.BuildTimeRow"--%>
        <td ${not bt.calculated ? "class='nodata'" : ""}>
          <admin:editBuildTypeLink buildTypeId="${bt.buildType.externalId}"><c:out value="${bt.buildTypeName}"/></admin:editBuildTypeLink>
        </td>
        <td class="groupedValue size"><stat:buildTime time="${bt.statisticResult.time}"/></td>
        <td class="groupedValue percent">
              ${util:formatPercent(bt.statisticResult.time,pr.statisticResult.time)}
        </td>
        <c:if test="${!empty hasProjectLimits}">
            <td class="size">&nbsp;</td>
        </c:if>
      </jsp:attribute>
      <jsp:attribute name="tableHeader">
        <th class="sortable projectName"><span id="PROJECT">Project Name</span></th>
        <th class="sortable configurationName"><span id="CONFIGURATION">Configuration Name</span></th>
        <th class="sortable size"><span class="descDefault" id="DURATION">Duration</span></th>
        <th class="percent"><span class="descDefault" id="a">%</span></th>
        <c:if test="${!empty hasProjectLimits}">
            <th class="size">Limits</th>
        </c:if>
      </jsp:attribute>
      <jsp:attribute name="postHeader">
        <td colspan="2">Total:</td>
        <%--@elvariable id="currentRootTotal" type="java.math.BigDecimal"--%>
        <td class="groupedValue size"><stat:buildTime time="${currentRootTotal}"/></td>
        <td class="percent">${util:formatPercent(currentRootTotal,currentRootTotal)}</td>
        <c:if test="${!empty hasProjectLimits}">
            <td class="size"><c:if test="${!empty rootLimit && rootLimit.limit>=0}"><bs:printTime time="${rootLimit.limit}"/></c:if></td>
        </c:if>
      </jsp:attribute>
      <jsp:attribute name="buildTypeNameHTML">
        <c:set var="pr" value="${projectBean.projectRow}"/>
        <c:set var="bt" value="${pr.rowsMap[buildType]}"/>
        <admin:editProjectLink projectId="${bt.project.externalId}">${bt.project.fullName}</admin:editProjectLink>
        <c:if test="${bt.project.archived}"> <span class="archivedProject">archived</span></c:if>
      </jsp:attribute>
    </bs:projectHierarchy>
  </c:if>
</bs:trimWhitespace>