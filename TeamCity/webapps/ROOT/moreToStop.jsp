<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="sequenceBuildInfo" type="jetbrains.buildServer.controllers.promotionGraph.SequenceBuildInfo" scope="request"/>

<c:if test="${empty buildPromotion}">
  Cannot find build data, it seems that build is already deleted.
  <script language="text/javascript">
    BS.StopBuildDialog.handleBuildNotFound();
  </script>
</c:if>
<c:if test="${not empty buildPromotion}">
<jsp:useBean id="buildPromotion" type="jetbrains.buildServer.serverSide.BuildPromotion" scope="request"/>

<c:if test="${(not buildPromotion.partOfBuildChain or buildPromotion.numberOfDependedOnMe == 0) and not buildPromotion.compositeBuild}">
<c:if test="${(not buildIsInQueue or buildIsInQueue == false) and (not empty operationKind && operationKind == '2')}">
  <div id="reAddSection">
    <forms:checkbox name="readd" id="stopBuildReadd"/><label for="stopBuildReadd">Re-add build to the queue</label>
    <br/>
  </div>
</c:if>
</c:if>
<c:if test="${buildPromotion.partOfBuildChain}">

<div class="stop__infoLine">
  This build is a part of a build chain.<bs:help file="Build+Chain" />
</div>

<c:set var="buildsToShow" value="${not empty operationKind && operationKind == '3' ?
                                   sequenceBuildInfo.buildsToRemove : sequenceBuildInfo.buildsToStop}"/>

<c:choose>
  <c:when test="${not empty buildsToShow and not sequenceBuildInfo.hasUnavailable}">
    <div class="stop__infoLine">
      Stop<c:if test="${not empty operationKind && operationKind == '3'}"> or remove</c:if> other parts:
      <br>
    <c:if test="${fn:length(buildsToShow) > 1}">
        <label class="withUnsharedDepsLabel"><forms:checkbox name="withUnsharedDeps" id="withUnsharedDeps" value="${buildPromotion.id}"/><strong>Non-reused builds this one depends on</strong></label>

      <label for="killAll"><forms:checkbox name="killAll" id="killAll"/><strong>All builds</strong></label>
    </c:if>
    </div>
  </c:when>
  <c:when test="${not empty buildsToShow and sequenceBuildInfo.hasUnavailable}">
    <!--You may also want to stop the following builds from the sequence (you don't have access rights for all the builds):-->
    <div class="attentionComment"><bs:buildStatusIcon type="red-sign" className="warningIcon"/>You don't have access rights to see some of its parts.</div>
    <div class="stop__infoLine">
      Select builds to stop:
    </div>
  </c:when>
  <c:when test="${empty buildsToShow and sequenceBuildInfo.hasUnavailable}">
    <div class="attentionComment"><bs:buildStatusIcon type="red-sign" className="warningIcon"/>You don't have access rights to see its other parts.</div>
  </c:when>
</c:choose>


<c:forEach items="${buildsToShow}" var="buildInfo">
  <c:set var="canKill" value="${not empty operationKind && operationKind == '3' ?
                                          buildInfo.canRemove : buildInfo.canStop}"/>

  <c:if test="${canKill}">
    <forms:checkbox id="bi${buildInfo.id}" name="kill" value="${buildInfo.promotion.id}" checked="${buildInfo.checked}"
                    attrs="${buildInfo.dependent ? 'data-dependent-build=true':''} ${buildInfo.dependentSafeRemove ? 'data-safe-remove=true':''}"
    />
  </c:if>
  <c:if test="${not canKill}">
    <forms:checkbox name="" className="checkboxPlaceholder"/>
  </c:if>

  <bs:queueDependencyState dependency="${buildInfo.promotion}"/>
</c:forEach>



</c:if>
  <c:if test="${not empty operationKind && operationKind == '3'}">
    <div id="leaveStatisticData">
      <forms:checkbox id="statsCB" name="stats"/><label for="statsCB">Keep statistic data</label>
    </div>
  </c:if>
</c:if>


<script>
  (function markUnsharedDependenciesForDeletionIfNeeded() {

    if ($j('#withUnsharedDeps').length && ${ufn:booleanPropertyValue(currentUser, 'stopBuildWithUnsharedDependencies')}) {
      setTimeout(function() {
        $j('#withUnsharedDeps').click();
      }, 300);
    }

  })();
</script>
