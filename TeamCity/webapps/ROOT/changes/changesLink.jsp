<%@ include file="../include-internal.jsp" %>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags" %>
<jsp:useBean id="buildPromotion" scope="request" type="jetbrains.buildServer.serverSide.BuildPromotionEx"/>
<jsp:useBean id="totalNum" scope="request" type="java.lang.Integer"/>
<jsp:useBean id="totalCount" scope="request" type="java.lang.String"/>
<jsp:useBean id="changes" scope="request" type="java.util.List<jetbrains.buildServer.UserChanges>"/>
<span class="${totalNum eq 0 ? 'noChanges' : ''}">
<bs:changesLinkFullInner build="${buildPromotion.associatedBuild}"
                         queuedBuild="${buildPromotion.queuedBuild}"
                         buildPromotion="${buildPromotion}"
                         noPopup="${noPopup}"
                         noUsername="${noUsername}"
                         noLink="${noLink}"
                         highlight="${highlight}"
                         containsUserChanges="${containsUserChanges}"
                         totalNum="${totalNum}"
                         totalCount="${totalCount}"
                         changes="${changes}"/>
</span>