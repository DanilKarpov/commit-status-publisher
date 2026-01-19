<%@ include file="include-internal.jsp" %>
<jsp:useBean id="buildType" type="jetbrains.buildServer.serverSide.BuildTypeEx" scope="request"/>
<jsp:useBean id="buildChainsBean" type="jetbrains.buildServer.controllers.graph.BuildChainsBean" scope="request"/>
<%@ include file="_subscribeToCommonBuildTypeEvents.jspf" %>

<bs:buildChains buildChainsBean="${buildChainsBean}" contextProject="${contextProject}"/>

<script type="text/javascript">
  BS.Branch.baseUrl = "${pageUrl}";
</script>
