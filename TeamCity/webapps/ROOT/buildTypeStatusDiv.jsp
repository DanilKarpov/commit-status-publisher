<%@ page import="jetbrains.buildServer.controllers.BranchUtil" %>
<%@
    include file="include-internal.jsp" %><%@
    taglib prefix="resp" tagdir="/WEB-INF/tags/responsible"%><%@
    taglib prefix="responsible" uri="/WEB-INF/functions/resp" %><%@
    taglib prefix="admin" tagdir="/WEB-INF/tags/admin"%><%@
    taglib prefix="user" tagdir="/WEB-INF/tags/userProfile"%><%@
    taglib prefix="t" tagdir="/WEB-INF/tags/tags"

%><jsp:useBean id="buildType" type="jetbrains.buildServer.serverSide.SBuildType" scope="request"
/><jsp:useBean id="currentUser" type="jetbrains.buildServer.users.SUser" scope="request"
/><jsp:useBean id="pinnedBuild" type="jetbrains.buildServer.controllers.buildType.BuildTypeController.PinnedBuildBean" scope="request"
/><jsp:useBean id="hasCompatibleAgentsOrTypesToRun" type="java.lang.Boolean" scope="request"
/><jsp:useBean id="runningAndQueuedBuilds" type="jetbrains.buildServer.controllers.RunningAndQueuedBuildsBean" scope="request"
/><jsp:useBean id="hasFinishedBuilds" type="java.lang.Boolean" scope="request"
/><jsp:useBean id="branchBean" type="jetbrains.buildServer.controllers.BuildTypeBranchBean" scope="request"
/><c:set var="buildTypeId" value="${buildType.buildTypeId}"
/><c:set var="externalId" value="${buildType.externalId}"
/><c:set var="limitedPendingChanges" value="<%=BranchUtil.getLimitedPendingChanges(branchBean, false)%>"
/><%@ include file="_subscribeToCommonBuildTypeEvents.jspf"
%><c:url var="history_url" value="/viewType.html?buildTypeId=${externalId}&tab=buildTypeHistoryList"
/><et:subscribeOnBuildTypeEvents buildTypeId="${buildType.buildTypeId}">
    <jsp:attribute name="eventNames">
      BUILD_STARTED
      BUILD_CHANGES_LOADED
      BUILD_FINISHED
      BUILD_INTERRUPTED
      BUILD_TYPE_ACTIVE_STATUS_CHANGED
      BUILD_TYPE_ADDED_TO_QUEUE
      BUILD_TYPE_REMOVED_FROM_QUEUE
      CHANGE_ADDED
    </jsp:attribute>
    <jsp:attribute name="eventHandler">
      BS.BuildType.updateView();
    </jsp:attribute>
</et:subscribeOnBuildTypeEvents><div id="buildTypeStatusDiv">
  <%--@elvariable id="serverTC" type="jetbrains.buildServer.serverSide.BuildServerEx"--%>
  <c:set var="runningBuilds" value="${runningAndQueuedBuilds.getRunningBuilds(branchBean)}"/>
  <c:set var="queuedBuilds" value="${runningAndQueuedBuilds.getQueuedBuilds(branchBean)}"/>

  <bs:messages key="buildNotFound"/>
  <c:if test="${(branchBean.matchesDefault && buildType.status.failed && buildType.lastChangesFinished != null) or
                 responsible:isActive(buildType.responsibilityInfo) or responsible:isFixed(buildType.responsibilityInfo)}">
    <div>
      <resp:responsible buildData="${buildType.lastChangesFinished}" server="${serverTC}" currentUser="${currentUser}"/>
    </div>
  </c:if>
  <c:set var="idle" value="${empty runningBuilds and empty queuedBuilds}"/>
  <c:set var="showIdle" value="${idle and not buildType.paused}"/>
  <div class="runningBuildsDiv">
    <c:if test="${not idle}">
      <h3 class="runningBuildsHeading">
        <bs:buildTypeStatusText theRunningBuilds="${runningBuilds}"
                                queuedBuilds="${queuedBuilds}"
                                buildType="${buildType}"
                                branchBean="${branchBean}"
                                noPopupForRunning="true"/>
      </h3>
    </c:if>
    <c:set var="inBranch"
      ><c:choose
        ><c:when test="${branchBean.defaultBranch}">in the default branch</c:when
        ><c:when test="${branchBean.singleBranch}">in <c:out value="${branchBean.userBranch}"/> branch</c:when
        ><c:when test="${not branchBean.allBranches}">in the selected branches</c:when
      ></c:choose
    ></c:set>
    <c:if test="${showIdle}">
      <div class="noBuildsNote">
        No running ${hasFinishedBuilds ? '' : 'or finished '}builds ${inBranch}
      </div>
    </c:if>
    <div class="buildTypeCurrentStatus">
      <c:if test="${limitedPendingChanges.containsChanges}">
        <div id="pendingChangesDiv" class="pendingChangesDiv">
          <bs:pendingChangesLink buildType="${buildType}"
                                 pendingChanges="${limitedPendingChanges.changes}"
                                 branchBean="${branchBean}">
            <c:set var="num" value="${fn:length(limitedPendingChanges.changes)}"/>
            ${num}${limitedPendingChanges.limitExceeded ? '+' : ''} pending change<bs:s val="${num}"/>
          </bs:pendingChangesLink>
        </div>
      </c:if>
      <c:if test="${not buildType.compositeBuildType and not hasCompatibleAgentsOrTypesToRun}">
        <a class="noCompatibleAgentsLink" href="viewType.html?tab=compatibilityList&buildTypeId=${externalId}">No suitable agents</a>
      </c:if>
      <bs:systemProblemMarker buildTypeId="${buildTypeId}" branchBean="${branchBean}" maxWidth="100"/>
    </div>
    <c:if test="${empty runningBuilds and hasFinishedBuilds}">
      <hr>
    </c:if>
    <c:if test="${not hasFinishedBuilds and not showIdle}">
      <div class="noBuildsNote noFinishedBuildsNote">
        No finished builds ${inBranch}
      </div>
    </c:if>
  </div>

  <div id="shortHistory"></div>
  <script>
    (function () {
      function renderBuildTypeHistory(branch){
        ReactUI.renderShortBuildTypeHistory('shortHistory', {
          buildTypeId: '<bs:escapeForJs text="${buildType.externalId}"/>',
          branch: branch,
          maxBuildCount: 15,
          showAgent: ${!buildType.compositeBuildType},
          hasRunningBuilds: ${not empty runningBuilds},
          hasFinishedBuilds: ${hasFinishedBuilds}
        });
      }
      BS.Branch.renderBuildList('<bs:escapeForJs text="${branchBean.userBranch}"/>', ${branchBean.allBranches}, renderBuildTypeHistory);
    })();
  </script>
  <bs:pinBuildDialog onBuildPage="${false}" buildType="${buildType}"/>
  <bs:buildCommentDialog/>
</div>

<script type="text/javascript">
  $j('.fading').each(function() {
    BS.Highlight(this);
  });
  BS.Branch.injectBranchParamToLinks($j("#pendingChangesDiv, #showHistory"), "${buildType.projectExternalId}");
  $j(document).ready(function() {
    BS.SystemProblems.setOptions({btId:'${buildType.buildTypeId}'});
    BS.SystemProblems.startUpdates();
  });
</script>
