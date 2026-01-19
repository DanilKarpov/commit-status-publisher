<%@ include file="/include-internal.jsp"
%><%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"
%><%@ taglib prefix="bs" tagdir="/WEB-INF/tags"
%><%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"
%><%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"
%><%@ taglib prefix="util" uri="/WEB-INF/functions/util"
%><%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin"
%><%@ taglib prefix="tags" tagdir="/WEB-INF/tags/tags"
%><%@taglib prefix="auth" tagdir="/WEB-INF/tags/authz" %>
<%--@elvariable id="error" type="java.lang.String"--%>
<c:choose>
  <c:when test="${not empty error}">
    Error: <c:out value="${error}"/>
  </c:when>
  <c:otherwise>
    <jsp:useBean id="now" class="java.util.Date"/>
    <%--@elvariable id="pageUrl" type="java.lang.String"--%>
    <%--@elvariable id="project" type="jetbrains.buildServer.serverSide.SProject"--%>
    <%--@elvariable id="maxBuilds" type="long"--%>
    <%--@elvariable id="averageArtBuildSize" type="long"--%>
    <%--@elvariable id="averageInternalArtBuildSize" type="long"--%>
    <%--@elvariable id="averageLogBuildSize" type="long"--%>
    <%--@elvariable id="topBuildsSize" type="java.util.List<jetbrains.buildServer.controllers.admin.diskUsage.DiskUsageBuildDataController.TopSizedBuildBean>"--%>
    <%--@elvariable id="buildsWithArtifactsNumber" type="long"--%>
    <%--@elvariable id="row" type="jetbrains.buildServer.serverSide.statistics.diskusage.DiskUsageRow"--%>
    <%--@elvariable id="pinnedBuilds" type="java.lang.Long"--%>
    <%--@elvariable id="canRescanDiskUsage" type="java.lang.Boolean"--%>
    <%--@elvariable id="pinnedSize" type="java.lang.Long"--%>

    <div class="buildSizePopup">
      <h3>Configuration <bs:buildTypeLinkFull buildType="${row.buildType}"/> total details<c:if test="${canRescanDiskUsage}"><a title="click to reload data" onclick="return BS.DiskUsage.BuildsStatsPopup.reload('${row.buildType.externalId}');" href="#" class="icon-refresh update_configuration"></a></c:if></h3>
      <div>Builds on disk: ${totalBuilds}, with artifacts: ${buildsWithArtifactsNumber}</div>
      <div>Average artifacts: <bs:fileSize value="${averageArtBuildSize}"/><c:if test="${averageInternalArtBuildSize != 0}"> (+<bs:fileSize value="${averageInternalArtBuildSize}"/> internal artifacts)</c:if>, logs: <bs:fileSize value="${averageLogBuildSize}"/></div>
      <c:if test="${pinnedBuilds != 0}">
        <div>Pinned: ${pinnedBuilds} builds, <bs:fileSize value="${pinnedSize}"/> occupied on disk</div>
      </c:if>
      <c:if test="${not empty topBuildsSize}">
        <div>Top ${fn:length(topBuildsSize)} build<bs:s val="${fn:length(topBuildsSize)}"/> with above-average disk usage (all artifacts with build log)</div>
        <ul>
          <c:forEach items="${topBuildsSize}" var="buildData" varStatus="status">
          <c:set var="build" value="${buildData.build}"/>
            <li>
              <bs:buildLink build="${build}">build #${build.buildNumber}</bs:buildLink>:
              <span class="buildSize"><strong><bs:fileSize value="${buildData.totalSize}"/></strong> (+${buildData.aboveAveragePercent})</span>
              <c:if test="${build.pinned}"><bs:pinImg build="${build}"/></c:if>
              <c:if test="${not empty build.tags}">
                <tags:showTags buildTypeId="${row.buildType.externalId}" tags="${build.tags}"/>
              </c:if>
            </li>
          </c:forEach>
        </ul>
      </c:if>

    <auth:authorize allPermissions="EDIT_PROJECT,CHANGE_CLEANUP_RULES" projectId="${row.buildType.projectId}">
      <div class="cleanupLink">
        <c:url var="projectCleanupUrl" value="/admin/editProject.html?tab=cleanup&projectId=${row.project.externalId}"/>
        <a href="${projectCleanupUrl}">Go to project clean-up rules page &raquo;</a>
      </div>
    </auth:authorize>
    </div>
  </c:otherwise>
</c:choose>