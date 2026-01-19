<%@ page import="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" %>
<%--@elvariable id="buildDatas" type="java.util.List<jetbrains.buildServer.serverSide.statistics.diskusage.HugeLogs.LogSizeData>"--%>
<%--@elvariable id="buildMap" type="java.util.Map<java.lang.Long,jetbrains.buildServer.serverSide.SFinishedBuild>"--%>
<%--@elvariable id="buildType" type="jetbrains.buildServer.serverSide.SBuildType"--%>
<%--@elvariable id="total" type="java.lang.String"--%>
<%--@elvariable id="average" type="java.lang.String"--%>
<%--@elvariable id="showMode" type="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode"--%>
<%--@elvariable id="healthStatusReportUrl" type="java.lang.String"--%>
<%--@elvariable id="sizeThreshold" type="java.lang.String"--%>
<%@ include file="/include-internal.jsp"
%><%@ taglib prefix="bs" tagdir="/WEB-INF/tags"
%><%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin"
%><%@ taglib prefix="tags" tagdir="/WEB-INF/tags/tags" %>
<c:set var="inplaceMode" value="<%=HealthStatusItemDisplayMode.IN_PLACE%>"/>
<bs:linkCSS>
  /healthStatus/css/hugeLog.css
</bs:linkCSS>
<c:set var="id"><c:out value="huge_log_${buildType.externalId}"/></c:set>
<div id="${id}" class="huge_log">
  Found <strong>${fn:length(buildDatas)}</strong> build<bs:s val="${fn:length(buildDatas)}"/> in <admin:viewOrEditBuildTypeLinkFull buildType="${buildType}"/> with logs larger than ${sizeThreshold}:<bs:help file="Build+Log" anchor="LargeBuildLogsInspection"/>
  <ul>
    <c:forEach items="${buildDatas}" var="buildData" varStatus="stat">
      <c:if test="${not empty buildMap[buildData.promotionId]}">
        <c:set value="${buildMap[buildData.promotionId]}" var="build"/>
        <li<c:if test="${stat.count > 5}"> class="hidden"</c:if>>
          <span><bs:buildLink buildId="${build.buildId}">Build #${build.buildNumber}</bs:buildLink>
            (<bs:date value="${build.finishDate}"/>) -
            <strong><bs:fileSize value="${buildData.size}" decimals="0"/></strong> <c:if test="${build.pinned}"><bs:pinImg build="${build}"/></c:if>
            <c:if test="${not empty build.tags}">
              <tags:showTags buildTypeId="${buildType.externalId}" tags="${build.tags}"/>
            </c:if></span>
        </li>
      </c:if>
    </c:forEach>
    <c:if test="${fn:length(buildDatas) > 5}">
      <div class="show_all_holder">
        <a href="#" class="show_all_link" onclick="return false;">show ${fn:length(buildDatas) - 5} more...</a>
      </div>
    </c:if>
  </ul>
</div>
<script type="text/javascript">
  jQuery(function($) {
    var holder = $("#${id} .show_all_link");
    holder.click(function () {
      $("#${id} .hidden").removeClass("hidden");
      holder.addClass("hidden");
    });
  }(jQuery));
</script>
