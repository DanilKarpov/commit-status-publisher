<%@ include file="include-internal.jsp"
%><jsp:useBean id="buildType" type="jetbrains.buildServer.serverSide.SBuildType" scope="request"
/><jsp:useBean id="bean" type="jetbrains.buildServer.controllers.buildType.tabs.BuildTypeAgentBrowserBean" scope="request"/>

<div id="agent-chooser">
  <c:url var="baseUrl" value="/viewType.html?buildTypeId=${buildType.externalId}&tab=agentBrowse"/>

  <c:choose>
    <c:when test="${empty bean.lastBuilds}">
      No connected agents that run builds in this configuration found.
    </c:when>
    <c:otherwise>
      <label for="build">Agent to browse:</label>
      <forms:select name="build" enableFilter="true" onchange="return BS.AgentBrowse.chooseSelected('#build', '${baseUrl}');">
        <option value="">-- Choose the agent --</option>
        <c:forEach items="${bean.lastBuilds}" var="build">
          <forms:option value="${build.buildId}"
                        selected="${build.buildId == bean.buildId}"><c:out value="${build.agent.name}"/> (build #${build.buildNumber})</forms:option>
        </c:forEach>
      </forms:select>
    </c:otherwise>
  </c:choose>
</div>

<c:set var="data" value="${bean.browseData}"/>
<c:choose>
  <c:when test="${empty data}">
  </c:when>
  <c:when test="${not empty bean.error}">
    <span class="error"><c:out value="${bean.error}"/></span>
  </c:when>
  <c:otherwise>
    <c:if test="${not empty bean.interferingBuild}">
      <c:set var="build" value="${bean.interferingBuild}"/>
      <div class="attentionComment">
        <bs:buildStatusIcon type="red-sign" className="warningIcon"/>There is a running build <bs:buildTypeLink buildType="${build.buildType}">${build.buildType.fullName}</bs:buildTypeLink>
        <bs:buildLink build="${build}">#${build.buildNumber}</bs:buildLink>
        on the same agent, which can affect the checkout directory you're browsing.
      </div>
    </c:if>
    <div id="checkout-dir">
      Checkout directory on agent <bs:agent agent="${data.buildAgent}"/>: <code><c:out value="${data.checkoutDirectory}"/></code>
    </div>

    <div id="agentTree"></div>

    <script type="text/javascript">
      BS.LazyTree.treeUrl = window['base_uri'] + "/agent/tree.html?buildTypeId=${buildType.externalId}&buildId=${data.build.buildId}";
      BS.LazyTree.allowDirectoryClick = true;
      BS.LazyTree.loadTree("agentTree");
      BS.blockRefreshPermanently();

      $j(window).on("bs.agentFile", function(e, name) {
        var url = window['base_uri'] + "/agent/download.html?buildTypeId=${buildType.externalId}&buildId=${data.build.buildId}&fileName=" + name;
        window.open(url);
      });
    </script>
  </c:otherwise>
</c:choose>
