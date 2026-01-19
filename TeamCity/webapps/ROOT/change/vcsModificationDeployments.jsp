<%@ include file="/include-internal.jsp" %>
<%--@elvariable id="modification" type="jetbrains.buildServer.vcs.SVcsModification"--%>
<%--@elvariable id="deploymentStatus" type="java.util.Map"--%>
<%--@elvariable id="pageUrl" type="java.lang.String"--%>

<bs:refreshable containerId="envsContainer_${modification.id}" pageUrl="${pageUrl}">
  <c:set var="buildTypesStatusMap" value="${deploymentStatus}" scope="request"/>
  <c:set var="refreshableId" value="envsContainer_${modification.id}" scope="request"/>
  <c:set var="notTriggeredText" value="Not deployed" scope="request"/>
  <%@ include file="/viewModificationBuildTypes.jsp" %>
</bs:refreshable>
