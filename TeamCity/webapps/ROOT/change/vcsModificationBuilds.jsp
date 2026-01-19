<%@ include file="/include-internal.jsp" %>
<%--@elvariable id="modification" type="jetbrains.buildServer.vcs.SVcsModification"--%>
<%--@elvariable id="regularBuildTypesStatus" type="java.util.Map"--%>
<%--@elvariable id="pageUrl" type="java.lang.String"--%>

<bs:refreshable containerId="buildsContainer_${modification.id}" pageUrl="${pageUrl}">
  <c:set var="buildTypesStatusMap" value="${regularBuildTypesStatus}" scope="request"/>
  <c:set var="refreshableId" value="buildsContainer_${modification.id}" scope="request"/>
  <c:set var="notTriggeredText" value="Not triggered" scope="request"/>
  <%@ include file="/viewModificationBuildTypes.jsp" %>
</bs:refreshable>
