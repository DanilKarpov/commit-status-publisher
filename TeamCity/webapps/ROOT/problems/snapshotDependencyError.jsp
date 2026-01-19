<%--@elvariable id="buildProblem" type="jetbrains.buildServer.serverSide.problems.BuildProblem"--%>
<%--@elvariable id="dependOnBuildPromotion" type="jetbrains.buildServer.serverSide.BuildPromotion"--%>
<%--@elvariable id="dependentBuildState" type="jetbrains.buildServer.web.problems.impl.BaseSnapshotDependencyErrorBuildProblemRenderer.DependentBuildState"--%>
<%--@elvariable id="compactMode" type="java.lang.Boolean"--%>
<%--@elvariable id="contextProject" type="jetbrains.buildServer.serverSide.SProject"--%>
<%--@elvariable id="buildProblemUID" type="java.lang.String"--%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags" %>
<%@ taglib prefix="queue" tagdir="/WEB-INF/tags/queue" %>
<c:set var="uid" value="${buildProblemUID}"/>
<div id="newContent_${uid}" style="display: none; padding: 0; margin: 0; vertical-align: top;">
  <c:choose>
    <c:when test="${not empty dependOnBuildPromotion && !compactMode}">
      <c:set var="buildType" value="${dependOnBuildPromotion.buildType}"/>
      <c:set var="dependOnBuild" value="${dependOnBuildPromotion.associatedBuild}"/>
      <c:set var="queuedBuild" value="${dependOnBuildPromotion.queuedBuild}"/>
      <c:set var="branch" value="${dependOnBuildPromotion.branch}"/>
      <c:if test="${not empty buildType}">
        <bs:responsibleIcon responsibility="${buildType.responsibilityInfo}" buildTypeRef="${buildType}"/>
        <c:choose>
        <c:when test="${not empty dependOnBuild}">
          <bs:buildTypeLinkFull buildType="${buildType}" fullProjectPath="true" popupMode="true" contextProject="${contextProject}" branch="${branch}"/>
          <span class="branch ${not empty branch ? 'hasBranch' : ''} ${not empty branch and branch.defaultBranch ? 'default' : ''}">
            <c:if test="${not empty branch}">
              <bs:branchLink branch="${branch}" trim="true" noLink="true"><bs:trimBranch branch="${branch}"/></bs:branchLink>
              <script type="text/javascript">$j("#changeblock${dependOnBuild.buildId}").parents(".modificationBuilds").addClass("hasBranches");</script>
            </c:if>
          </span>

          <bs:buildDataIcon buildData="${dependOnBuild}" imgId="build:${dependOnBuild.buildId}:img" attrs="buildId='${dependOnBuild.buildId}'"/>
          <bs:buildNumber buildData="${dependOnBuild}" withLink="true"/>
          <bs:resultsLink build="${dependOnBuild}" attrs="buildId='${dependOnBuild.buildId}'"><span class="dependentBuildResult" id="build:${dependOnBuild.buildId}:text"><c:out value="${dependOnBuild.statusDescriptor.text}"/></span></bs:resultsLink>
        </c:when>
        <c:when test="${not empty queuedBuild}">
          <span class="branch ${not empty branch ? 'hasBranch' : ''} ${not empty branch and branch.defaultBranch ? 'default' : ''}">
            <c:if test="${not empty branch}">
              <bs:branchLink branch="${branch}" trim="true" noLink="true"><bs:trimBranch branch="${branch}"/></bs:branchLink>
              <script type="text/javascript">$j("#changeblock${dependOnBuild.buildId}").parents(".modificationBuilds").addClass("hasBranches");</script>
            </c:if>
          </span>
          <bs:queuedBuildIcon promotion="${queuedBuild.buildPromotion}"/>
          <queue:queueLink queuedBuild="${queuedBuild}"><bs:buildTypeFullName buildType="${buildType}" contextProject="${contextProject}"/></queue:queueLink>
        </c:when>
        </c:choose>
      </c:if>
    </c:when>
    <c:when test="${not empty dependOnBuildPromotion && compactMode}">
      <c:out value="${dependOnBuildPromotion.buildType.fullName}"/>
      <script type="text/javascript">
        var outerLink = $j('#problemLink_${uid}');
        var link = '<c:url value="/viewQueued.html?itemId=${dependOnBuildPromotion.id}&problemId=${buildProblem.id}"/>';
        if (outerLink != undefined){
          outerLink.attr('href', link);
          outerLink.attr('title', 'Show dependency build details');
        }
      </script>
    </c:when>
    <c:when test="${empty dependOnBuildPromotion && dependentBuildState=='CLASSIFIED'}">
      &nbsp;<span class="noDependencyBuildInfo">You do not have enough permissions to view build problem details</span>
    </c:when>
    <c:when test="${empty dependOnBuildPromotion && dependentBuildState=='DELETED'}">
      &nbsp;<span class="noDependencyBuildInfo">The dependency build was removed</span>
    </c:when>
  </c:choose>
</div>
<c:choose>
  <c:when test="${compactMode}">
    <script type="text/javascript">
      BS.Util.runWithElement('descriptionContainer_${uid}', function(elemIsAvailable) {
        if (elemIsAvailable) {
          BS.BuildProblems.updateSnapshotDependencyCompactDescription('${uid}', '#newContent_${uid}');
        } else {
          BS.Log.info('#descriptionContainer_${uid} is not ready in 5 sec');
        }
      }, 5000);
    </script>
  </c:when>
  <c:otherwise>
    <script type="text/javascript">
      BS.Util.runWithElement('descriptionContainer_${uid}', function(elemIsAvailable) {
        if (elemIsAvailable) {
          BS.BuildProblems.updateSnapshotDependencyDescription('${uid}', '#newContent_${uid}');
        } else {
          BS.Log.info('#descriptionContainer_${uid} is not ready in 5 sec');
        }
      }, 5000);
    </script>
  </c:otherwise>
</c:choose>

