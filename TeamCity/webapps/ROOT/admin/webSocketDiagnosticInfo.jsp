<table class="runnerFormTable" style="margin-top: 1em">
  <tr class="groupingTitle">
    <td>Diagnostics info</td>
  </tr>
  <tr>
    <td>
      <div>Servlet Container: ${serverInfo}</div>
      <div>WebSocket Enabled: ${websocketEnabled}</div>
      <div>User Agent: <span id="userAgent"></span></div>
    </td>
  </tr>
  <tr class="groupingTitle">
    <td>Detailed log</td>
  </tr>
  <tr>
    <td>
      <div id="log"></div>
    </td>
  </tr>
</table>

<style type="text/css">

  #log {
    width: 99%;
    margin-top: 1em;
    border: 1px solid var(--ring-line-color, #dfe5eb);
    background-color: var(--ring-secondary-background-color, #f7f9fa);
    padding: 1em 0 1em 1em;
  }
</style>

<script type="text/javascript">

  $j('#userAgent').html(navigator.userAgent);

  var refreshLog = function() {
    var newLogHtml ="";
    BS.WebSocketLog.getLog().forEach(function(message) {
      newLogHtml += message + "</br>";
    });
    $j('#log').html(newLogHtml);
  };
  refreshLog();
  setInterval(refreshLog, 1000);
</script>
