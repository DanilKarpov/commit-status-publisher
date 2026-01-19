<%@ include file="/include-internal.jsp" %>

<div class="metricsPage">
</div>

<script type="text/javascript">
  ReactUI.renderAdminMetricsTab(document.querySelector(".metricsPage"), {
    helpUrl: "${util:helpUrl(null, "TeamCity+Monitoring+and+Diagnostics", "Metrics", false)}"
  });
</script>

