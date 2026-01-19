<%@include file="/include-internal.jsp"%>
<%--@elvariable id="nodeDiagnostics" type="jetbrains.buildServer.diagnostic.web.NodeDiagnosticsDetails"--%>
<%--@elvariable id="moreChangesReason" type="jetbrains.buildServer.serverSide.impl.BuildPromotionReplacementLog.ReplacementReason"--%>
<%--@elvariable id="startedBuildExistsReason" type="jetbrains.buildServer.serverSide.impl.BuildPromotionReplacementLog.ReplacementReason"--%>
<%--@elvariable id="memoryDumpAvailable" type="java.lang.Boolean"--%>
<%--@elvariable id="restartAvailable" type="java.lang.Boolean"--%>
<%--@elvariable id="restartUnavailableReason" type="java.lang.String"--%>

<bs:linkScript>
  /js/bs/hostnameConfirm.js
  /js/bs/serverRestart.js
</bs:linkScript>

<c:set var="nd" value="${nodeDiagnostics}"/>

<c:set var="node" value="${nd.teamCityNode}"/>
<c:set var="serverData" value="${nd.serverData}"/>
<c:set var="id" value="id${nd.id}"/>
<c:set var="java" value="${serverData.javaConf}"/>
<div class="diagnosticDetails currentNode" >
  <table class="nodeDiagnosticInfo">
    <tr>
      <td>
        <bs:_collapsibleBlock title="CPU & Memory Usage" id="${id}CPU_MemoryUsage" collapsedByDefault="false" saveState="true">
          <table class="chartsContainer" id="${id}chartsContainer">
            <tr>
              <td class="chartCell">
                <div class="chart" data-type="cpu" data-update-url="/admin/diagnostic/nodeStatisticData.html?type=cpu" style="overflow: hidden">
                  <div class="chartTitle">CPU usage (${serverData.availableProcessors} cores)</div>
                  <div class="chartHolder" id="cpuChart${id}" style="float: left; width: 600px; height: 200px;"></div>
                  <div class="chartLegend" id="cpuChart${id}Legend"></div>
                  <script type="text/javascript">
                    $j(function () {
                      BS.AdminDiagnostics.renderCPUChart(null, '${id}');
                    });
                  </script>
                </div>
              </td>
              <td class="chartCell">
                <div class="chart" data-type="memory" data-update-url="/admin/diagnostic/nodeStatisticData.html?type=memory" style="overflow: hidden">
                  <div class="chartTitle">Memory usage</div>
                  <div class="chartHolder" id="memoryChart${id}" style="float: left; width: 600px; height: 200px;"></div>
                  <div class="chartLegend" id="memoryChart${id}Legend"></div>
                  <script type="text/javascript">
                    $j(function () {
                      BS.AdminDiagnostics.renderMemoryChart(null, '${id}', ${nd.memoryUsageChartAdditionalData});
                    });
                  </script>
                </div>
              </td>
            </tr>
          </table>
        </bs:_collapsibleBlock>
        <script type="application/javascript">
          $j(function() {
            var $collapsible = $j("#${id}CPU_MemoryUsage");
            $collapsible.click(function() {
              $j("#cpuChart${id}").data("chart").renderChart();
              $j("#memoryChart${id}").data("chart").renderChart();
            });
          });
        </script>
      </td>
    </tr>
    <tr>
      <td>
        <bs:_collapsibleBlock title="Troubleshooting" id="${id}Troubleshooting" collapsedByDefault="${false}" saveState="true">
          <div style="width: 100%; margin-top: 0.5em;">
            <bs:messages key="loggingPresetLoaded"/>
            <bs:messages key="threadDumpSucceeded"/>
            <bs:messages key="memoryDumpSucceeded"/>
            <div class="error" id="errorsHolder"></div>
            <div id="progressIndicator" style="display: none;"><forms:progressRing style="float:none;"/> Please wait...</div>
          </div>

          <table class="runnerFormTable">

            <tr class="groupingTitle">
              <td>Debug Logging</td>
            </tr>
            <tr>
              <td>
                <c:url var="url" value="/admin/admin.html?item=diagnostics"/>
                Active logging preset:<bs:help file="TeamCity+Server+Logs" anchor="loggingPreset"/>
                <forms:select name="loggingPreset" onchange="BS.JvmStatusForm.loadPreset()">
                  <c:forEach items="${loggingPresets}" var="preset">
                    <forms:option value="${preset}" selected="${preset == currentLoggingPreset}"><c:out value="${preset}"/></forms:option>
                  </c:forEach>
                </forms:select>
              </td>
            </tr>
            <tr class="groupingTitle">
              <td>Hangs and Thread Dumps</td>
            </tr>
            <tr>
              <td>
                <div>
                    <span class="btn-group" style="float: right">
                      <button class="btn" id="threadDump" onclick="BS.JvmStatusForm.takeThreadDump(); return false;">Save Thread Dump</button>
                      <button class="btn btn_append" onclick="return false;" id="threadDumpMoreOptions" title="Save thread dump with custom file name">...</button>
                    </span>

                  If the TeamCity server appears slow or is not responding, please try taking several thread dumps with some interval.
                  <br/>
                  On this page you can either <a target="_blank" rel="noreferrer" href="<c:url value='/admin/diagnostic.html?actionName=threadDump&save=false'/>">view a server thread dump</a> in a new browser window
                  or save a thread dump to a file.

                  <input type="hidden" name="threadDumpPath" id="threadDumpPath" value=""/>
                </div>
              </td>
            </tr>
            <tr>
              <td>
                <c:choose>
                  <c:when test="${memoryDumpAvailable}">
                    <div>
                      <input class="btn" type="button" name="memoryDump" value="Dump Memory Snapshot" onclick="BS.JvmStatusForm.takeMemoryDump()" style="float: right;"/>
                      If you notice that TeamCity server is consuming too much memory,
                      please dump a memory snapshot and <a href="<bs:helpUrlPrefix/>Reporting+Issues">send</a> it to us.
                    </div>
                    <div class="clr"></div>
                  </c:when>
                  <c:otherwise>
                    <div>If you notice that TeamCity server is consuming too much memory,
                      read more on how to take a memory snapshot in the TeamCity <a href="<bs:helpUrlPrefix/>Reporting+Issues">documentation</a>.</div>
                  </c:otherwise>
                </c:choose>
              </td>
            </tr>
          <tr class="groupingTitle">
            <td>Server Restart</td>
          </tr>
            <tr>
              <td id="serverRestart">
                <div>
                  <c:choose>
                    <c:when test="${restartAvailable}">

                      <authz:authorize checkGlobalPermissions="true" allPermissions="MANAGE_SERVER_INSTALLATION">
                        <jsp:attribute name="ifAccessGranted">
                          <input class="btn" type="button" name="restart" value="Restart Server" onclick="BS.ServerRestarter.restartServer();" style="float: right;"/>
                          TeamCity server process will be restarted.
                        </jsp:attribute>
                        <jsp:attribute name="ifAccessDenied">
                          You don't have enough permissions to restart the TeamCity Server.
                        </jsp:attribute>
                      </authz:authorize>
                    </c:when>
                    <c:otherwise>
                      <bs:buildStatusIcon type="red-sign" className="warningIcon"/>Server restart is not supported: <c:out value="${restartUnavailableReason}"/>
                    </c:otherwise>
                  </c:choose>
                </div>
                <div class="clr"></div>
              </td>
          </table>
        </bs:_collapsibleBlock>
      </td>
    </tr>

    <tr>
      <td>
        <bs:_collapsibleBlock title="Java Configuration" id="${id}JavaConfiguration" collapsedByDefault="true" saveState="true">
          <div>Java version: <c:out value="${java.version}"/></div>
          <div>Java VM info: <c:out value="${java.VMInfo}"/></div>
          <div>Java Home path: <c:out value="${java.homePath}"/></div>
          <c:if test="${serverData.serverInfo != null}">
            <div>Server: <c:out value="${serverData.serverInfo}"/></div>
          </c:if>
          <div>JVM arguments:
            <pre style="white-space: pre-wrap;"><c:forEach items="${java.args}" var="arg"><c:out value="${arg}"/> </c:forEach></pre>
          </div>
        </bs:_collapsibleBlock>
      </td>
    </tr>

    <c:if test="${not empty buildQueueStatistics}">
      <tr>
        <td>
          <bs:_collapsibleBlock title="Build Queue Optimization Statistics" id="${id}BuildQueueStatistics" collapsedByDefault="true" saveState="true">
            <bs:refreshable containerId="buildQueueStatistics" pageUrl="${pageUrl}">
              <table class="settings runnerFormTable">
                <tr>
                  <th class="name" style="width: 10em">Optimization reason</th>
                  <th class="name" style="width: 7em">Total builds optimized</th>
                  <th class="name" style="width: 7em">Total optimized build time</th>
                </tr>
                <tr>
                  <td>Build with the same revisions already exists</td>
                  <td><c:out value="${buildQueueStatistics.optimizedBuildsNumber[startedBuildExistsReason]}"/></td>
                  <td><bs:printTime time="${buildQueueStatistics.optimizedBuildTimeSeconds[startedBuildExistsReason]}"/></td>
                </tr>
                <tr>
                  <td>Build with fresher changes triggered</td>
                  <td><c:out value="${buildQueueStatistics.optimizedBuildsNumber[moreChangesReason]}"/></td>
                  <td><bs:printTime time="${buildQueueStatistics.optimizedBuildTimeSeconds[moreChangesReason]}"/></td>
                </tr>
              </table>
            </bs:refreshable>
            <script type="text/javascript">
              window.setInterval(function() {
                BS.reload(false, function() {
                  $('buildQueueStatistics').refresh();
                });
              }, 10000);
            </script>
          </bs:_collapsibleBlock>
        </td>
      </tr>
    </c:if>
    <tr>
      <td>
        <hr>
        <c:url value="/app/metrics" var="metricsUrl"/>
        <a href="${metricsUrl}" target="_blank" rel="noreferrer">Server Load Metrics</a> (Prometheus format)
      </td>
    </tr>

    <c:if test="${not empty serverLoadMetrics}">
      <tr>
        <td>
          <bs:_collapsibleBlock title="Server Load" id="${id}ServerLoad" collapsedByDefault="true" saveState="true">
            <bs:refreshable containerId="serverLoad" pageUrl="${pageUrl}">
              <table class="settings runnerFormTable">
                <tr>
                  <th class="name" style="width: 10em">Metric name</th>
                  <th class="name" style="width: 7em">1 min</th>
                  <th class="name" style="width: 7em">5 mins</th>
                  <th class="name" style="width: 7em">10 mins</th>
                </tr>
                <c:forEach items="${serverLoadMetrics}" var="metric">
                  <tr>
                    <td>
                        <%--@elvariable id="metric" type="jetbrains.buildServer.util.IntervalMetric"--%>
                      <c:out value="${metric.description}"/>:
                    </td>
                    <c:forEach items="${metric.formattedRate}" var="val" varStatus="pos">
                      <td>${val}</td>
                    </c:forEach>
                  </tr>
                </c:forEach>
              </table>
            </bs:refreshable>
            <script type="text/javascript">
              window.setInterval(function() {
                BS.reload(false, function() {
                  $('serverLoad').refresh();
                });
              }, 10000);
            </script>
          </bs:_collapsibleBlock>
        </td>
      </tr>
    </c:if>

  </table>
  <script type="text/javascript">
    $j(function () {
      $j("#${id}chartsContainer").find(".chart").data("paused", "false");
      if (BS.AdminDiagnostics.updateFunction) {
        BS.AdminDiagnostics.updateFunction();
      }
      $j(BS.AdminDiagnostics.installChartsAutoUpdate);
    });
  </script>
</div>
