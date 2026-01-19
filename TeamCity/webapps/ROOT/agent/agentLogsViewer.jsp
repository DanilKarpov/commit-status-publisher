<%@ include file="/include-internal.jsp"
%><jsp:useBean id="bean" type="jetbrains.buildServer.controllers.agent.AgentLogsViewerBean" scope="request"
/><%--@elvariable id="error" type="java.lang.String"--%>
<c:choose>
  <c:when test="${not empty error}"><div class="errorMessage">${error}</div></c:when>
  <c:otherwise>
    <bs:fileBrowsePage id="agentLogs"
                       dialogId=""
                       dialogTitle=""
                       bean="${bean}"
                       actionPath="/agent/viewLogs.html"
                       homePath="/agentDetails.html?id=${bean.agentId}&tab=agentLogs"
                       pageUrl="${pageUrl}"
                       jsBase="">
      <jsp:attribute name="belowFileName">
        <c:if test="${bean.clipped}"><div class="clippedMessage">Showing last ${bean.clipSize} only.</div></c:if>
      </jsp:attribute>
      <jsp:attribute name="headMessage">
        Choose a log file:
      </jsp:attribute>
      <jsp:attribute name="headMessageNoFiles">
        No log files available
      </jsp:attribute>
    </bs:fileBrowsePage>

    <script type="text/javascript">
      BS.blockRefreshPermanently();
    </script>
  </c:otherwise>
</c:choose>
