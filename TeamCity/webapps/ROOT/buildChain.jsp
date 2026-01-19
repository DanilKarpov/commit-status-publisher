<%@ include file="include-internal.jsp" %>
<jsp:useBean id="buildChain" type="jetbrains.buildServer.serverSide.dependency.BuildChain" scope="request"/>
<c:set var="graphId" value="graph_${buildChain.id}"/>
<c:set var="settingsPreviewMode" value="${fn:length(buildChain.allPromotions) eq 0}"/>
<bs:externalPage>
  <jsp:attribute name="page_title">View build chain</jsp:attribute>
  <jsp:attribute name="head_include">
    <bs:linkCSS>
      /css/settingsTable.css
      /css/autocompletion.css
      /css/tabs.css
      /css/forms.css
      /css/runCustomBuild.css

      /css/buildQueue.css
      /css/layeredGraph.css
      /css/buildChains.css
      /css/tree/tree.css
      /css/overviewTable.css
      /css/changeLog.css
      /css/filePopup.css
      /css/pager.css
      /css/progress.css
      /css/investigation.css
      /css/testList.css
      /css/testGroups.css
      /css/buildLog/buildResultsDiv.css
    </bs:linkCSS>
    <bs:linkScript>
      <%-- BS - utility components --%>
      /js/bs/resize.js
      /js/bs/refresh.js

      <%-- BS - common components --%>
      /js/bs/tabs.js
      /js/bs/forms.js
      /js/bs/modalDialog.js
      /js/bs/investigation.js
      /js/bs/changeBuildStatus.js
      /js/bs/tree.js
      /js/bs/issues.js
      /js/bs/pluginProperties.js
      /js/bs/serverLink.js
      /js/bs/tags.js

      <%-- BS - business logic --%>
      /js/bs/adminActions.js
      /js/bs/runBuild.js
      /js/bs/runningBuilds.js
      /js/bs/stopBuild.js
      /js/bs/customControl.js
      /js/bs/parameters.js
      /js/bs/editParameters.js
      /js/bs/branch.js

      /js/raphael-min.js
      /js/raphael.pieChart.js

      /js/bs/locationHash.js
      /js/bs/layeredGraph.js
      /js/bs/pieChartStatus.js
      /js/bs/buildChains.js
      /js/bs/activation.js
      /js/bs/blocks.js
      /js/bs/blockWithHandle.js
      /js/bs/blocksWithHeader.js
      /js/bs/collapseExpand.js
      /js/bs/changeLog.js
      /js/bs/changeLogGraph.js
      /js/bs/async.js
      /js/bs/testDetails.js
      /js/bs/testGroup.js
      /js/bs/buildResultsDiv.js
      /js/bs/restProjectsPopup.js
    </bs:linkScript>

    <style type="text/css">
      .openChainInNewWindow {
        display: none;
      }
    </style>
    <script type="text/javascript">
      BS.WebSocketProperties.webSocketEnabled = ${webSocketFeature.enabled}
      BS.WebSocketProperties.heartbeatIntervalMillis = ${webSocketFeature.heartbeatIntervalMillis}

      <c:if test="${not settingsPreviewMode}">
      BS.SubscriptionManager.start();
      $j(document).ready(function() {
        if (typeof BS == "undefined") return;
        BS.EventTracker.startTracking("<c:url value='/eventTracker.html'/>");
      });
      </c:if>
    </script>
    <problems:buildProblemStylesAndScripts/>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <div id="mainContent">
      <div class="singleBuildChain">
        <bs:refreshable containerId="allChains" pageUrl="${pageUrl}">

        <bs:_singleChainBlock buildChain="${buildChain}" serverSideExpand="true" contextProject="${contextProject}" selectedBuildTypeId="${param['selectedBuildTypeId']}" showHeader="false"/>

        <c:if test="${not settingsPreviewMode}">
        <c:forEach items="${buildChain.notFinishedChainBuildTypes}" var="buildType">
          <et:subscribeOnBuildTypeEvents buildTypeId="${buildType.buildTypeId}">
            <jsp:attribute name="eventNames">
              BUILD_STARTED
              BUILD_FINISHED
              BUILD_INTERRUPTED
              BUILD_TYPE_REMOVED_FROM_QUEUE
              BUILD_TYPE_ADDED_TO_QUEUE
            </jsp:attribute>
            <jsp:attribute name="eventHandler">
              BS.BuildChains.scheduleAllChainsRefresh(1000);
            </jsp:attribute>
          </et:subscribeOnBuildTypeEvents>
        </c:forEach>
        </c:if>
        </bs:refreshable>

      </div>
    </div>

    <bs:commonTemplates/>
    <bs:commonDialogs/>

  </jsp:attribute>
</bs:externalPage>
