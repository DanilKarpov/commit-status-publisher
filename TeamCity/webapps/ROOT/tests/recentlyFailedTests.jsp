<%@ page
  %><%@include file="/include-internal.jsp"
  %><%@ taglib prefix="tt" tagdir="/WEB-INF/tags/tests"

%><jsp:useBean id="pagerUrlPattern" scope="request" type="java.lang.String"
/><jsp:useBean id="pager" type="jetbrains.buildServer.util.Pager" scope="request"
/><jsp:useBean id="tests" type="java.util.List<jetbrains.buildServer.serverSide.stat.TestFailureRate>" scope="request"
/><jsp:useBean id="thresholdHours" type="java.lang.Long" scope="request"
/><jsp:useBean id="buildTypes" type="java.util.List" scope="request"
/><jsp:useBean id="project" scope="request" type="jetbrains.buildServer.serverSide.SProject"

/><c:if test="${empty buildType}">
  <c:set var="buildType" value="${null}"/>
</c:if

><bs:refreshable containerId="problematicTests" pageUrl="">
  
<div class="actionBar clearfix">
  Show problematic tests<bs:help file="Flaky+Tests"/> for:
  <c:url var="pagerUrl" value="project.html?projectId=${project.externalId}&tab=tests"/>
  <bs:buildTypesFilter buildTypes="${buildTypes}" selectedBuildTypeId="${buildType.externalId}" url="${pagerUrl}"/>
  <forms:saving className="progressRingInline"/>
</div>

<c:choose>
  <c:when test="${fn:length(tests) == 0}">
    <p style="margin: 10px;">No tests found</p>
  </c:when>
  <c:otherwise>
    <table class="testList dark borderBottom">
      <thead>
        <tr>
          <th>Test</th>
          <th style="text-align:right;">Total Runs</th>
          <th style="text-align:right;">Failure Count</th>
          <th style="text-align:right;">Last Failure Time</th>
        </tr>
      </thead>
      <c:forEach items="${tests}" var="failureRate">
        <jsp:useBean id="failureRate" type="jetbrains.buildServer.serverSide.stat.TestFailureRate"/>
        <tr>
          <td>
            <tt:testNameWithLink showPackage="true" testBean="${failureRate.test}"/>
          </td>
          <td style="text-align:right;">
            ${failureRate.successCount + failureRate.failureCount}
          </td>
          <td style="text-align:right;">
            <%--<fmt:formatNumber value="${test.failureRate * 100}" minFractionDigits="1" maxFractionDigits="1"/> %--%>
            ${failureRate.failureCount}
          </td>
          <td style="text-align:right;">
            <bs:date value="${failureRate.lastFailureTime}" pattern="dd MMM yy HH:mm"/>
          </td>
        </tr>
      </c:forEach>
    </table>
  </c:otherwise>
</c:choose>
<bs:pager place="bottom" urlPattern="${pagerUrlPattern}" pager="${pager}"/>
</bs:refreshable>
