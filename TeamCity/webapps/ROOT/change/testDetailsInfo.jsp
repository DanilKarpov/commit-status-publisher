<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<%@ include file="/include-internal.jsp" %>

<span class="testRunsNote">
  <c:if test="${not empty loadedTestRun and loadedTestRun.invocationCount > 1}">
    The test was run <b>${loadedTestRun.invocationCount}</b> times in the
    build<c:if test="${loadedTestRun.failedInvocationCount > 0}">, <b>${loadedTestRun.failedInvocationCount}</b> failure<bs:s val="${loadedTestRun.failedInvocationCount}"/></c:if>
  </c:if>
</span>

<c:set var="buildId" value="${not empty loadedTestRun ? loadedTestRun.buildId : 0}"/>
<c:set var="testId" value="${not empty loadedTestRun ? loadedTestRun.testRunId : 0}"/>
<c:set var="testNameId" value="${not empty loadedTestRun ? loadedTestRun.test.testNameId : 0}"/>
<c:set var="testDetailsId">tdi_${util:uniqueId()}</c:set>

<div class="rightBlock expandedDetails">
  <div class="icon_before icon16 collapser collapser_expanded" onclick="BS.TestDetails.toggleBuildDetails(this);" title="Click to hide the details block"></div>
  <div class="relatedBuildsWrapper">
    <c:choose>
      <c:when test="${not empty loadedTestRun and loadedTestRun.status.failed}">
        <table class="testRelatedBuilds" id="table_${testDetailsId}">
          <%@include file="testFailureInformation.jsp"%>
        </table>
      </c:when>
      <c:otherwise>
        <div class="emptyTestRelatedBuilds" style=" : none"></div>
      </c:otherwise>
    </c:choose>
    <ext:includeExtensions placeId="<%=PlaceId.TEST_DETAILS_BLOCK%>"/>
  </div>
</div>
<div class="rightBlock collapsedDetails" style="display: none;" onclick="BS.TestDetails.toggleBuildDetails(this);">
  <div class="icon_before icon16 collapser collapser_collapsed" title="Click to show the details block"></div>
  <a href="#" onclick="return false;">show details</a>
</div>
<%--@elvariable id="testStacktrace" type="java.lang.String"--%>
<div class="testMetadata" id="testMetadata_${testDetailsId}"></div>
<pre class="fullStacktrace" id="fullStacktrace_${testDetailsId}">${testStacktrace}</pre>
<a href="#" onclick="BS.TestDetails.closeDetails(this); return false;" class="hideStacktrace">&laquo; Hide stacktrace</a>
<bs:copy2ClipboardLink dataId="fullStacktrace_${testDetailsId}" stripTags="true">Copy to clipboard</bs:copy2ClipboardLink>

<script type="text/javascript">
  (function () {

    var tableWithData = $('table_${testDetailsId}');

    var testDivContainer = $j(tableWithData).closest('.testBlockGeneral');
    var popupStacktraceId = testDivContainer.attr('data-copy-stacktrace-id');
    if (popupStacktraceId) {
      testDivContainer.find('.fullStacktrace').attr('id', popupStacktraceId);
      testDivContainer.find('.copy2Clipboard').attr('data-clipboard-id', popupStacktraceId);
    }

    BS.TestDetails.loadFFIInformationForBuild(${buildId}, ${testId}, tableWithData);
    if (${testId} > 0) {
      BS.TestMetadata.renderMetadata('testMetadata_${testDetailsId}', '${build.buildTypeExternalId}', ${buildId}, ${testId}, '${testNameId}');
    }
  })();
</script>
