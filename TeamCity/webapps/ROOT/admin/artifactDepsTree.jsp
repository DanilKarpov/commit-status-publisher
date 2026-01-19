<%@ include file="/include-internal.jsp"
%><jsp:useBean id="build" type="jetbrains.buildServer.serverSide.SBuild" scope="request"/>
<c:set var="url" value='${pageUrl}'/>
<bs:storeBuildData buildPromotion="${build.buildPromotion}" withArtifactsTree="true" />
<div>
  <div>Choose the artifacts of build <bs:buildLinkFull build="${build}"/>:</div>
  <div class="artifactsTreeWrapper">
    <div id="artifactsTree"></div>
  </div>
  <script type="text/javascript">
    (function() {
      ReactUI.renderConnected('artifactsTree', ReactUI.BuildArtifactsTree, {
        buildId: ${build.buildId},
        <c:if test="${param.forReportTab ne 'true'}">canSelectDirs: true,</c:if>
        showToggleHidden: true,
        onSelect: function(path) {
          BS.EditArtifactDependencies.appendPath(path);
        }
      });
    })();
  </script>
</div>