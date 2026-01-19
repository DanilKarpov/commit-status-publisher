<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags" %>
<%@ taglib prefix="problems" tagdir="/WEB-INF/tags/problems" %>
<%--@elvariable id="compactMode" type="java.lang.Boolean"--%>
<%--@elvariable id="buildProblem" type="jetbrains.buildServer.serverSide.problems.BuildProblem"--%>
<%--@elvariable id="buildProblemUID" type="java.lang.String"--%>
<%--@elvariable id="causeMessageList" type="java.util.List<jetbrains.buildServer.serverSide.buildLog.LogMessage>"--%>
<c:if test="${!compactMode && not empty causeMessageList}">
  <style type="text/css">
    .detailsWrapper .log {
      margin-top: 0;
    }
  </style>
  <problems:buildProblemDetails uid="${buildProblemUID}" insertIcons="true" buildProblem="${buildProblem}" expand="false">
    <bs:buildLog buildPromotion="${buildProblem.buildPromotion}" messagesList="${causeMessageList}"/>
  </problems:buildProblemDetails>
</c:if>
