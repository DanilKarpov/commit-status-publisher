<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags" %>

<style type="text/css">
  .detailsWrapper .errorMessagesNote {
    color: #737577;
  }
  .detailsWrapper .log + .errorMessagesNote {
    display: block;
    padding-top: 1em;
  }
  .detailsWrapper .log {
    margin-top: 0;
  }
</style>

<jsp:useBean id="errorMessages" scope="request" type="java.util.List<jetbrains.buildServer.serverSide.buildLog.LogMessage>"/>
<jsp:useBean id="moreErrorsAvailable" scope="request" type="java.lang.Boolean"/>
<jsp:useBean id="buildPromotion" scope="request" type="jetbrains.buildServer.serverSide.BuildPromotion"/>

<c:choose>
  <c:when test="${errorMessages.size() > 0}">
    <bs:buildLog buildPromotion="${buildPromotion}" messagesList="${errorMessages}" renderRunningTime="true"/>
    <c:if test="${moreErrorsAvailable}"><i class="errorMessagesNote">More errors available on the Build Log</i></c:if>
  </c:when>
  <c:otherwise><i class="errorMessagesNote">Nothing to show</i></c:otherwise>
</c:choose>