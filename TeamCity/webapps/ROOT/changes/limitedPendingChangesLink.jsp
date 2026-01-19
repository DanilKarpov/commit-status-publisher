<%@ include file="../include-internal.jsp" %>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags" %>
<jsp:useBean id="buildType" scope="request" type="jetbrains.buildServer.serverSide.BuildTypeEx"/>
<jsp:useBean id="pendingChanges" scope="request" type="jetbrains.buildServer.serverSide.LimitedChangesCollection"/>
<jsp:useBean id="branchBean" scope="request" type="jetbrains.buildServer.controllers.BranchBean"/>
<c:if test="${pendingChanges.containsChanges}">
  <bs:limitedPendingChangesLink buildType="${buildType}"
                                pendingChanges="${pendingChanges}"
                                noLink="${noLink}"
                                branchBean="${branchBean}"/>
</c:if>
