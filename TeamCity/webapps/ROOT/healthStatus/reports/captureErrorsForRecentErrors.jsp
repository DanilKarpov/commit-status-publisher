<%@ page import="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" %>
<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<jsp:useBean id="statistic" type="java.util.Map" scope="request"/>
<jsp:useBean id="showMode" type="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" scope="request"/>
<c:set var="inplaceMode" value="<%=HealthStatusItemDisplayMode.IN_PLACE%>"/>
<c:set var="autoExpandError" value="${showMode == inplaceMode}" />

<div class="capture-errors-for-recent-errors-report">
  <c:if test="${statistic.max_count != null}">

    <c:if test="${statistic.max_count == 1}">
      There was
      <c:if test="${statistic.error_messages != null}">
        <c:if test="${!autoExpandError}">
          <strong><a class="show-last-captured-error" style="cursor: pointer;">1 error</a></strong>
        </c:if>
        <c:if test="${autoExpandError}">
          <strong>1 error</strong>
        </c:if>
      </c:if>
      <c:if test="${statistic.error_messages == null}">
        <strong>1 error</strong>
      </c:if>
      logged since the last server start. The error occurred <strong>${statistic.file_date}</strong> ago.
    </c:if>

    <c:if test="${statistic.max_count > 1}">
      There were
      <c:if test="${statistic.error_messages != null}">
        <c:if test="${!autoExpandError}">
          <strong><a class="show-last-captured-error" style="cursor: pointer;">${statistic.max_count} errors</a></strong>
        </c:if>
        <c:if test="${autoExpandError}">
          <strong>${statistic.max_count} errors</strong>
        </c:if>
      </c:if>
      <c:if test="${statistic.error_messages == null}">
        <strong>${statistic.max_count} errors</strong>
      </c:if>
      logged since the last server start.

      <c:if test="${statistic.max_period == statistic.file_date}">
        Errors occurred <strong>${statistic.max_period}</strong> ago.
      </c:if>
      <c:if test="${statistic.max_period != statistic.file_date}">
        Last error occurred <strong>${statistic.file_date}</strong> ago,
        first error occurred <strong>${statistic.max_period}</strong> ago.
      </c:if>
    </c:if>

  </c:if>

  <c:if test="${statistic.file_name != null}">
    <div>
      View entire <a href="<c:url value='/get/file/serverLogs/?dynamicFile=lastCapturedError&forceInline=true'/>" target="_blank" rel="noreferrer">log file</a>
      <span class="separator">|</span>
      <a href="<c:url value='/get/file/serverLogs/?dynamicFile=lastCapturedError&forceAttachment=true'/>"><i class="tc-icon_before icon16 tc-icon_download"></i></a>
    </div>
  </c:if>

  <c:if test="${statistic.error_messages != null}">
    <c:set var="classVal"><c:if test="${!autoExpandError}">last-captured-error-message hidden</c:if></c:set>
      <span class="${classVal}">
        <c:forEach items="${statistic.error_messages}" var="message">
          <pre style="word-wrap: break-word; white-space: pre-wrap; word-break: normal;">${fn:escapeXml(message)}</pre>
        </c:forEach>
      </span>
  </c:if>
</div>

<c:if test="${!autoExpandError}">
  <script type="text/javascript">
    jQuery(function ($) {
      $("div.capture-errors-for-recent-errors-report .show-last-captured-error").off("click").on("click", function () {
        var log = $(this).closest("div.capture-errors-for-recent-errors-report").children(".last-captured-error-message");
        if (log.hasClass("hidden")) {
          log.removeClass("hidden");
        } else {
          log.addClass("hidden");
        }
      });
    }(jQuery));
  </script>
</c:if>
