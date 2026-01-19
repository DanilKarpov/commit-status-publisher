<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="vcsRootStatusBean" type="jetbrains.buildServer.diagnostic.web.DiagnosticVcsStatusBean" scope="request"/>
<c:set var="total" value="${vcsRootStatusBean.totalNumberOfInstances}"/>

<style>
  .operationRequesters {
    margin-left: 10px;
  }
  .operationRequesters th, td.operationRequesters__name {
    text-align: right;
    padding: 2px 10px 2px 2px;
    width: auto;
    border-right: 1px dotted var(--ring-line-color, #dfe5eb);
  }
  td.operationRequesters__val {
    text-align: right;
    padding: 2px 10px 2px 2px;
    white-space: nowrap;
    border-right: 1px dotted var(--ring-line-color, #dfe5eb);
  }
  .operationRequesters__percent {
    color: #737577;
    display: inline-block;
    width: 50px;
  }
</style>

<form action="${pageUrl}" method="get" style="margin-top: 0.5em;">
  <table class="runnerFormTable" style="width: 100%;">
    <tr class="groupingTitle">
      <td>Checking for changes status</td>
    </tr>
    <tr>
      <td>
        <div>
          Number of monitored VCS Roots (after parameters resolution): <strong><c:out value="${total}"/></strong>
        </div>
        <div>
          Number of VCS roots in polling mode: <strong><c:out value="${total - vcsRootStatusBean.noPollingCount}"/></strong>
        </div>
        <div>
          Number of VCS roots with configured commit hooks: <strong><c:out value="${vcsRootStatusBean.noPollingCount}"/></strong>
        </div>
        <div>
          Waiting in the queue: <strong><c:out value="${vcsRootStatusBean.scheduledInstances}"/></strong>
        </div>
        <div>
          Started checking for changes: <strong><c:out value="${vcsRootStatusBean.checkingForChangesStartedInstances}"/></strong>
        </div>
        <div>
          <c:set var="tasks" value="${vcsRootStatusBean.numberOfInProgressBuildChangesCollectingTasks}"/>
          In-progress builds and build chains changes collecting tasks:
          <c:if test="${empty tasks}"><strong>0</strong></c:if>
          <c:forEach items="${tasks}" var="e" varStatus="pos">
            <strong>${e.value}</strong> (<c:out value="${e.key}"/>)<c:if test="${not pos.last}">, </c:if>
          </c:forEach>
          <br/>
          <c:set var="tasks" value="${vcsRootStatusBean.numberOfInProgressCommitHookAndUserRequestsTasks}"/>
          In-progress commit hooks and user requested changes collecting tasks:
          <c:if test="${empty tasks}"><strong>0</strong></c:if>
          <c:forEach items="${tasks}" var="e" varStatus="pos">
            <strong>${e.value}</strong> (<c:out value="${e.key}"/>)<c:if test="${not pos.last}">, </c:if>
          </c:forEach>
        </div>
        <div>
          Latest requestors for changes collecting:
        </div>
        <table class="operationRequesters">
          <tr><th></th><th>Instances</th><th>Call count</th><th>Total collection time</th><th>Total waiting time</th></tr>
          <c:forEach items="${vcsRootStatusBean.requestors}" var="entry">
            <c:set var="stats" value="${entry.value}"/>
            <tr>
              <td class="operationRequesters__name">${entry.key.description}:</td>
              <td class="operationRequesters__val">${stats.instanceCount}</td>
              <td class="operationRequesters__val">${stats.callCount}</td>
              <td class="operationRequesters__val">
                <bs:millis value="${stats.collectionTimeMs}"/>
                <span class="operationRequesters__percent">
                  <bs:percent value="${stats.collectionTimeMs}" total="${vcsRootStatusBean.totalCollectionTime}"/>
                </span>
              </td>
              <td class="operationRequesters__val">
                <bs:millis value="${stats.waitingTimeMs}"/>
                <span class="operationRequesters__percent">
                  <bs:percent value="${stats.waitingTimeMs}" total="${vcsRootStatusBean.totalWaitingTime}"/>
                </span>
              </td>
            </tr>
          </c:forEach>

          <tfoot>
          <tr>
            <td colspan="4">
              <em>The data in the table is calculated across all instances (with limited number of collections per instance, default 50), within the last hour.</em>
            </td>
          </tr>
          </tfoot>
        </table>
      </td>
    </tr>

    <c:if test="${vcsRootStatusBean.totalNumberOfInstances > 0}">
      <tr class="groupingTitle">
        <td>Checking for changes duration</td>
      </tr>
      <tr>
      <td>

      Duration threshold: <forms:textField name="durationThresholdSecs" value="${vcsRootStatusBean.durationThresholdSecs}" style="width: 5em;"/> seconds;
      sort by averages: <forms:checkbox name="useAverages" checked="${vcsRootStatusBean.useAverages}" value="true"/> &nbsp;
      <input type="submit" class="btn btn_mini" value="Find VCS roots"/>

      <c:set var="foundRoots" value="${fn:length(vcsRootStatusBean.slowInstances)}"/>

      <p>Found <strong><c:out value="${foundRoots}"/></strong> VCS Root<bs:s val="${foundRoots}"/> with checking for changes duration &gt; <strong>${vcsRootStatusBean.durationThresholdSecs}</strong> seconds.</p>

      <c:if test="${not empty vcsRootStatusBean.slowInstances}">
        <l:tableWithHighlighting className="settings runnerFormTable" style="width: auto">
          <tr>
            <th class="name">Parent Id - Id</th>
            <th class="name">VCS Root name</th>
            <th class="name" style="width: 10em;">Last duration</th>
            <th class="name" style="width: 10em;">Average times</th>
          </tr>
          <c:forEach items="${vcsRootStatusBean.slowInstances}" var="vcsRootStat">
            <c:set var="vri" value="${vcsRootStat.rootInstance}"/>

            <tr>
              <td class="highlight" style="vertical-align: top;"><c:out value="${vri.parent.id}"/> - <c:out value="${vri.id}"/></td>
              <td class="highlight" style="vertical-align: top;">
                <a href="javascript:;" style="float: right" onclick="$('parameters_${vri.id}').toggle(); if (this.innerHTML.indexOf('show') != -1 ) { this.innerHTML = '&laquo; hide details' } else { this.innerHTML = 'show details &raquo;' }">show details &raquo;</a>
                <admin:vcsRootName vcsRoot="${vri.parent}" editingScope="" cameFromUrl="${pageUrl}"/>
                <div id="parameters_${vri.id}" style="display: none;">
                  <c:forEach items="${vcsRootStat.rootInstanceParameters}" var="e">
                    <c:out value="${e.key}"/>: <c:out value="${e.value}"/><br/>
                  </c:forEach>
                  <br/>
                  effective changes checking interval: <bs:printTime time="${vri.effectiveModificationCheckInterval}"/><br/>
                  <c:if test="${not empty vri.lastFinishChangesCollectingTime}">
                    last changes collection finished: <bs:date value="${vri.lastFinishChangesCollectingTime}"/><br/>
                  </c:if>
                  last changes collection requestor: ${vri.lastRequestor}<br/>

                  <br/>

                  <c:set var="progress" value="${vcsRootStat.rootProgressMessages}"/>
                  <c:if test="${not empty progress}">
                    <br/>
                    progress:<br/>
                    <c:forEach items="${progress}" var="msg">
                      <c:out value="${msg}"/><br/>
                    </c:forEach>
                  </c:if>
                </div>
              </td>
              <td class="highlight" style="vertical-align: top;">
                <bs:millis value="${vcsRootStat.durationMillis}"/> <c:if test="${not vcsRootStat.finished}">(in progress)</c:if><c:if
                  test="${not empty vcsRootStat.scheduledMillis}">, <bs:millis value="${vcsRootStat.scheduledMillis}"/> in queue</c:if>
                <c:if test="${vcsRootStat.durationMillis / 1000.0 > vri.effectiveModificationCheckInterval}">
                  <span class="error">checking for changes interval (<strong>${vri.effectiveModificationCheckInterval}</strong> seconds) exceeded</span>
                </c:if>
              </td>
              <td class="highlight" style="vertical-align: top;">
                Collect: <bs:millis value="${vcsRootStat.averageCollectChanges}"/>
                <c:set var="waitTime" value="${vcsRootStat.averageWaitTime}"/>

                <c:if test="${waitTime > 1000}">
                  <br>Wait: <bs:millis value="${waitTime}"/>
                </c:if>
              </td>
            </tr>
          </c:forEach>
        </l:tableWithHighlighting>
      </c:if>

      <input type="hidden" name="item" value="diagnostics"/>
      <input type="hidden" name="tab" value="vcsStatus"/>
      </td>
      </tr>

    </c:if>
  </table>

</form>
