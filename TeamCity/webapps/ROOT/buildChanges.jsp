<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="changes" scope="request" type="jetbrains.buildServer.controllers.changes.ChangesBean"/>


<c:set var="historyBuildWithChanges" value="${changes.outOfChangesSequence and not empty changes.build and fn:length(changes.build.revisions) > 0}"/>
<c:if test="${historyBuildWithChanges and not empty changes.changes}">
    <div class="historyBuildNote changePopupHeader">
    This build contains
      <bs:_viewLog build="${changes.build}" title="Click to see all build changes" attrs="" tab="buildChangesDiv">change<bs:s val="${fn:length(changes.modifications)}"/></bs:_viewLog> created <bs:date smart="true" value="${changes.modifications[0].date}"/>.
    <c:if test="${empty changes.build.containingChanges}">
      <br/>
    The most recent changes included into this build are shown below.
    </c:if>
    </div>
</c:if>

<c:if test="${empty changes.changes}">
<div class="changePopupHeader">
  <c:choose>
    <c:when test="${changes.pendingChanges}">No pending changes. Build with these changes just started.</c:when>
    <c:otherwise>
      <c:set var="promo" value="${changes.buildPromotion}"/>
      <c:set var="build" value="${changes.build}"/>
      <c:choose>
        <c:when test="${not empty build}">
          No changes in this build. <bs:_viewLog build="${build}" tab="buildChangesDiv">View source revisions</bs:_viewLog>
        </c:when>
        <c:otherwise>
          <c:set var="queuedBuild" value="${changes.queuedBuild}"/>
          <c:if test="${not empty queuedBuild}">
            <c:choose>
              <c:when test="${promo.changeCollectingNeeded}">Changes are not yet collected.</c:when>
              <c:otherwise>No changes in this build. <bs:_viewQueued queuedBuild="${queuedBuild}" tab="buildChangesDiv">View source revisions</bs:_viewQueued></c:otherwise>
            </c:choose>
          </c:if>
          <c:if test="${empty queuedBuild}">No changes in this build.</c:if>
        </c:otherwise>
      </c:choose>
    </c:otherwise>
  </c:choose>
</div>
</c:if>

<c:choose>
  <c:when test="${not historyBuildWithChanges}">
    <div id="groupedChanges">
      <bs:changesPopupGroupedChanges changes="${changes}"/>
    </div>
  </c:when>
  <c:otherwise>
    <div id="ungroupedChanges">
      <table class="changesPopupTable">
        <c:set var="currUser" value=""/>
        <c:choose>
          <c:when test="${changes.buildPromotion != null}">
            <c:set var="resolverContext" value="${changes.buildPromotion}"/>
          </c:when>
          <c:otherwise>
            <c:set var="resolverContext" value="${changes.ownerBuildType}"/>
          </c:otherwise>
        </c:choose>
        <c:forEach items="${changes.modifications}" var="change">
          <c:if test="${not changefn:isArtifactDependencyModification(change)}">
            <%@ include file="changePopupRow.jspf" %>
          </c:if>
        </c:forEach>
        <c:set var="showArtDepsSection" value="true"/>
        <c:forEach items="${changes.modifications}" var="change">
          <c:if test="${changefn:isArtifactDependencyModification(change)}">
            <c:if test="${showArtDepsSection}">
              <tr>
                <td colspan="4" class="icon_before icon16 changePopupHeader artifactsChangeHeader blockHeader collapsed">Artifact dependency changes</td>
              </tr>
              <c:set var="showArtDepsSection" value="false"/>
            </c:if>
            <%@ include file="changePopupRow.jspf" %>
          </c:if>
        </c:forEach>
      </table>
    </div>
  </c:otherwise>
</c:choose>

<c:choose>
<c:when test="${changes.limit > 0}">
<div class="changePopupHeader">
  and ${changes.total-changes.limit} more.
    <c:choose>
      <c:when test="${not empty changes.build}">
          <bs:_viewLog build="${changes.build}" title="Click to see all changes" attrs="" tab="buildChangesDiv">Show all ${changes.total} changes &raquo;</bs:_viewLog>
      </c:when>
      <c:otherwise>
        <c:if test="${not changes.ownerBuildType.personal}">
          <c:url var="href" value='/viewType.html?buildTypeId=${changes.ownerBuildType.externalId}&tab=pendingChangesDiv'/>
          <a href="${href}" title="Click to see all changes">Show all ${changes.total} changes &raquo;</a>
        </c:if>
      </c:otherwise>
    </c:choose>
</div>
</c:when>
<%--@elvariable id="suspiciousBean" type="jetbrains.buildServer.controllers.changes.SuspiciousChanges"--%>
<c:when test="${suspiciousBean.hasModifications}">
  <div class="changePopupHeader">
    <c:set var="body">
      ${suspiciousBean.modificationsNumber} more change<bs:s val="${suspiciousBean.modificationsNumber}"/> might have broken this build &raquo;
    </c:set>
    <c:url var="href" value="/viewType.html?buildTypeId=${changes.ownerBuildType.externalId}&tab=buildTypeChangeLog&showBuilds=true">
      <c:param name="from" value="${suspiciousBean.firstNormalBuild.buildNumber}"/>
      <c:param name="to" value="${suspiciousBean.lastFailureBuild.buildNumber}"/>
    </c:url>
    <a href="${href}" title="${title}">${body}</a>
  </div>
</c:when>
</c:choose>

<div class="clr"></div>

<c:if test="${historyBuildWithChanges}">
  <c:set var="seq" value="${changes.build.sequenceBuild}"/>
  <c:if test="${not empty seq and seq.buildId != changes.build.buildId}">
    <div class="changesPopupFooter">
      <c:set var="changeTxt" value="this change"/>
      <c:if test="${fn:length(changes.modifications)> 1}">
        <c:set var="changeTxt" value="all these changes"/>
      </c:if>
    The first build with ${changeTxt} was <bs:resultsLink build="${seq}">build <bs:buildNumber buildData="${seq}"/></bs:resultsLink><br/>
    </div>
  </c:if>
</c:if>

<script type="text/javascript">
  (function() {
    var container = $j("#changesContainer"),
        window = $j(window);
    var totalHeight = window.height() || 0,
        scrollTop = window.scrollTop(),
        popupHeight = container.height(),
        popupOffset = container.offset();

    // If there is enough space for the popup without clipping, don't do anything (TW-19086).
    if (totalHeight - 5 <= popupHeight + popupOffset.top - scrollTop) {
      container.find(".userChangeComment").filter(":not(.artifactComment)").installEllipsis();
    }
  })();
  BS.ChangesPopup.initArtifactChangesBlocks();
</script>