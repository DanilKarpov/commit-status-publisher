<%@ page import="jetbrains.buildServer.web.problems.impl.exitCode.ExitCodeBuildProblemRenderer" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="problems" tagdir="/WEB-INF/tags/problems" %>
<%--@elvariable id="compactMode" type="java.lang.Boolean"--%>
<%--@elvariable id="buildProblem" type="jetbrains.buildServer.serverSide.problems.BuildProblem"--%>
<%--@elvariable id="buildProblemUID" type="java.lang.String"--%>
<%--@elvariable id="processFlowId" type="java.lang.String"--%>
<%--@elvariable id="showExpanded" type="java.lang.String"--%>
<%--@elvariable id="exitCodeExpand" type="java.lang.Boolean"--%>
<c:if test="${!compactMode && not empty processFlowId}">
  <c:url var='url' value='/problems/exitCodeProblemAjax.html'/>
  <c:set var="messagesNum" value="<%=request.getParameter(ExitCodeBuildProblemRenderer.MESSAGES_NUMBER_SHORT)%>"/>
  <problems:lazyBuildProblemDetails
      uid="${buildProblemUID}"
      buildProblem="${buildProblem}"
      expand="${showExpanded && exitCodeExpand}"
      url="${url}"
      parameters="processFlowId=${processFlowId}&promotionId=${buildProblem.buildPromotion.id}&relatedMessagesNum=${messagesNum}"
      loadingText="Loading build log messages..."/>
</c:if>
