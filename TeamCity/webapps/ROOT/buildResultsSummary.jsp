<%@ include file="include-internal.jsp" %>
<%@ taglib prefix="resp" tagdir="/WEB-INF/tags/responsible" %>
<%@ taglib prefix="tt" tagdir="/WEB-INF/tags/tests" %>
<%@ taglib prefix="problems" tagdir="/WEB-INF/tags/problems" %>
<bs:messages key="buildNotFound"/>

<%--@elvariable id="buildResultsSummary" type="jetbrains.buildServer.controllers.viewLog.BuildResultsSummary"--%>
<c:if test="${not empty buildResultsSummary}">
<jsp:useBean id="buildResultsSummary" type="jetbrains.buildServer.controllers.viewLog.BuildResultsSummary" scope="request"/>

<c:set var="build" value="${buildResultsSummary.build}"/>
<c:set var="buildStatistics" value="${buildResultsSummary.buildStatistics}"/>
<c:set var="id" value="buildResults_${build.buildId}"/>
<bs:refreshable containerId="${id}" pageUrl="${pageUrl}">
<table class="buildResultsSummaryTable">
  <td>

    <div class="header">Build shortcuts</div>

      <ul class="bsLinks">
        <li>
          <a href="<c:url value='/viewLog.html?tab=buildLog&buildTypeId=${build.buildTypeExternalId}&buildId=${build.buildId}'/>"
                 title="View log messages">Build log</a
          ><a href="<c:url value='/downloadBuildLog.html?buildId=${build.buildId}&archived=true'/>" target="_blank"
             rel="noreferrer"
             class="actionIconWrapper downloadBuildLog"
             title="Download archived build log"><bs:svgIcon name="download" className="actionIcon"/></a>
        </li>

        <c:forEach items="${buildResultsSummary.extensions}" var="extension">
          <li><bs:_viewLog build="${build}" title="View ${extension.tabTitle}" tab="${extension.tabId}">${extension.tabTitle}</bs:_viewLog></li>
        </c:forEach>
      </ul>

  </td>

  <c:if test="${buildStatistics.failedTestCount > 0 or buildResultsSummary.ownBuildProblemsBean.hasBuildProblems or buildResultsSummary.hasProblemsFromDependencies}">
  <td style="padding: 0 0 5px 15px">

    <bs:buildProblemsSection ownBuildProblemsBean="${buildResultsSummary.ownBuildProblemsBean}"
                             hasDependenciesProblems="${buildResultsSummary.hasProblemsFromDependencies}"
                             numberOfNonTestRelatedProblems="${buildResultsSummary.numberOfNonTestRelatedProblems}"
                             totalNumberOfProblems="${buildResultsSummary.totalNumberOfProblems}"
                             ownAndDependenciesProblemsBean="${buildResultsSummary.dependenciesProblemsBean}"
                             contextBuildType="${buildResultsSummary.build.buildType}"
                             compactMode="true" refreshFunction="$('${id}').refresh()"/>

    <tt:failedTestsSummary maxTestNameLength="${param.forExpandedBuild ? null : '120'}" buildResultsSummary="${buildResultsSummary}"/>
  </td>
  </c:if>

</table>
</bs:refreshable>
</c:if>
