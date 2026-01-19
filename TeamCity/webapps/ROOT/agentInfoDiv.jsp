<%@ include file="include-internal.jsp" %>
<jsp:useBean id="buildType" type="jetbrains.buildServer.serverSide.SBuildType" scope="request"/>
<jsp:useBean id="agent" type="jetbrains.buildServer.serverSide.SBuildAgent" scope="request"/>
<p><strong>${buildType.fullName}</strong> will run on:</p>
<bs:agent agent="${agent}" showRunningStatus="true"/>
