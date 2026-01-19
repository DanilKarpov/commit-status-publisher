<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags" %>
<jsp:useBean id="processImportantMessagesTail" scope="request" type="java.util.List<jetbrains.buildServer.serverSide.buildLog.LogMessage>"/>
<jsp:useBean id="processImportantMessagesNumber" scope="request" type="java.lang.Integer"/>
<jsp:useBean id="buildPromotion" scope="request" type="jetbrains.buildServer.serverSide.BuildPromotion"/>
<jsp:useBean id="processFlowId" scope="request" type="java.lang.Integer"/>
<style type="text/css">
  .detailsWrapper .exitCodeProcessErrorsNote {
    color: #737577;
  }
  .detailsWrapper .log {
    margin-top: 0;
  }
</style>
<c:choose>
  <c:when test="${processImportantMessagesNumber > 0}">
    <c:if test="${processImportantMessagesNumber > processImportantMessagesTail.size()}">
      <c:url var='url' value='/problems/exitCodeProblemAjax.html'/>
      <i class="exitCodeProcessErrorsNote">Showing the recent process error output.&nbsp;
        <a onclick="loadLazyBuildProblemDetails($j(this).closest('.lazyBuildProblemDetailsContainer').data('uid'), '${url}', 'processFlowId=${processFlowId}&promotionId=${buildPromotion.id}&relatedMessagesNum=${processImportantMessagesTail.size() + 40}'); return false;" href="#">Show more</a></i>
    </c:if>
    <bs:buildLog buildPromotion="${buildPromotion}" messagesList="${processImportantMessagesTail}" renderRunningTime="true"/>
  </c:when>
  <c:otherwise>
    <i class="exitCodeProcessErrorsNote">Nothing to show</i>
  </c:otherwise>
</c:choose>