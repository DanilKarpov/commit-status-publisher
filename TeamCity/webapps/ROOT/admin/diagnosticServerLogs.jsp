<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="bean" type="jetbrains.buildServer.diagnostic.web.DiagnosticServerLogsController.ServerLogsBean" scope="request"/>
<bs:fileBrowsePage id="serverLogs"
                   dialogId=""
                   dialogTitle=""
                   bean="${bean}"
                   actionPath="/admin/serverLogs.html"
                   homePath="/admin/admin.html?item=diagnostics&tab=logs"
                   pageUrl="${pageUrl}"
                   showTimestamps="${true}"
                   showServerTime="${true}"
                   jsBase="">
  <jsp:attribute name="belowFileName">
    <c:if test="${bean.clipped}"><div class="clippedMessage">Showing last ${bean.clipSize} only.</div></c:if>
  </jsp:attribute>
  <jsp:attribute name="headMessage">
    Choose a log file from <c:out value="${bean.logsDir}"/>:
  </jsp:attribute>
  <jsp:attribute name="headMessageNoFiles">
    No log files available in <c:out value="${bean.logsDir}"/>.
  </jsp:attribute>
</bs:fileBrowsePage>
<c:if test="${showTotalSize}">
<div class="filesize" style="margin-top: 1em;">
  Total size: <forms:progressRing id="totalSizeLoadProgress" progressTitle="Loading..." className="totalSizeLoadProgress"/><span id="totalSizePlaceholder" style="display: none;">&nbsp;&nbsp;<em style="color: #737577;">(zero-length files aren't shown)</em></span>
</div>
<script type="text/javascript">
  $j(function() {
    $j.ajax({
              type: "POST",
              url: window['base_uri'] + "/admin/serverLogs.html",
              data: {
                fileName: "/",
                action: "getTotalSize"
              },
              dataType: "json"
            }).done(function (data) {
      if (data.sizeFormatted) {
        var $placeHolder = $j("#totalSizePlaceholder");
        $placeHolder.text(data.sizeFormatted + $placeHolder.text());
        $j("#totalSizeLoadProgress").remove();
        $placeHolder.show();
      }
    }).error(function (data) {
      var $placeHolder = $j("#totalSizePlaceholder");
      $placeHolder.text("cannot calculate");
      $j("#totalSizeLoadProgress").remove();
      $placeHolder.show();
    });

  });
</script>
</c:if>