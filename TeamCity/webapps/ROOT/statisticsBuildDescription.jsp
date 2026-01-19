<%@ include file="/include-internal.jsp"
%><%--@elvariable id="branch" type="jetbrains.buildServer.serverSide.Branch"--%>
<%--@elvariable id="showBranch" type="java.lang.Boolean"--%>
<%--@elvariable id="build" type="jetbrains.buildServer.serverSide.SBuild"--%>
<%--@elvariable id="buildType" type="jetbrains.buildServer.serverSide.SBuildType"--%>
<c:choose>
  <c:when test="${not accessDenied}">
    <div>Build: <bs:buildLink build="${build}">#${build.buildNumber} <bs:buildDataIcon buildData="${build}"/></bs:buildLink><c:out value="${build.statusDescriptor.text}"/></div>
    <c:if test="${showBuildType}">
      <div>Configuration: <bs:buildTypeLink buildType="${buildType}"/></div>
    </c:if>
    <div>Started: <bs:simpleDate value="${build.startDate}"/></div>
    <c:if test="${showBranch}">
      <div>Branch: <span class="branch hasBranch"><bs:branchLink branch="${branch}"/></span></div>
    </c:if>
  </c:when>
  <c:otherwise>
    You do not have enough permissions to see this build details
  </c:otherwise>
</c:choose>