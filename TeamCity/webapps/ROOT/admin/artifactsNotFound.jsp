<%@ include file="/include-internal.jsp"
%><jsp:useBean id="build" type="jetbrains.buildServer.serverSide.SBuild" scope="request"

/><div>
  <div>Build <bs:buildLinkFull build="${build}"/> does not contain artifacts</div>
</div>