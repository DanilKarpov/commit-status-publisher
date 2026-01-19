<%@ include file="include-internal.jsp" %>
<jsp:useBean id="changes" scope="request" type="java.util.List"/>
<jsp:useBean id="lastSuccessful" scope="request" type="jetbrains.buildServer.Build"/>

<script type="text/javascript">
  <%@include file="/js/bs/blocks.js"%>
  <%@include file="/js/bs/blocksWithHeader.js"%>
  <%@include file="/js/bs/buildChangesBlock.js"%>
</script>

<div class="changePopupHeader">

  <div>Changes since <bs:resultsLink build="${lastSuccessful}">build <bs:buildNumber buildData="${lastSuccessful}"/></bs:resultsLink>
    (<bs:date value="${lastSuccessful.startDate}"/>)
  </div>

  <c:if test="${empty changes}">
    <div>
      No changes since the last successful build.
    </div>
  </c:if>

  <c:if test="${not empty changes}">
    <c:set var="firstChange" value="<%=changes.get(0)%>"/>
    <div>
      <c:url value='/viewType.html?buildTypeId=${lastSuccessful.buildTypeExternalId}&tab=buildTypeChangeLog' var="changeLogUrl"/>
      Displaying changes from no more than 25 recent builds, <bs:changeLogLink baseUrl="${changeLogUrl}" from="${firstChange.build.buildNumber}" to="${lastSuccessful != null ? lastSuccessful.buildNumber : ''}">view all &raquo;</bs:changeLogLink>
    </div>
  </c:if>
</div>

<c:if test="${not empty changes}">
  <c:forEach items="${changes}" var="changesBean">
    <div class="icon_before icon16 buildChangesHeader blockHeader expanded" id="build${changesBean.build.buildId}">
      <table width="100%"><tr><bs:buildRow build="${changesBean.build}" showBuildNumber="true" showStatus="true" showStartDate="true"/></tr></table>
    </div>
    <div id="build${changesBean.build.buildId}_changes">
      <bs:changesPopupGroupedChanges changes="${changesBean}"/>
    </div>
    <script type="text/javascript">
      <l:blockState blocksType="Block_${changesBean.build.buildId}"/>
      new BS.BuildChangesBlock('build${changesBean.build.buildId}');
    </script>
  </c:forEach>
</c:if>

<script type="text/javascript">
  BS.ChangesPopup.initArtifactChangesBlocks();
</script>
