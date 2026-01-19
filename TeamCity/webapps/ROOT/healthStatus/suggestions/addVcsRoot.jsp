<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="buildType" type="jetbrains.buildServer.serverSide.SBuildType" scope="request"/>
<div class="suggestionItem">
  <admin:editBuildTypeLinkFull buildType="${buildType}"/> does not have VCS roots.

  <div class="suggestionAction">
    <c:set var="url"><c:url value='/admin/attachBuildTypeVcsRoots.html?init=1&id=buildType:${buildType.externalId}'/></c:set>
    <forms:addLink href="${url}">Attach VCS Root</forms:addLink>
  </div>
</div>
