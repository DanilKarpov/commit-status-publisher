<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="build" type="jetbrains.buildServer.serverSide.SBuild" scope="request"/>

<div>
  The latest finished build is
  <bs:buildTypeLink buildType="${build.buildType}"><c:out value="${build.buildType.fullName}"/></bs:buildTypeLink>
  <bs:buildLink build="${build}">#<c:out value="${build.buildNumber}"/></bs:buildLink><br>
  Select files to be published as artifacts from its checkout directory:
</div>

<div id="agentTree"></div>
<div class="agentTreeSelectedPathDiv" style="display: none">
  Selected: <span class="agentTreeSelectedPath" id="selectedPath"></span>
  <span class="clipboard-btn tc-icon icon16 tc-icon_copy" data-clipboard-action="copy" data-clipboard-target=".agentTreeSelectedPath"/>
</div>

<script type="text/javascript">
  BS.Clipboard('.agentTreeSelectedPathDiv .clipboard-btn');

  BS.LazyTree.ignoreHashes = true;
  BS.LazyTree.treeUrl = window['base_uri'] + "/agent/tree.html?buildTypeId=${build.buildType.externalId}&buildId=${build.buildId}";
  BS.LazyTree.loadTree("agentTree");
</script>
