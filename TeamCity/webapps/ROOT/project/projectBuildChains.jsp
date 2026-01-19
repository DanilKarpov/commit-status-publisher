<%@ include file="../include-internal.jsp" %>
<jsp:useBean id="buildChainsBean" type="jetbrains.buildServer.controllers.graph.BuildChainsBean" scope="request"/>

<bs:buildChains buildChainsBean="${buildChainsBean}"/>
