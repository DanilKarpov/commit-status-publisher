<%@ include file="/include-internal.jsp" %>
<%--@elvariable id="pageUrl" type="java.lang.String"--%>
<%--@elvariable id="settingsTasks" type="java.util.List<jetbrains.buildServer.serverSide.impl.persisting.TaskInfo>"--%>
<%--@elvariable id="projectTasks" type="java.util.List<jetbrains.buildServer.serverSide.impl.persisting.TaskInfo>"--%>

<script type="text/javascript">
  abortTask = function (taskType, taskId) {
    BS.confirm('Are you sure you want to abort the task #' + taskId + '?', function () {
      BS.ajaxRequest(BS.AdminActions.url, {
        method: "post",
        parameters: "action=abortTask&taskType=" + taskType + "&taskId=" + taskId,
        onComplete: function () {
          BS.reload(true);
        }
      });
    }.bind(this));
  }
</script>

<bs:refreshable containerId="persistQueue" pageUrl="${pageUrl}">
  <style type="text/css">
    div.header {
      margin-top: 1em;
      font-weight: bold;
    }

    div.queueItem {
      margin-top: 1em;
      margin-left: 1em;
    }

    div.releaseThreads {
      margin-left: 1em;
    }

    span.user {
      font-weight: bold;
      margin-left: 1em;
    }

    span.description {
      margin-left: 1em;
    }
  </style>

  <div>
    <div class="header">Project Settings Queue</div>
    <c:choose>
      <c:when test="${empty projectTasks}">
        <div class="queueItem">Empty</div>
      </c:when>
      <c:otherwise>
        <c:forEach var="task" items="${projectTasks}" varStatus="status">
          <div class="queueItem">
              Task id: ${task.id}, created: <bs:date value="${task.createDate}"/>, "<c:out value="${task.description}"/>", stage: ${task.stage}.
            <c:if test="${status.count == 1 && afn:permissionGrantedGlobally('CHANGE_SERVER_SETTINGS')}">
              <div class="releaseThreads"><a href="javascript:abortTask('${task.type}', '${task.id}')">Abort task...</a></div>
            </c:if>
          </div>
        </c:forEach>
      </c:otherwise>
    </c:choose>
  </div>

  <div>
    <div class="header">Configuration Files Queue</div>
    <c:choose>
      <c:when test="${empty settingsTasks}">
        <div class="queueItem">Empty</div>
      </c:when>
      <c:otherwise>
        <c:forEach var="task" items="${settingsTasks}" varStatus="status">
          <div class="queueItem">
            Task id: ${task.id}, "<c:out value="${task.description}"/>", stage: ${task.stage}.
            <c:if test="${status.count == 1 && afn:permissionGrantedGlobally('CHANGE_SERVER_SETTINGS')}">
              <div class="releaseThreads"><a href="javascript:abortTask('${task.type}', '${task.id}')">Abort task...</a></div>
            </c:if>
          </div>
        </c:forEach>
      </c:otherwise>
    </c:choose>
  </div>

  <script type="text/javascript">
    setTimeout(function () {
      $j("#persistQueue").get(0).refresh();
    }, 5000);
  </script>
</bs:refreshable>
