<%@ include file="include-internal.jsp" %>
<jsp:useBean id="chainGraph" type="jetbrains.buildServer.controllers.graph.BuildChainGraph" scope="request"/>
<c:if test="${onlyOneGroup}">
  <p class="smallNote" style="margin-left: 0;">Grouping by project is disabled because all of the build chain build configurations belong to the same project.</p>
</c:if>

<bs:buildChain buildChainGraph="${chainGraph}" wrapInRefreshable="false" autoRefresh="true" selectedBuildType="${selectedBuildType}" ungroupedProjects="${ungroupedProjects}"/>
