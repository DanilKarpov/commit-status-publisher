<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="runBuildBean" type="jetbrains.buildServer.controllers.RunBuildBean" scope="request"/>
<jsp:useBean id="changes" type="java.util.List" scope="request"/>
<c:set var="selectedChange" value="${runBuildBean.selectedChange}"/>
<select>
<c:forEach items="${changes}" var="vcsChange">
  <%@include file="vcsChangeOption.jsp"%>
</c:forEach>
</select>
