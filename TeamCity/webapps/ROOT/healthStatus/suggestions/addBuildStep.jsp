<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="buildType" type="jetbrains.buildServer.serverSide.SBuildType" scope="request"/>
<div class="suggestionItem">
  <admin:editBuildTypeLinkFull buildType="${buildType}"/> does not have build steps.

  <div class="suggestionAction">
    <c:url value="/admin/discoverRunners.html?init=1&id=buildType:${buildType.externalId}" var="discoverLink"/>
    <forms:addLink href="${discoverLink}">Add Build Step</forms:addLink>
  </div>
</div>
