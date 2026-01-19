<%@include file="/include.jsp"
%><jsp:useBean id="buildData" scope="request" type="jetbrains.buildServer.serverSide.SBuild"
/><c:set var="bt" value="${buildData.buildType}"  />

<bs:buildTypeLinkFull buildType="${bt}" branch="${buildData.branch}"/>
<br />
Build: <bs:resultsLink build="${buildData}" noPopup="true" noTitle="true">
  <bs:buildNumber buildData="${buildData}"/>
  <bs:buildDataIcon buildData="${buildData}"/>
  ${buildData.statusDescriptor.text}
</bs:resultsLink>
<br/>
Duration on agent: <strong><bs:printTime time="${buildData.durationOnAgent}" showIfNotPositiveTime="&lt; 1s"/></strong><br/>
(<bs:date value="${buildData.serverStartDate}" pattern="dd MMM yyyy HH:mm:ss"/>
-
<bs:date value="${buildData.finishOnAgentDate}" pattern="dd MMM yyyy HH:mm:ss"/>)

