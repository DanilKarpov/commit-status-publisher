<%@ include file="/include-internal.jsp" %>

<%--@elvariable id="loadedTestRun" type="jetbrains.buildServer.serverSide.STestRun"--%>
<%--@elvariable id="ffiTestRun" type="jetbrains.buildServer.serverSide.STestRun"--%>
<%--@elvariable id="build" type="jetbrains.buildServer.serverSide.SBuild"--%>
<%--@elvariable id="fixedIn" type="jetbrains.buildServer.serverSide.SBuild"--%>

<c:set var="firstFailedInBuild" value="${empty ffiTestRun ? null : ffiTestRun.build}"/>
<c:set var="currentIsFFI" value="${not empty loadedTestRun and firstFailedInBuild == build}"/>
<c:set var="hasAnotherFFI" value="${not empty loadedTestRun and not empty firstFailedInBuild and not currentIsFFI}"/>

<c:if test="${not empty fixedIn}">
  <tr data-buildId="${fixedIn.buildId}">
    <td class="selector">&nbsp;</td>
    <td class="header">Already fixed in:<bs:help file="Already+Fixed+In"/></td>
    <c:set var="_currBuild" value="${loadedTestRun.fixedIn}"/>
    <%@ include file="_relatedBuildTDs.jspf" %>
  </tr>
</c:if>

<c:set var="currTestId" value="${empty loadedTestRun ? testId : loadedTestRun.testRunId}"/>

<tr class="selectedBuild"
    data-buildId="${build.buildId}"
    data-buildTypeId="${build.buildTypeExternalId}"
    data-testId="${currTestId}"
    data-testNameId="${not empty loadedTestRun ? loadedTestRun.test.testNameId : 0}"
    data-invocationCount="${not empty loadedTestRun ? loadedTestRun.invocationCount : 0}"
    data-failedInvocationCount="${not empty loadedTestRun ? loadedTestRun.failedInvocationCount : 0}"
>
  <td class="selector">
    <c:if test="${hasAnotherFFI}">
      <input type='radio' name='currentSelector_${build.buildId}_${currTestId}' checked/>
    </c:if>
  </td>
  <td class="header">
    <c:if test="${currentIsFFI}">
      First failure:<bs:help file="First Failure"/>
    </c:if>
    <c:if test="${not currentIsFFI}">
      Current failure:
    </c:if>
  </td>
  <c:set var="_currBuild" value="${build}"/>
  <%@ include file="_relatedBuildTDs.jspf" %>
</tr>

<c:choose>
  <c:when test="${empty firstFailedInBuild}">
    <tr>
      <td class="selector">&nbsp;</td>
      <td class="header">First failure:<bs:help file="First Failure"/></td>
      <td colspan="4"><em>Calculating ...</em></td>
    </tr>
  </c:when>
  <c:when test="${hasAnotherFFI}">
    <tr data-buildId="${firstFailedInBuild.buildId}"
        data-buildTypeId="${firstFailedInBuild.buildTypeExternalId}"
        data-testId="${ffiTestRun.testRunId}"
        data-testNameId="${ffiTestRun.test.testNameId}"

        data-invocationCount="${ffiTestRun.invocationCount}"
        data-failedInvocationCount="${ffiTestRun.failedInvocationCount}">
      <td class="selector"><input type='radio' name='currentSelector_${build.buildId}_${currTestId}'/></td>
      <td class="header">First failure:<bs:help file="First Failure"/></td>
      <c:set var="_currBuild" value="${firstFailedInBuild}"/>
      <%@ include file="_relatedBuildTDs.jspf" %>
    </tr>
  </c:when>
</c:choose>