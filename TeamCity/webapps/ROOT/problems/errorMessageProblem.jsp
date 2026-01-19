<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="problems" tagdir="/WEB-INF/tags/problems" %>
<%--@elvariable id="compactMode" type="java.lang.Boolean"--%>
<%--@elvariable id="buildProblem" type="jetbrains.buildServer.serverSide.problems.BuildProblem"--%>
<%--@elvariable id="buildProblemUID" type="java.lang.String"--%>
<%--@elvariable id="showErrorMessagesInline" type="java.lang.Boolean"--%>
<c:if test="${!compactMode and showErrorMessagesInline}">
  <c:url var='url' value='/problems/errorMessageProblemAjax.html'/>
  <problems:lazyBuildProblemDetails uid="${buildProblemUID}" buildProblem="${buildProblem}" url="${url}"  parameters="promotionId=${buildProblem.buildPromotion.id}" expand="false"/>
</c:if>
