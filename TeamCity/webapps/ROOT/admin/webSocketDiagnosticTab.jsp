<%@ include file="/include-internal.jsp" %>

<script type="application/javascript">
  BS.WebSocketDiagnostics = {

    reloadAllPages: function() {

      BS.confirmDialog.show({
        actionButtonText: "Reload",
        cancelButtonText: 'Cancel',
        title: "Reload all WebUI pages",
        text: 'All the opened TeamCity Web UI pages will be scheduled to reload.',
        action: function () {
          BS.ajaxRequest(BS.AdminActions.url, {
            method: "post",
            parameters: "reloadAllPages=1",
            onComplete: function() {
              $('generalWebSocketInfo').refresh();
            }
          })
        }
      });
    }
  }
</script>

<c:url value="/websocketDiagnostic.html" var="separatePageLink"/>

<bs:refreshable containerId="generalWebSocketInfo" pageUrl="${pageUrl}">
  <table class="runnerFormTable" style="margin-top: 1em">
    <tr class="groupingTitle">
      <td>General</td>
    </tr>
    <tr>
      <td>
        <bs:messages key="webSocketDiagnostics"/>
        <div>
          Users without admin permissions can view WebSocket Status <a href="${separatePageLink}">here</a>
        </div>
        <div style="margin-top: 1em;">
          Number of currently opened WebSocket sessions: ${totalSessions} (<fmt:formatNumber value="${perHttpSession}" maxFractionDigits="1"/> on average per HTTP session)
        </div>

        <div style="margin-top: 1em;">
          <input class="btn" type="button" name="reloadAllPages" value="Reload all WebUI pages" onclick="BS.WebSocketDiagnostics.reloadAllPages(); return false;"/>
        </div>

      </td>
    </tr>
  </table>

</bs:refreshable>



<jsp:include page="webSocketDiagnosticInfo.jsp"/>
